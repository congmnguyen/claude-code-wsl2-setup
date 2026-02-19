# Shift+Enter: Insert Newline in VSCode Terminal (WSL)

## Problem

In the VSCode integrated terminal with WSL, pressing Shift+Enter either does nothing
or inserts a `\` at the end of the line (zsh line continuation), making it unusable
for sending a soft newline to CLI apps like Claude Code.

## Fix

Add this to your VSCode `keybindings.json` (`Ctrl+Shift+P` → "Open Keyboard Shortcuts (JSON)"):

```json
{
  "key": "shift+enter",
  "command": "workbench.action.terminal.sendSequence",
  "args": { "text": "\u001B\u000A" },
  "when": "terminalFocus"
}
```

This sends the escape sequence `ESC + LF` (`\x1B\x0A`), which readline-based apps
interpret as "insert a literal newline" — no trailing backslash.
