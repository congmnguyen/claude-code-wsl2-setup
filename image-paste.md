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

## Auto-start with systemd

Create `~/.config/systemd/user/wsl-screenshot-cli.service`:

```ini
[Unit]
Description=WSL screenshot clipboard monitor
After=default.target

[Service]
Type=simple
Environment=WSL_INTEROP=/run/WSL/1_interop
Environment=PATH=%h/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=%h/.local/bin/wsl-screenshot-cli start --quiet
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
```

Then enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now wsl-screenshot-cli.service
systemctl --user status wsl-screenshot-cli.service
```

The explicit `WSL_INTEROP` and `PATH` entries are required because the systemd user manager does not inherit them from an interactive WSL shell. Run `start` in the foreground here: systemd must own the process so it can restart it if the clipboard client exits. Do not also start the daemon from `.bashrc`, `.zshrc`, or Claude hooks.

Inspect failures with:

```bash
journalctl --user -u wsl-screenshot-cli.service -n 50 --no-pager
```

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
