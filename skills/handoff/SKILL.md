---
name: handoff
allowed-tools: Write
description: Summarize the current conversation into a handoff file saved to ~/.claude/handoffs/
---

## Context

- Today's date: !`date +%Y-%m-%d`
- Current project: !`basename $(pwd)`

## Your task

Review the entire conversation above and write a handoff file to:
`~/.claude/handoffs/<project>_<date>.md`

Use this structure:

```
# Session Handoff — <date>
**Project:** <project>

## What we were doing
<1–3 sentences on the main task or goal>

## Decisions made
<bullet list of key decisions or conclusions reached>

## Current state
<where things stand — what's done, what's in progress, what's broken>

## Next steps
<actionable list — enough detail to resume without re-reading the conversation>

## Key files / commands
<important file paths, commands, or snippets referenced in the session>
```

After writing the file, tell the user the exact path.
