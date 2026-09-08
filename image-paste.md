# Image Paste on WSL2

[wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli) — a Go daemon that saves screenshots to disk and puts the file path in the clipboard. Works with both Claude Code and Codex CLI.

| | |
|---|---|
| Claude Code | ✓ (Alt+V or Ctrl+Shift+V, paste path) |
| Codex CLI | ✓ |
| Requirements | WSL2, Windows interoperability, systemd user services; pre-built binary needs no Go toolchain |
| Poll interval | 250ms |

---

## Install

```bash
curl -fsSL https://nailu.dev/wscli/install.sh | bash
```

Installs binary to `~/.local/bin/`. No Go toolchain needed.

---

## Manage the monitor with systemd

Use the service below as the only process owner. Do not run `start --daemon`
alongside it or put start/stop commands in shell startup files or Claude hooks.
If migrating from a manually started daemon, stop that old daemon once with
`wsl-screenshot-cli stop` before enabling the service. If a service already owns
the monitor, use `systemctl --user stop wsl-screenshot-cli.service` instead.

## Auto-start with systemd

Requires a WSL distribution with systemd enabled. Confirm
`systemctl --user is-system-running` can reach the user manager before continuing.
A `degraded` result means some units failed; inspect them with
`systemctl --user --failed`.

Create the directory, then create `~/.config/systemd/user/wsl-screenshot-cli.service`.
Back up an existing unit before editing it:

```bash
mkdir -p ~/.config/systemd/user
```

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

This unit preserves the `WSL_INTEROP` path used by the previous setup. Confirm
`test -S /run/WSL/1_interop` succeeds on your WSL instance; if it does not, inspect
`printf '%s\n' "$WSL_INTEROP"` in a working WSL shell and use that socket path.
The socket may change after a WSL restart, so recheck it if interoperability fails.
The explicit environment entries are needed because the systemd user manager does
not inherit them from an interactive WSL shell. Run `start` in the foreground
here: systemd must own the process so it can restart it if the clipboard client
exits. Do not also start the daemon from shell startup files or Claude hooks.

Then enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now wsl-screenshot-cli.service
systemctl --user status wsl-screenshot-cli.service
```

Inspect failures with:

```bash
journalctl --user -u wsl-screenshot-cli.service -n 50 --no-pager
```

---

## Keybinding (optional)

To use Alt+V instead of Ctrl+Shift+V, merge this binding into
`~/.claude/keybindings.json`, preserving other entries:

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

## Verify

Use the service for routine control:

```bash
systemctl --user start wsl-screenshot-cli.service
systemctl --user status wsl-screenshot-cli.service
# To stop it:
systemctl --user stop wsl-screenshot-cli.service
# Start it again before testing clipboard paste:
systemctl --user start wsl-screenshot-cli.service
```

Take a screenshot on Windows and paste into your terminal with Ctrl+Shift+V.
Expect a path under `/tmp/.wsl-screenshot-cli/`; confirm that the file exists and
Claude Code can open it. After restarting WSL, repeat the test to check autostart.

For an update, stop the service, run `wsl-screenshot-cli update`, then start the
service again and repeat the paste test.

## Remove

```bash
systemctl --user disable --now wsl-screenshot-cli.service
rm -f ~/.config/systemd/user/wsl-screenshot-cli.service
systemctl --user daemon-reload
```

Remove only the optional `alt+v` binding you added from `~/.claude/keybindings.json`.
Keep other bindings. If no other workflow needs it, remove the installed
`~/.local/bin/wsl-screenshot-cli` binary. Restore an earlier service file if you
had one, reload systemd, and restore its previous enabled state.
