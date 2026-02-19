# Claude Code WSL2 — "Needs Your Input" Windows Notification

## Problem

When Claude Code finishes a long task on WSL2, the terminal gives no visual signal that
it is waiting. You only notice if you switch back to the terminal yourself.

The `Notification` hook lets Claude Code fire a Windows balloon tip (system tray popup)
so you get an OS-level alert even when the terminal is in the background.

---

## How It Works

1. Claude Code fires the `Notification` hook whenever it needs the user's attention.
2. The hook runs `~/bin/claude-notify`, a bash script that calls Windows PowerShell
   directly from WSL via `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`.
3. PowerShell creates a `NotifyIcon` (system tray icon) and shows a balloon tip for 5 s.
4. The script sleeps 6 s to keep the PowerShell process alive long enough for the
   balloon to display, then disposes the icon and exits.

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
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$notification = New-Object System.Windows.Forms.NotifyIcon
\$notification.Icon = [System.Drawing.SystemIcons]::Information
\$notification.BalloonTipTitle = '$title'
\$notification.BalloonTipText = '$message'
\$notification.Visible = \$true
\$notification.ShowBalloonTip(5000)
Start-Sleep -Seconds 6
\$notification.Dispose()
"
```

Make it executable:

```bash
chmod +x ~/bin/claude-notify
```

### Step 2: Add the Notification hook

In `~/.claude/settings.json`, add inside the `"hooks"` object:

```json
"Notification": [
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

When Claude Code finishes a task and is waiting, a Windows balloon tip appears in the
system tray with the title **Claude Code** and the message **Needs your input!**

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
- The `Start-Sleep -Seconds 6` in the script keeps the PowerShell process alive so the
  notification stays visible. If you removed or reduced it, restore it to at least 6 s.
