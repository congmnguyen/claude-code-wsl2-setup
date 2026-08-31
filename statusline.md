# Claude Code Status Line

A custom status line script that shows the current project directory, git branch, context window usage, and rate limits — color-coded by severity.

![Status line preview](assets/statusline.png)

```
📁 claude-code-wsl2-setup | 🌿 main | [░░░░░░░░░░] 6% | 5h:10% | W:95%
```

- **Project dir** — basename of `.workspace.current_dir` (fallback: `$PWD`), prefixed with `📁`
- **Git branch** — current branch, prefixed with `🌿` (only shown inside git repos)
- **Progress bar** — context window fill (green < 70%, yellow < 90%, red ≥ 90%)
- **5h:X%** — 5-hour rolling usage
- **W:X%** — 7-day rolling usage

---

## Install

**1. Save the script**

```bash
cat > ~/.claude/statusline-command.sh << 'EOF'
#!/usr/bin/env bash
# Claude Code status line
# Format: 📁 project | 🌿 main | [░░░░░░░░░░] 6% | 5h:10% | W:95%

input=$(cat)

IFS=$'\t' read -r cwd ctx_pct five_pct week_pct < <(
  printf '%s' "$input" | jq -r '[
    .workspace.current_dir // .cwd // "",
    .context_window.used_percentage // "",
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.seven_day.used_percentage // ""
  ] | @tsv'
)

parts=()

# ── Helper: round a value, or return 1 if it is not a number ──────────────────
to_pct() {
  case $1 in
    ''|*[!0-9.]*|*.*.*) return 1 ;;
  esac
  printf '%.0f' "$1"
}

# ── Helper: pick ANSI color based on percentage ───────────────────────────────
pct_color() {
  if   [ "$1" -lt 70 ]; then printf '\033[32m'
  elif [ "$1" -lt 90 ]; then printf '\033[33m'
  else                       printf '\033[31m'
  fi
}

# ── Helper: append "<label><pct>%" colored by severity ────────────────────────
add_pct() {
  local raw=$2 pct
  pct=$(to_pct "$raw") || return 0
  parts+=("$(pct_color "$pct")$1${pct}%$(printf '\033[0m')")
}

# ── 0. Project dir basename ───────────────────────────────────────────────────
parts+=("📁 $(basename "${cwd:-$PWD}")")

# ── 1. Git branch (only inside git repos) ─────────────────────────────────────
if [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null) \
    || branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && parts+=("🌿 $branch")
fi

# ── 2. Context window progress bar + percentage ───────────────────────────────
if pct=$(to_pct "$ctx_pct"); then
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( pct * 10 / 100 ))
  bar=""
  for (( i = 0; i < filled; i++ )); do bar="${bar}█"; done
  for (( i = filled; i < 10; i++ )); do bar="${bar}░"; done
  parts+=("$(pct_color "$pct")[${bar}] ${pct}%$(printf '\033[0m')")
fi

# ── 3. Rate limits ────────────────────────────────────────────────────────────
add_pct "5h:" "$five_pct"
add_pct "W:"  "$week_pct"

# ── Join with " | " and print ─────────────────────────────────────────────────
out=""
for part in "${parts[@]}"; do
  [ -z "$out" ] && out="$part" || out="${out} | ${part}"
done
printf '%s\n' "$out"
EOF
chmod +x ~/.claude/statusline-command.sh
```

**2. Wire it into `~/.claude/settings.json`**

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Restart Claude Code. The status line appears at the bottom of the interface.

---

## How it works

Claude Code pipes a JSON blob to the script's stdin on every refresh. The script extracts four fields in one `jq` call:

| Field | JSON path |
|-------|-----------|
| Working dir | `.workspace.current_dir` |
| Context % | `.context_window.used_percentage` |
| 5-hour usage % | `.rate_limits.five_hour.used_percentage` |
| 7-day usage % | `.rate_limits.seven_day.used_percentage` |

The git branch is resolved by running `git symbolic-ref` against the working directory from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files. On a detached HEAD (mid-rebase, mid-bisect) it falls back to a short SHA.

Every percentage goes through `to_pct`, which rejects anything non-numeric before `printf '%.0f'` sees it. This matters because the fields are absent or `null` more often than you would expect: `rate_limits` only appears for Pro/Max subscribers and only after the first API response of the session, Claude Code drops each window once its `resets_at` passes, and `context_window.used_percentage` is `null` early in a session. Without the guard, `printf` errors and the whole status line renders as a shell error. The context percentage is also clamped to 100 — `spend_limit.used_percentage` can exceed 100 once you pass the limit, which would otherwise overflow the 10-character bar.

Output uses `printf '%s'`, not `%b`: a directory or branch name containing a backslash would otherwise be mangled by escape interpretation.

---

## Debugging

Use a wrapper script to capture the live JSON without breaking the statusline:

```bash
cat > /tmp/debug-statusline.sh << 'EOF'
#!/usr/bin/env bash
input=$(cat)
printf '%s' "$input" | jq '.' > /tmp/statusline-debug.json
printf '%s' "$input" | bash ~/.claude/statusline-command.sh
EOF
chmod +x /tmp/debug-statusline.sh
```

Temporarily swap in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /tmp/debug-statusline.sh"
  }
}
```

Restart Claude Code, then inspect:

```bash
cat /tmp/statusline-debug.json | jq '{five_hour: .rate_limits.five_hour, seven_day: .rate_limits.seven_day}'
```

Test the script offline against a saved snapshot:

```bash
cat /tmp/statusline-debug.json | bash ~/.claude/statusline-command.sh
```
