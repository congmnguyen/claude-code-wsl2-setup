# Claude Code WSL2 — "Needs Your Input" Windows Notification

## Problem

When Claude Code finishes a long task on WSL2, the terminal gives no visual signal that
it is waiting. You only notice if you switch back to the terminal yourself.

The `PermissionRequest` hook lets Claude Code fire a Windows balloon tip (system tray popup)
when it needs you to approve or deny a tool use — so you get an OS-level alert even when
the terminal is in the background.

---

## How It Works

1. Claude Code fires the `PermissionRequest` hook whenever it is blocked on a tool-use
   approval prompt (e.g. "Do you want to proceed?").
2. The hook runs `~/bin/claude-notify`, a bash script that calls Windows PowerShell
   directly from WSL via `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`.
3. PowerShell creates a `NotifyIcon` (system tray icon) and shows a balloon tip for 5 s.
4. A WinForms message loop keeps the process alive until the balloon is dismissed or clicked.
5. **Clicking the balloon** restores the Windows Terminal window (if minimised) and brings
   it to the foreground via `ShowWindow` + `SetForegroundWindow`.
6. On dismiss or click, the message loop exits, the icon is disposed, and the process ends.

---

## Setup

### Step 1: Create the script

Save to `~/bin/claude-notify`:

```bash
#!/bin/bash
title="${1:-Claude Code}"
message="${2:-Notification}"
# Escape quotes for PowerShell
title=$(echo "$title" | sed 's/"/\\"/g')
message=$(echo "$message" | sed 's/"/\\"/g')
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport(\"user32.dll\")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport(\"user32.dll\")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport(\"user32.dll\")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport(\"user32.dll\")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@
\$hwnd = [Win32]::GetForegroundWindow()
\$winPid = 0
[Win32]::GetWindowThreadProcessId(\$hwnd, [ref]\$winPid) | Out-Null
\$proc = Get-Process -Id \$winPid -ErrorAction SilentlyContinue
if (\$proc -and \$proc.Name -eq 'WindowsTerminal') { exit 0 }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$notification = New-Object System.Windows.Forms.NotifyIcon
\$notification.Icon = [System.Drawing.SystemIcons]::Information
\$notification.BalloonTipTitle = '$title'
\$notification.BalloonTipText = '$message'
\$notification.Visible = \$true

\$notification.add_BalloonTipClicked({
    \$wt = Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (\$wt -and \$wt.MainWindowHandle -ne [IntPtr]::Zero) {
        [Win32]::ShowWindow(\$wt.MainWindowHandle, 9) | Out-Null
        [Win32]::SetForegroundWindow(\$wt.MainWindowHandle) | Out-Null
    }
    [System.Windows.Forms.Application]::Exit()
})
\$notification.add_BalloonTipClosed({
    [System.Windows.Forms.Application]::Exit()
})

\$notification.ShowBalloonTip(5000)
[System.Windows.Forms.Application]::Run()
\$notification.Dispose()
"
```

Make it executable:

```bash
chmod +x ~/bin/claude-notify
```

### Step 2: Add the hooks

In `~/.claude/settings.json`, add inside the `"hooks"` object:

```json
"PermissionRequest": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Needs your input!\" &'"
      }
    ]
  }
]
```

`PermissionRequest` fires when Claude is waiting for you to approve or deny a tool use
(e.g. "Do you want to proceed? Yes / No").

> **Why `bash -c '... &'` and not just the command directly?**
>
> The script calls PowerShell which does `Start-Sleep -Seconds 6` before exiting.
> If the hook runs synchronously, Claude Code blocks for ~7 s every time a notification
> fires — the UI appears frozen and input is unresponsive during that window.
> Running it with `&` inside `bash -c` detaches it immediately so Claude Code continues
> while the balloon tip displays in the background.

Restart Claude Code for the hook to take effect.

---

## Result

When Claude Code hits a permission prompt and is waiting for your approval, a Windows
balloon tip appears in the system tray with the title **Claude Code** and the message
**Needs your input!** Clicking the balloon restores and focuses Windows Terminal so you
can approve or deny immediately without manually switching windows.

---

## Troubleshooting

**No balloon appears**
- Confirm `~/bin/claude-notify` exists and is executable: `ls -l ~/bin/claude-notify`
- Test manually: `~/bin/claude-notify "Test" "Hello"`
- Check Windows notification settings — balloon tips require "Get notifications from apps"
  to be enabled for the app, and Focus Assist must not be blocking them.

**UI freezes for ~7 seconds when Claude finishes a task**
- The hook is running synchronously (missing the `&`).
- Ensure the command in `settings.json` is wrapped as `bash -c '... &'`.

**Balloon tip flashes and disappears instantly**
- The WinForms message loop (`Application.Run()`) keeps the PowerShell process alive until
  the balloon is clicked or times out. If the process exits immediately, check that both
  `add_BalloonTipClicked` and `add_BalloonTipClosed` handlers call `Application.Exit()`.

**Click does not focus Windows Terminal**
- Windows restricts `SetForegroundWindow` to prevent background processes from stealing focus.
  The balloon-click event fires in the context of the notification click, which satisfies the
  restriction in most cases. If it still doesn't work, try clicking the taskbar button instead.
- Make sure Windows Terminal is running (not just WSL in another host).
