# Image Paste on WSL2

[wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli) — a Go daemon that saves screenshots to disk and puts the file path in the clipboard. Works with both Claude Code and Codex CLI.

| | |
|---|---|
| Claude Code | ✓ (Alt+V or Ctrl+Shift+V, paste path) |
| Codex CLI | ✓ |
| Dependencies | none (pre-built binary) |
| Poll interval | 250ms |

---

## Install

```bash
curl -fsSL https://nailu.dev/wscli/install.sh | bash
```

Installs binary to `~/.local/bin/`. No Go toolchain needed.

---

## Usage

```bash
wsl-screenshot-cli start --daemon   # start
wsl-screenshot-cli status           # check
wsl-screenshot-cli stop             # stop
wsl-screenshot-cli update           # update
```

After starting: take a screenshot on Windows → `Ctrl+Shift+V` in terminal → pastes `/tmp/.wsl-screenshot-cli/<hash>.png` → Claude Code / Codex loads the image.

---

## Auto-start via SessionStart hook

Add to `~/.claude/settings.json`:

```json
"hooks": {
  "SessionStart": [
    { "hooks": [{ "type": "command", "command": "wsl-screenshot-cli start --daemon --quiet 2>/dev/null" }] }
  ]
}
```

> **Do not add a `SessionEnd` hook.** Claude Code fires `SessionStart`/`SessionEnd` for every Task tool subagent — a stop hook would kill the daemon mid-session.

---

## Keybinding (optional)

To use Alt+V instead of Ctrl+Shift+V, add to `~/.claude/keybindings.json`:

```json
{
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "alt+v": "chat:imagePaste"
      }
    }
  ]
}
```

> The top level must be an object with a `bindings` array — not a bare JSON array (bare array silently fails to load).
