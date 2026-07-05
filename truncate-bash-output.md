# Claude Code Bash Output Truncation Hook

## Problem

One verbose command — a test runner, a build log, an unfiltered `curl` returning a JSON blob —
can dump tens of thousands of characters into the conversation. That output is then re-read as
context on **every subsequent turn**, so a single careless `npm test` early in a session taxes
the whole rest of it.

Claude Code has its own hard output cap, but it cuts blindly. This hook truncates smarter:
it keeps the **head and the tail** (where errors and summaries usually live) and inserts an
explicit omission marker that tells the model how to recover the middle if it needs it
(rerun with `grep`/`tail`).

---

## Install

### Step 1: Save the hook script

```bash
mkdir -p ~/.claude/hooks
cp hooks/truncate-bash-output.sh ~/.claude/hooks/truncate-bash-output.sh
chmod +x ~/.claude/hooks/truncate-bash-output.sh
```

Requires `jq`.

### Step 2: Wire it into `~/.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/truncate-bash-output.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have other `PostToolUse` hooks, merge this entry into the existing array.
Restart Claude Code after editing `settings.json`.

---

## How It Works

Claude Code sends the tool-result event JSON to the hook on stdin after the Bash tool runs.
The hook extracts the command output (`.tool_response.stdout` when the response is an object,
the bare `.tool_response` string otherwise) and checks two thresholds:

| Trigger | Kept |
|---------|------|
| more than **200 lines** | first **120** + last **50** lines |
| more than **30,000 chars** (catches one-line JSON dumps that the line check misses) | first **16,000** + last **6,000** chars |

Below both thresholds the hook exits `0` silently and the output passes through untouched.
Above either, it emits `hookSpecificOutput.updatedToolOutput` with the truncated version and
an inline marker like:

```
... [843 lines omitted by truncate-bash-output hook — rerun with a filter (grep/tail) if you need the middle] ...
```

The marker matters: the model sees *why* the middle is missing and knows the recovery move,
instead of silently reasoning over incomplete output.

### The `updatedToolOutput` schema trap

`updatedToolOutput` must match the tool's **output schema**, not just be a string. For Bash
the response is the full `tool_response` object, so the hook replaces `.stdout` **in place**
and returns the whole object. Emitting a bare string where an object is expected makes
Claude Code ignore the hook output — the truncation silently stops working.

---

## Tuning

The thresholds are plain variables at the top of the script:

```bash
MAX_LINES=200   HEAD_LINES=120   TAIL_LINES=50
MAX_CHARS=30000 HEAD_CHARS=16000 TAIL_CHARS=6000
```

Head is deliberately bigger than tail for the line case (compiler/test output front-loads the
useful part), while errors and summaries at the end survive via the tail.

---

## Troubleshooting

**Output isn't being truncated**
- Check `jq` is installed — the hook exits without effect if `jq` fails.
- Verify the `PostToolUse` matcher is exactly `Bash` and settings.json was reloaded (restart).
- See the schema trap above — a bare-string `updatedToolOutput` is silently ignored.

**Truncation cut something you needed**
- That's the designed trade-off: rerun the command piped through `grep`/`sed -n 'A,Bp'`/`tail`
  to fetch just the region you need, as the marker suggests.
