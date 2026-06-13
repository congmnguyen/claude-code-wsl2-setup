# Codex CLI WSL2 — "Done" Windows Notification

## Problem

When Codex CLI finishes a turn on WSL2, the terminal gives no visual signal that it is
done — you only notice if you switch back to the terminal yourself.

This is the **Codex variant** of the notification fix. It reuses the same
`~/bin/claude-notify` script as the Claude Code WSL2 setup (see `claude-notify.md`), but
wires it up through Codex's `notify` config instead of Claude hooks.

> **Trap:** `[tui].notifications = true` is *not* this. That setting only controls the
> in-terminal (escape-code) notification and never runs an external program. The Windows
> balloon needs the separate **top-level `notify` key** — missing it means Codex never
> fires the balloon even with `[tui].notifications = true` enabled.

---

## How It Works

1. Codex finishes a turn and emits an `agent-turn-complete` event.
2. It runs the program in the top-level `notify` key, passing the event JSON as the
   **final argument**. With `["bash", "-lc", "<script>", "--"]`, the `"--"` becomes `$0`
   and the JSON lands in `$1`.
3. `jq` extracts `last-assistant-message` from the payload, so the balloon shows **Codex's
   actual last reply** (truncated to 120 chars), falling back to `"Done!"` if parsing fails.
4. `~/bin/claude-notify "Codex" "<msg>"` runs with a trailing `&` so it detaches
   immediately — Codex never blocks while the balloon is up.
5. The script's `GetForegroundWindow()` check still applies: the balloon is suppressed when
   Windows Terminal is the active window, so it only appears when you've stepped away.

---

## Setup

### Prerequisite: the notify script and `jq`

This reuses `~/bin/claude-notify` from `claude-notify.md` — install that first if you
haven't. Also install `jq`:

```bash
sudo apt install jq
```

### Add the `notify` key

Add to the **top-level** section of `~/.codex/config.toml` (before any `[table]` header —
TOML requires top-level keys to precede tables):

```toml
notify = ["bash", "-lc", "msg=$(printf '%s' \"$1\" | jq -r '.\"last-assistant-message\" // \"Done!\"' 2>/dev/null | head -c 120); ~/bin/claude-notify \"Codex\" \"${msg:-Done!}\" &", "--"]
```

Restart Codex for the config to take effect.

---

## Result

When Windows Terminal is **not** the active window, a balloon tip appears in the system
tray titled **Codex** with Codex's last reply as the body. Clicking it restores and
focuses Windows Terminal (handled by `~/bin/claude-notify`). No notification fires if you
are already looking at the terminal.

---

## Troubleshooting

**No balloon appears**
- Confirm the `notify` key is at the **top level** of `config.toml`, not inside a `[table]`.
  A misplaced key is silently ignored or causes a TOML parse error.
- Verify the script works standalone: `~/bin/claude-notify "Codex" "test"` (switch away
  from Windows Terminal first, or it will self-suppress).
- Confirm `jq` is installed: `command -v jq`.
- Restart Codex — it only reads `config.toml` at startup.

**Balloon shows raw JSON instead of the reply**
- The `jq` filter failed (older Codex payload, or `jq` missing). The script falls back to
  `"Done!"`, not raw JSON, so a JSON body means an older/hand-rolled `notify` line — use the
  exact line above.

**`[tui].notifications = true` is set but nothing happens**
- That setting is unrelated — it only does in-terminal notifications. Add the top-level
  `notify` key as shown above.
