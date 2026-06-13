# Claude Code WSL2 — "Done" Windows Notification

![Windows balloon tip — Claude Code Done!](assets/notification.png)

## Problem

When Claude Code finishes a long task on WSL2, the terminal gives no visual signal that
it is done. You only notice if you switch back to the terminal yourself.

Two hooks fire a Windows balloon tip (system tray popup):

- `Stop` — when Claude finishes a response
- `PermissionRequest` — when Claude is blocked waiting for tool-use approval

Both are suppressed when Windows Terminal is the foreground window, so they don't
interrupt you when you're already watching the output.

---

## How It Works

1. Claude Code fires the `Stop` or `PermissionRequest` hook.
2. The hook runs `~/bin/claude-notify`, a bash script that calls Windows PowerShell
   directly from WSL via `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`.
3. PowerShell checks the foreground window — if Windows Terminal is active, it exits silently.
4. Otherwise, it creates a `NotifyIcon` (system tray icon) and shows a balloon tip for 5 s.
5. A WinForms message loop keeps the process alive until the balloon is dismissed or clicked.
6. **Clicking the balloon** restores the Windows Terminal window (if minimised) and brings
   it to the foreground via `ShowWindow` + `SetForegroundWindow`.
7. On dismiss or click, the message loop exits, the icon is disposed, and the process ends.

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

In `~/.claude/settings.json`, add both hooks inside the `"hooks"` object:

```json
"Stop": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Done!\" &'"
      }
    ]
  }
],
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

`Stop` fires when Claude finishes a response; `PermissionRequest` fires when Claude is
blocked on a tool-approval prompt. Both exit silently if Windows Terminal is the
foreground window, so notifications only appear when you're working in another window.

> **Why `bash -c '... &'` and not just the command directly?**
>
> The script calls PowerShell which does `Start-Sleep -Seconds 6` before exiting.
> If the hook runs synchronously, Claude Code blocks for ~7 s every time a notification
> fires — the UI appears frozen and input is unresponsive during that window.
> Running it with `&` inside `bash -c` detaches it immediately so Claude Code continues
> while the balloon tip displays in the background.

Restart Claude Code for the hook to take effect.

---

## Codex CLI

Codex reuses the same `~/bin/claude-notify` script but wires it up differently: instead of
hooks in `settings.json`, Codex has a **top-level `notify` key** in `~/.codex/config.toml`.

> **Trap:** `[tui].notifications = true` is *not* this. That setting only controls the
> in-terminal (escape-code) notification and never runs an external program. The Windows
> balloon needs the separate top-level `notify` key — missing it means Codex never notifies
> even with `[tui].notifications = true` enabled.

Add to the top-level section of `~/.codex/config.toml` (before any `[table]`):

```toml
notify = ["bash", "-lc", "msg=$(printf '%s' \"$1\" | jq -r '.\"last-assistant-message\" // \"Done!\"' 2>/dev/null | head -c 120); ~/bin/claude-notify \"Codex\" \"${msg:-Done!}\" &", "--"]
```

How it works:

- Codex emits an `agent-turn-complete` event and passes its JSON payload as the **final
  argument** to the program. With `["bash", "-lc", "<script>", "--"]`, the `"--"` becomes
  `$0` and the JSON lands in `$1`.
- `jq` extracts `last-assistant-message` so the balloon shows **Codex's actual last reply**
  (truncated to 120 chars), falling back to `"Done!"` if parsing fails.
- The trailing `&` detaches it so Codex never blocks while the balloon is up — same reason
  as the Claude `Stop` hook.
- The script's `GetForegroundWindow()` check still applies, so the balloon is suppressed
  when Windows Terminal is the active window.

Requires `jq` (`sudo apt install jq`). Restart Codex to load the new config.

---

## Result

When Windows Terminal is **not** the active window, a balloon tip appears in the system
tray with the title **Claude Code** — **Done!** when Claude finishes a response, or
**Needs your input!** when it's blocked waiting for tool approval. Clicking the balloon
restores and focuses Windows Terminal. No notification fires if you are already looking
at the terminal.

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
