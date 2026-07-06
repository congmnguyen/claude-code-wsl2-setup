# Claude Code WSL2 — "Needs Your Input" Windows Notification

![Windows balloon tip — Claude Code Done!](assets/notification.png)

## Problem

When Claude Code finishes a long task on WSL2, needs permission, or a background agent
finishes, the terminal gives no visual signal unless you are watching it.

This hook uses Claude Code's `Notification` event, scoped by matcher:

- `idle_prompt` — Claude is done and waiting for your next prompt
- `permission_prompt` — Claude needs you to approve a tool use
- `agent_completed` — a background agent finishes or fails
- `agent_needs_input` — a background agent starts waiting on your input

All notifications are suppressed when Windows Terminal is the foreground window, so they
don't interrupt you when you're already watching the output.

`agent_completed` and `agent_needs_input` require Claude Code v2.1.198 or later and only
fire while agent view is open. If your Claude Code version is older, keep only
`idle_prompt` and `permission_prompt`.

---

## How It Works

1. Claude Code fires the `Notification` hook for a matched notification type.
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
# Escape for PowerShell: text lands inside single-quoted PS strings, where the
# only special character is the single quote itself (escaped by doubling).
title=$(printf '%s' "$title" | sed "s/'/''/g")
message=$(printf '%s' "$message" | sed "s/'/''/g")
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

In `~/.claude/settings.json`, add these entries inside the `"hooks"` object:

```json
"Notification": [
  {
    "matcher": "idle_prompt",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Done!\" &'"
      }
    ]
  },
  {
    "matcher": "permission_prompt",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Needs your input!\" &'"
      }
    ]
  },
  {
    "matcher": "agent_completed",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Background agent completed\" &'"
      }
    ]
  },
  {
    "matcher": "agent_needs_input",
    "hooks": [
      {
        "type": "command",
        "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Background agent needs input!\" &'"
      }
    ]
  }
]
```

`idle_prompt` fires when Claude is done and waiting. `permission_prompt` fires when Claude
is blocked on a tool-approval prompt. The agent matchers are useful for background
subagents such as `codex-delegate`. All commands exit silently if Windows Terminal is the
foreground window, so notifications only appear when you're working in another window.

> **Why `bash -c '... &'` and not just the command directly?**
>
> The PowerShell process stays alive in its WinForms message loop
> (`[Application]::Run()`) until the balloon is clicked, dismissed, or times out
> (~6 s). If the hook ran synchronously, Claude Code would block for that entire
> time — the UI appears frozen and input is unresponsive. Running it with `&`
> inside `bash -c` detaches it immediately so Claude Code continues while the
> balloon tip displays in the background.

Run `/hooks` and select `Notification` to confirm the hook is registered. If Claude Code
doesn't pick up the settings change within a few seconds, restart the session.

> **Running Codex too?** The same `~/bin/claude-notify` script is reused for Codex CLI,
> but it's wired up through Codex's top-level `notify` key (not Claude hooks) and shows
> Codex's actual last reply in the balloon. See `codex-notify.md`.

---

## Result

When Windows Terminal is **not** the active window, a balloon tip appears in the system
tray with the title **Claude Code** — **Done!** when Claude is waiting for your next
prompt, **Needs your input!** when it needs approval, or an agent-specific message for
background work. Clicking the balloon restores and focuses Windows Terminal. No
notification fires if you are already looking at the terminal.

---

## Troubleshooting

**No balloon appears**
- Confirm `~/bin/claude-notify` exists and is executable: `ls -l ~/bin/claude-notify`
- Test manually: `~/bin/claude-notify "Test" "Hello"`
- Run `/hooks` and confirm `Notification` has entries for `idle_prompt` and
  `permission_prompt`.
- Check Windows notification settings — balloon tips require "Get notifications from apps"
  to be enabled for the app, and Focus Assist must not be blocking them.

**UI freezes for several seconds when Claude finishes a task**
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
