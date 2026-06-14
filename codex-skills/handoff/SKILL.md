---
name: handoff
description: Summarize the current conversation into a handoff file saved to ~/.claude/handoffs/
---

## Context

- Today's date: !`date +%Y-%m-%d`
- Current time: !`date +%H%M`
- Current project: !`basename $(pwd)`
- Working dir: !`pwd`

## Your task

Review the entire conversation above and write a handoff file to:
`~/.claude/handoffs/<project>_<date>_<time>.md`

The handoff may be picked up by a different tool (Claude Code or Codex CLI), so keep it
self-contained — no tool-specific assumptions.

Use this structure:

```
# Session Handoff — <date> <time>
**Project:** <project>
**From:** Codex CLI
**Working dir:** <full path>

## What we were doing
<1–3 sentences on the main task or goal>

## Decisions made
<bullet list of key decisions or conclusions reached>

## Current state
<where things stand — what's done, what's in progress, what's broken>

## Gotchas / don't redo
<dead ends already tried, constraints to respect, traps to avoid — so the next agent
doesn't repeat work you already ruled out>

## Next steps
<actionable list — enough detail to resume without re-reading the conversation>

## Key files / commands
<important file paths, commands, or snippets referenced in the session>
```

After writing the file, tell the user the exact path.
