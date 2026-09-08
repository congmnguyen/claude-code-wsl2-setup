#!/usr/bin/env bash
# Claude Code status line
# Format: 📁 project | 🌿 main | [··········] 6% | 5h:10% | W:95%

# Keep decimal parsing independent of the user's locale.
export LC_ALL=C

# Validate before splitting. NUL separators preserve empty fields and literal
# tabs/backslashes in paths; Bash read with tab IFS collapses empty columns.
fields_json=$(jq -ce '
  if type != "object" then error("expected a statusline object") else
    [ .workspace.current_dir // .cwd // "",
      .context_window.used_percentage // "",
      .rate_limits.five_hour.used_percentage // "",
      .rate_limits.seven_day.used_percentage // "" ]
  end
') || exit 1
mapfile -d '' -t fields < <(printf '%s' "$fields_json" | jq -j '.[] | tostring, "\u0000"')
cwd=${fields[0]:-$PWD}
ctx_pct=${fields[1]:-}
five_pct=${fields[2]:-}
week_pct=${fields[3]:-}

parts=()

# ── Helper: round a value, or return 1 if it is not a number ──────────────────
to_pct() {
  [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
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
  filled_bar=""
  empty_bar=""
  for (( i = 0; i < filled; i++ )); do filled_bar="${filled_bar}█"; done
  for (( i = filled; i < 10; i++ )); do empty_bar="${empty_bar}·"; done
  parts+=("$(pct_color "$pct")[${filled_bar}$(printf '\033[90m')${empty_bar}$(pct_color "$pct")] ${pct}%$(printf '\033[0m')")
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
