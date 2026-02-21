# Claude Code WSL2 Setup Notes

## Image Paste (Alt+V) Fix

### Problem
Three issues prevent image paste from working on WSL2:

1. **Wrong clipboard format**: Windows copies images as `image/bmp`, but Claude Code's
   internal `checkImage` only accepts `png|jpeg|jpg|gif|webp`. So even if paste is
   triggered, the image is rejected silently.

2. **Keybinding conflict**: The default image paste key is `ctrl+v`, but Windows Terminal
   intercepts that for text paste before it reaches Claude Code.

3. **Missing dependencies**: `wl-clipboard` and `imagemagick` are not installed by default.

---

### Step 0: Install dependencies

```bash
sudo apt install wl-clipboard imagemagick
```

---

### Fix 1: BMP → PNG clipboard converter

**Script**: `~/.local/bin/clip2png`

Polls the Wayland clipboard every 1s. When `image/bmp` is detected, converts it to PNG
via ImageMagick and puts it back. Claude Code then sees a valid `image/png`.

The converted PNG is also saved to `/tmp/clip2png-last.png`. If `image/png` disappears
from the Wayland clipboard (the `wl-copy` background server can exit unexpectedly — e.g.
a WSLg clipboard sync takes back ownership) and no new content was copied, the script
re-serves the saved PNG. This keeps alt+v working throughout a session without needing
to re-copy the image from Windows.

> **Why polling and not `wl-paste --watch`?**
> WSLg does not support the wlroots data-control protocol that `--watch` requires.
> Polling is the only option on WSLg.

**Script contents** — save to `~/.local/bin/clip2png` and run `chmod +x ~/.local/bin/clip2png`:

```bash
#!/usr/bin/env bash
# Polls Wayland clipboard and converts image/bmp to image/png.
# WSLg does not support wlroots data-control protocol, so --watch is not available.
# Usage: clip2png --watch   (start background poller)
#        clip2png --stop    (kill it)

PID_FILE="/tmp/clip2png.pid"
LAST_PNG="/tmp/clip2png-last.png"
INTERVAL=1  # seconds between polls

stop() {
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi
}

watch() {
    stop

    (
        while true; do
            types=$(wl-paste --list-types 2>/dev/null)
            if echo "$types" | grep -q "image/bmp"; then
                tmp=$(mktemp)
                wl-paste --type image/bmp 2>/dev/null | convert - png:- 2>/dev/null > "$tmp"
                if [[ -s "$tmp" ]]; then
                    cp "$tmp" "$LAST_PNG"
                    wl-copy --type image/png < "$tmp"
                fi
                rm -f "$tmp"
            elif ! echo "$types" | grep -qE "image/png|text/" && [[ -f "$LAST_PNG" ]]; then
                # image/png disappeared (wl-copy background server exited) and no
                # new content was copied — re-serve the last converted image so
                # alt+v keeps working without needing a fresh copy from Windows.
                wl-copy --type image/png < "$LAST_PNG"
            fi
            sleep "$INTERVAL"
        done
    ) >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
}

case "${1:-}" in
    --watch) watch ;;
    --stop)  stop  ;;
    *) echo "Usage: clip2png [--watch|--stop]" >&2; exit 1 ;;
esac
```

The script supports two modes:
- `--watch` — start the background poller (saves PID to `/tmp/clip2png.pid`)
- `--stop` — kill the running poller

**Auto-start/stop via Claude Code hooks** in `~/.claude/settings.json`:

```json
"SessionStart": [
  { "hooks": [{ "type": "command", "command": "/home/YOU/.local/bin/clip2png --watch" }] }
],
"SessionEnd": [
  { "hooks": [{ "type": "command", "command": "/home/YOU/.local/bin/clip2png --stop" }] }
]
```

> **Note**: Hooks only take effect after restarting Claude Code. For the first run,
> start the poller manually: `/home/YOU/.local/bin/clip2png --watch`

The `>/dev/null 2>&1` before `&` is critical: without it the background subshell inherits
the hook's stdout pipe. Claude Code waits for that pipe to close (EOF) before considering
the hook done — but the infinite loop never closes it, so the hook hangs forever and all
input is silently discarded.

---

### Fix 2: Rebind image paste to Alt+V

**File**: `~/.claude/keybindings.json` (create if it does not exist)

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

> **Important**: The top level must be an object with a `bindings` array — NOT a bare JSON
> array. A bare array will silently fail to load.

---

### Result

Copy image on Windows → wait ~1s for poller → Alt+V in Claude Code → image pastes.

---

## Troubleshooting

**API Error 400: "image cannot be empty"**
- Cause 1: `wl-paste` on your system uses `--type` not `--mime`. Check your script uses
  `wl-paste --type image/bmp` (not `--mime`). Verify: `wl-paste --help | grep type`
- Cause 2: the old script piped directly into `wl-copy` with no size check, so if
  `convert` failed silently it stored 0 bytes as `image/png`. The fix: write to a temp
  file and only call `wl-copy` if the file is non-empty (`[[ -s "$tmp" ]]`).
- Debug: after copying image, run `wl-paste --type image/bmp | wc -c` (should be > 0),
  then `wl-paste --type image/bmp | convert - png:- | wc -c` (should also be > 0).

**"no image found in clipboard"**
- Check poller is running: `ps aux | grep wl-paste`
- Check clipboard types after copying image: `wl-paste --list-types`
- If no `image/bmp` shown: WSLg may not be bridging the image — check WSLg is up to date
- Start poller manually if hook hasn't fired yet: `clip2png --watch`

> **Note on v2.1.47+ native BMP support**: Claude Code's source has `wl-paste --type image/bmp`
> fallback and BMP→PNG conversion via sharp, but in practice sharp fails to convert Windows
> BMP on WSL2 and `aFH()` silently returns null — still showing "no image found". clip2png
> (which uses ImageMagick's `convert`) remains necessary.

**Alt+V does nothing**
- Confirm `~/.claude/keybindings.json` exists with the correct object structure
- Restart Claude Code after creating the file

**Typing Enter clears input and nothing happens (Claude Code on WSL)**
- Cause: the background subshell in `clip2png --watch` is inheriting the hook's stdout
  pipe, causing Claude Code to hang forever waiting for the hook to finish.
- Fix: ensure the script has `>/dev/null 2>&1 &` (not just `&`) on the background line.

**SessionStart hook error on startup**
- Cause: `clip2png` script is not executable.
- Fix: `chmod +x ~/.local/bin/clip2png`

**Notification hook freezes UI for ~7 seconds**
- Cause: if using a `claude-notify` script that calls PowerShell with `Start-Sleep`,
  the hook blocks Claude Code's UI until it returns.
- Fix: run it in the background in `~/.claude/settings.json`:
  ```json
  "command": "bash -c '~/bin/claude-notify \"Claude Code\" \"Needs your input!\" &'"
  ```
