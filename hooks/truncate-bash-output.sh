#!/bin/bash
# PostToolUse hook (matcher: Bash) — truncates huge command output before it
# reaches the model's context. Keeps head + tail with an omission marker.
# Thresholds: >MAX_LINES lines, or >MAX_CHARS chars (catches one-line JSON dumps).

MAX_LINES=200
HEAD_LINES=120
TAIL_LINES=50
MAX_CHARS=30000
HEAD_CHARS=16000
TAIL_CHARS=6000

input=$(cat)
out=$(jq -r 'if (.tool_response|type)=="object" then (.tool_response.stdout // empty) else (.tool_response // empty) end' <<<"$input")
[[ -z "$out" ]] && exit 0

lines=$(printf '%s\n' "$out" | wc -l)
chars=${#out}

if (( lines > MAX_LINES )); then
  truncated=$(printf '%s\n' "$out" | head -n "$HEAD_LINES"
    printf '\n... [%s lines omitted by truncate-bash-output hook — rerun with a filter (grep/tail) if you need the middle] ...\n\n' "$((lines - HEAD_LINES - TAIL_LINES))"
    printf '%s\n' "$out" | tail -n "$TAIL_LINES")
elif (( chars > MAX_CHARS )); then
  truncated="${out:0:HEAD_CHARS}
... [$((chars - HEAD_CHARS - TAIL_CHARS)) chars omitted by truncate-bash-output hook — rerun with a filter if you need the middle] ...
${out: -TAIL_CHARS}"
else
  exit 0
fi

# updatedToolOutput must match the tool's output schema — for Bash that is the
# full tool_response object, so replace .stdout in place rather than emitting a string.
jq -c --arg t "$truncated" '{hookSpecificOutput:{hookEventName:"PostToolUse",updatedToolOutput:(if (.tool_response|type)=="object" then (.tool_response|.stdout=$t) else $t end)}}' <<<"$input"
exit 0
