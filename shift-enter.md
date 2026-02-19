# Shift+Enter: Insert Newline in Claude Code (WSL2)

## Problem

Shift+Enter doesn't insert a newline in Claude Code by default when using WSL2,
whether in VSCode's integrated terminal or Windows Terminal.

## Fix: VSCode Integrated Terminal

Run `/terminal-setup` inside Claude Code from the VSCode integrated terminal.
It will automatically configure the keybinding.

> If it says "Found existing VSCode terminal Shift+Enter key binding. Remove it to continue.",
> remove any existing `shift+enter` entry from your VSCode `keybindings.json`
> (`C:\Users\<you>\AppData\Roaming\Code\User\keybindings.json`) and run `/terminal-setup` again.

## Fix: Windows Terminal

Windows Terminal needs a separate keybinding. Add this to your Windows Terminal `actions` array
in `settings.json` (`C:\Users\<you>\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`):

```json
"actions": [
    {
        "command": {
            "action": "sendInput",
            "input": "\u001b\r"
        },
        "keys": "shift+enter"
    }
]
```

Then restart Windows Terminal. Shift+Enter will now insert a newline in Claude Code.

## Fallback (no setup needed)

Use `\` + `Enter` to insert a newline — works everywhere without any configuration.
