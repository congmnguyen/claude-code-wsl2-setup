#!/usr/bin/env bash
# codex-run.sh — the only sanctioned way to invoke `codex exec` non-interactively.
# Encodes failure modes that each cost real debugging time when done by hand:
#   * prompt goes via stdin from a FILE (long prompts as argv break quoting, and
#     codex then silently blocks reading stdin forever)
#   * output goes to a log FILE, never a pipe (if the pipe reader dies, e.g. on a
#     harness timeout killing `tee`, codex deadlocks on a full pipe buffer mid-task)
#   * no extra flags accepted at all, so approval-bypass flags cannot be smuggled in;
#     the sandbox mode is the only permission mechanism
#   * quota exhaustion and stalls are detected and reported with distinct exit codes
#
# usage: codex-run.sh -p PROMPT_FILE [-w WORKDIR] [-s workspace-write|read-only]
#                     [-l LOG_FILE] [-t TIMEOUT_S] [-S STALL_S]
# exit: 0 ok | 2 quota-blocked (reset time printed) | 3 stalled or timed out (codex killed)
#       | 4 usage error | otherwise codex's own exit code
# First line printed is "LOG: <path>" so a background caller knows what to tail.

set -u

usage() {
  echo "usage: codex-run.sh -p PROMPT_FILE [-w WORKDIR] [-s workspace-write|read-only] [-l LOG] [-t TIMEOUT_S] [-S STALL_S]" >&2
  exit 4
}

PROMPT="" WORKDIR="$PWD" SANDBOX="workspace-write" LOG="" TIMEOUT=7200 STALL=600
while getopts "p:w:s:l:t:S:" opt; do
  case "$opt" in
    p) PROMPT=$OPTARG ;;
    w) WORKDIR=$OPTARG ;;
    s) SANDBOX=$OPTARG ;;
    l) LOG=$OPTARG ;;
    t) TIMEOUT=$OPTARG ;;
    S) STALL=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] && { echo "codex-run.sh: extra args refused (no flag pass-through): $*" >&2; exit 4; }

[ -n "$PROMPT" ] || usage
[ -s "$PROMPT" ] || { echo "codex-run.sh: prompt file missing or empty: $PROMPT" >&2; exit 4; }
[ -d "$WORKDIR" ] || { echo "codex-run.sh: no such workdir: $WORKDIR" >&2; exit 4; }
case "$SANDBOX" in workspace-write|read-only) ;; *) echo "codex-run.sh: bad sandbox: $SANDBOX" >&2; exit 4 ;; esac
command -v codex >/dev/null || { echo "codex-run.sh: codex CLI not found" >&2; exit 4; }
[ -n "$LOG" ] || LOG="/tmp/codex_run.$$.log"

echo "LOG: $LOG"

( cd "$WORKDIR" && exec codex exec -s "$SANDBOX" --skip-git-repo-check - < "$PROMPT" ) > "$LOG" 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null' INT TERM

START=$SECONDS
last_size=0 idle=0 status=""
while kill -0 "$PID" 2>/dev/null; do
  sleep 15
  if (( SECONDS - START > TIMEOUT )); then
    echo "TIMEOUT: exceeded ${TIMEOUT}s — killing codex"
    kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
    status=3; break
  fi
  size=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
  if (( size > last_size )); then
    last_size=$size; idle=0
  else
    (( idle += 15 ))
  fi
  if (( idle >= STALL )); then
    # Live children (ssh/nohup jobs) mean codex is legitimately waiting, not hung.
    if pgrep -P "$PID" >/dev/null 2>&1; then idle=0; continue; fi
    echo "STALLED: no log growth for ${STALL}s and no live children — killing codex"
    kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
    status=3; break
  fi
done
if [ -z "$status" ]; then
  wait "$PID"; status=$?
fi

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

if [ "$status" -ne 0 ] && strip_ansi < "$LOG" | grep -qiE "hit your usage limit|rate limit reached"; then
  reset=$(strip_ansi < "$LOG" | grep -oiE "try again (at|in)[^.\"]*" | tail -1)
  echo "BLOCKED: codex quota — ${reset:-reset time unknown}"
  exit 2
fi

wall=$(( SECONDS - START ))
# "tokens used" and the number may be on the same line or adjacent lines
tokens=$(strip_ansi < "$LOG" | grep -iA1 "tokens used" | grep -oE "[0-9][0-9,]*" | tail -1)
echo "EXIT: $status"
echo "WALL_CLOCK: $(( wall / 60 ))m$(( wall % 60 ))s"
echo "TOKENS: ${tokens:-unknown}"
echo "LOG_TAIL:"
tail -n 5 "$LOG" | strip_ansi
exit "$status"
