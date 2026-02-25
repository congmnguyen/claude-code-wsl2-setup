# Claude Code Windows (PowerShell) — "Needs Your Input" Notification

## Problem

When Claude Code finishes a long task while running natively in PowerShell on Windows,
there is no visual signal that it is waiting. You only notice if you switch back to the
terminal yourself.

This is the **Windows-native variant** of the notification fix. If you are running
Claude Code inside WSL2, see `claude-notify.md` instead.

Credit: [soulee-dev/claude-code-notify-powershell](https://github.com/soulee-dev/claude-code-notify-powershell)

---

## How It Works

1. Claude Code fires the `PermissionRequest` hook when it is blocked on a tool-use
   approval prompt (e.g. "Do you want to proceed?").
2. The hook runs `claude-hook-toast.ps1` via `cmd /c chcp 65001 && powershell ...`.
   The `chcp 65001` sets UTF-8 code page so message text renders correctly.
3. Claude Code pipes a JSON payload into the script's stdin containing `hook_event_name`
   and `message`.
4. The script checks if Windows Terminal is the foreground window — if it is, it exits
   silently. No point notifying if you're already looking at the terminal.
5. Otherwise it uses the Windows Toast Notification API (`Windows.UI.Notifications`)
   to show a modern toast — no sleep needed, no background process required.

The key hook is **`PermissionRequest`** — it fires only when Claude is blocked on a
permission prompt, not on every completed response.

---

## Setup

### Step 1: Install the script

Copy `claude-hook-toast.ps1` from this repo to your Claude config directory:

```powershell
Copy-Item "claude-hook-toast.ps1" "$env:USERPROFILE\.claude\claude-hook-toast.ps1"
```

This is a lightly customised fork of [soulee-dev/claude-code-notify-powershell](https://github.com/soulee-dev/claude-code-notify-powershell)
with two changes: the `Stop` message reads **"Needs your input!"** instead of "Response finished",
and a foreground window check skips the toast if Windows Terminal is already active.

### Step 2: Hook is already configured

`C:\Users\cong\.claude\settings.json` contains:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmd /c chcp 65001 >nul && powershell -ExecutionPolicy Bypass -File %USERPROFILE%\\.claude\\claude-hook-toast.ps1"
          }
        ]
      }
    ]
  }
}
```

**Restart Claude Code** (the Windows/PowerShell instance) for the hook to take effect.

---

## Testing

1. Open Claude Code in PowerShell (`claude`)
2. Type a prompt that takes a moment to respond (e.g. "explain quicksort in detail")
3. **Immediately alt-tab** to another app before Claude finishes
4. A Windows toast notification should appear when Claude is done

Or test the script directly:

```powershell
echo '{"hook_event_name":"Stop","message":""}' | powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\claude-hook-toast.ps1"
```

---

## Differences from the WSL2 variant

| | WSL2 (`claude-notify.md`) | Windows PowerShell (this file) |
|---|---|---|
| Script type | bash wrapper | native `.ps1` |
| Notification type | `NotifyIcon` balloon tip | Windows Toast API |
| Async mechanism | `bash -c '... &'` | not needed — toast fires and exits |
| Key hook | `PermissionRequest` | `PermissionRequest` |
| Script location | `~/bin/claude-notify` | `%USERPROFILE%\.claude\claude-hook-toast.ps1` |
| Settings file | `~/.claude/settings.json` | `C:\Users\cong\.claude\settings.json` |

---

## Troubleshooting

**No toast appears**

- Test the script manually (see Testing above).
- Make sure you alt-tab away before Claude finishes — the toast is suppressed when
  Windows Terminal is the active window.
- Check Windows Settings → Notifications — ensure notifications are enabled and
  Focus Assist / Do Not Disturb is off.

**Characters display as garbage**

- The `chcp 65001` in the hook command sets UTF-8. Make sure it is present.
