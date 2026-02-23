# Claude Code Windows (PowerShell) — "Needs Your Input" Notification

## Problem

When Claude Code finishes a long task while running natively in PowerShell on Windows,
there is no visual signal that it is waiting. You only notice if you switch back to the
terminal yourself.

This is the **Windows-native variant** of the notification fix. If you are running
Claude Code inside WSL2, see `claude-notify.md` instead.

---

## How It Works

1. Claude Code fires the `Notification` hook whenever it needs the user's attention.
2. The hook runs a `Start-Process` call that launches `claude-notify.ps1` in a hidden
   background PowerShell window — so Claude Code is not blocked.
3. The script creates a `NotifyIcon` (system tray icon) and shows a balloon tip for 5 s.
4. The script sleeps 6 s to keep the PowerShell process alive long enough for the
   balloon to display, then disposes the icon and exits.

---

## Setup

### Step 1: Script is already installed

The script is at:

```
C:\Users\cong\.claude\scripts\claude-notify.ps1
```

It accepts `-Title` and `-Message` parameters and skips the notification silently if
Windows Terminal is the foreground window (you are already looking at it).

### Step 2: Hook is already configured

`C:\Users\cong\.claude\settings.json` now contains:

```json
"hooks": {
  "Notification": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -WindowStyle Hidden -NonInteractive -Command \"Start-Process powershell -WindowStyle Hidden -ArgumentList @('-NonInteractive','-File','C:\\Users\\cong\\.claude\\scripts\\claude-notify.ps1','-Title','Claude Code','-Message','Needs your input!')\""
        }
      ]
    }
  ]
}
```

**Restart Claude Code** (the Windows/PowerShell instance) for the hook to take effect.

---

## Why `Start-Process` instead of just running the script directly?

The script does `Start-Sleep -Seconds 6` to keep the balloon visible. Running it
synchronously would block Claude Code's UI for ~7 s after every notification. The
outer `powershell` call launches the script as a detached background process and
returns immediately, so Claude Code is never blocked.

---

## Differences from the WSL2 variant

| | WSL2 (`claude-notify.md`) | Windows PowerShell (this file) |
|---|---|---|
| Script type | bash wrapper | native `.ps1` |
| Async mechanism | `bash -c '... &'` | `Start-Process` |
| Script location | `~/bin/claude-notify` | `C:\Users\cong\.claude\scripts\claude-notify.ps1` |
| Settings file | `~/.claude/settings.json` | `C:\Users\cong\.claude\settings.json` |

---

## Troubleshooting

**No balloon appears**

- Test the script manually in PowerShell:
  ```powershell
  & "C:\Users\cong\.claude\scripts\claude-notify.ps1" -Title "Test" -Message "Hello"
  ```
- Check Windows notification settings — balloon tips require "Get notifications from
  apps" to be enabled and Focus Assist must not be blocking them.

**UI freezes for ~7 seconds when Claude finishes a task**

- The hook is running synchronously. Verify the hook command in `settings.json` uses
  `Start-Process` (not a direct `-File` invocation).

**Balloon tip flashes and disappears instantly**

- `Start-Sleep -Seconds 6` in the script keeps the PowerShell process alive so the
  notification stays visible. If you reduced it, restore it to at least 6 s.

**ExecutionPolicy error**

- PowerShell may block unsigned scripts. Run this once as Administrator:
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
  ```
