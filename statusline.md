# Claude Code Status Line

A custom status line script that shows git branch, context window usage, model name, and rate limit countdown timers — all color-coded by severity.

```
main | [████░░░░░░] 42% | sonnet | ⏱ 28% 3h12m | W:91% 19h04m
```

- **Cyan** — current git branch
- **Progress bar** — context window fill (green < 50%, yellow < 80%, red ≥ 80%)
- **Model** — `sonnet`, `opus`, or `haiku`
- **⏱ X% Yh Zm** — 5-hour rolling usage + time until it resets
- **W:X% Yh Zm** — 7-day rolling usage + time until it resets

---

## Install

**1. Save the script**

```bash
cat > ~/.claude/statusline-command.sh << 'EOF'
#!/usr/bin/env bash
# Claude Code status line
# Receives JSON on stdin; outputs a single formatted line.
# Elements: git-branch | context-bar% | model | ⏱ usage% time | W:usage% time

input=$(cat)

# ── Parse JSON once ───────────────────────────────────────────────────────────
IFS=$'\t' read -r cwd ctx_pct model_id model_disp five_pct five_resets week_pct week_resets < <(
  printf '%s' "$input" | jq -r '[
    .workspace.current_dir // .cwd // "",
    .context_window.used_percentage // "",
    .model.id // "",
    .model.display_name // "",
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.five_hour.resets_at // "",
    .rate_limits.seven_day.used_percentage // "",
    .rate_limits.seven_day.resets_at // ""
  ] | @tsv'
)

parts=()

# ── Helper: format seconds as Xh Ym or Ym ────────────────────────────────────
fmt_remaining() {
  local diff=$1
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then
    printf "%dh%02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

# ── Helper: pick ANSI color based on percentage ───────────────────────────────
pct_color() {
  local pct=$1
  if   [ "$pct" -lt 50 ]; then printf '\033[32m'
  elif [ "$pct" -lt 80 ]; then printf '\033[33m'
  else                          printf '\033[31m'
  fi
}

# ── 1. Git branch (cyan) ──────────────────────────────────────────────────────
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  [ -n "$branch" ] && parts+=("$(printf '\033[36m%s\033[0m' "$branch")")
fi

# ── 2. Context window progress bar + percentage ───────────────────────────────
if [ -n "$ctx_pct" ]; then
  pct=$(printf '%.0f' "$ctx_pct")
  color=$(pct_color "$pct")
  filled=$(( pct * 10 / 100 ))
  [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
  parts+=("$(printf "${color}[%s] %d%%\033[0m" "$bar" "$pct")")
fi

# ── 3. Model short name ───────────────────────────────────────────────────────
if   printf '%s' "$model_id" | grep -qi 'sonnet'; then short="sonnet"
elif printf '%s' "$model_id" | grep -qi 'opus';   then short="opus"
elif printf '%s' "$model_id" | grep -qi 'haiku';  then short="haiku"
else short=$(printf '%s' "$model_disp" | awk '{print tolower($NF)}')
fi
[ -n "$short" ] && parts+=("$short")

# ── 4. 5-hour block: usage% + remaining time ──────────────────────────────────
if [ -n "$five_pct" ] && [ -n "$five_resets" ]; then
  pct=$(printf '%.0f' "$five_pct")
  color=$(pct_color "$pct")
  now=$(date +%s)
  diff=$(( five_resets - now ))
  if [ "$diff" -gt 0 ]; then
    parts+=("$(printf "${color}⏱ %d%% %s\033[0m" "$pct" "$(fmt_remaining "$diff")")")
  else
    parts+=("$(printf "${color}⏱ %d%%\033[0m" "$pct")")
  fi
fi

# ── 5. Weekly limit: usage% + remaining time ──────────────────────────────────
if [ -n "$week_pct" ] && [ -n "$week_resets" ]; then
  pct=$(printf '%.0f' "$week_pct")
  color=$(pct_color "$pct")
  now=$(date +%s)
  diff=$(( week_resets - now ))
  if [ "$diff" -gt 0 ]; then
    parts+=("$(printf "${color}W:%d%% %s\033[0m" "$pct" "$(fmt_remaining "$diff")")")
  else
    parts+=("$(printf "${color}W:%d%%\033[0m" "$pct")")
  fi
fi

# ── Join with " | " and print ─────────────────────────────────────────────────
out=""
for part in "${parts[@]}"; do
  [ -z "$out" ] && out="$part" || out="${out} | ${part}"
done

printf '%b\n' "$out"
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

Claude Code pipes a JSON blob to the script's stdin on every refresh. The script extracts eight fields in one `jq` call:

| Field | JSON path |
|-------|-----------|
| Working dir | `.workspace.current_dir` |
| Context % | `.context_window.used_percentage` |
| Model ID | `.model.id` |
| Model display name | `.model.display_name` |
| 5-hour usage % | `.rate_limits.five_hour.used_percentage` |
| 5-hour reset (Unix) | `.rate_limits.five_hour.resets_at` |
| 7-day usage % | `.rate_limits.seven_day.used_percentage` |
| 7-day reset (Unix) | `.rate_limits.seven_day.resets_at` |

The git branch is resolved by running `git symbolic-ref` against the working directory from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files.

---

## Debugging

Dump the live JSON to a file so you can inspect the schema:

```bash
# Add a debug hook temporarily in settings.json:
# "PreToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "cat > /tmp/statusline-debug.json" }] }]

# Then inspect:
cat /tmp/statusline-debug.json | jq '{five_hour: .rate_limits.five_hour, seven_day: .rate_limits.seven_day}'
```

Test the script offline against a saved snapshot:

```bash
cat /tmp/statusline-debug.json | bash ~/.claude/statusline-command.sh
```
