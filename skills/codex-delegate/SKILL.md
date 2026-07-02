---
name: codex-delegate
description: Delegate a heavy or mechanical coding task to Codex (gpt-5.5) via a cheap Sonnet wrapper subagent, so Codex's large transcript stays OUT of the main Opus context (token isolation). Trigger when the user says "delegate to codex", "hand this to codex", "let codex do X", or when a well-specified implementation/refactor/migration/bulk task is large enough that doing it inline would flood context with tool round-trips. Do NOT use for small tasks you can one-shot.
allowed-tools: Bash, Read, Glob, Grep, LS
---

## What this does

Runs Codex the token-cheap way (benchmark-verified): spawn the **`codex-delegate` subagent** (Sonnet), which shells out to `codex exec` and returns only a ~10-line summary. Codex's work (tens of thousands of tokens) runs on OpenAI's side and its transcript is absorbed by the cheap Sonnet subagent — **the main context only pays for the summary.**

Calling `codex exec` *directly* from the main context instead would dump the entire transcript (~90KB in the benchmark) back into Opus — convenient but the opposite of token-saving. Always go through the subagent.

## When to use it (routing)

- **Use**: well-specified implementation, refactor across many files, migration, boilerplate/scaffolding, bulk-mechanical edits, or work that would take many Read/Edit/Bash/test/fix round-trips inline.
- **Don't use**: a small edit you can do correctly in one shot (delegation overhead isn't worth it), or anything needing deep judgment about *this* codebase's architecture — do that yourself.

## How to invoke

1. Turn the request (`$ARGUMENTS` if given, else the current task) into a **self-contained spec** — Codex has no memory of this conversation, so include everything: exact behavior, file paths, edge cases, and how to verify.
2. Spawn the subagent (background), passing TASK, WORKDIR (default: current working directory), SANDBOX (`workspace-write` for edits, `read-only` for investigation), and a VERIFY command if there's a test/build to check.

   **Preferred** — the dedicated agent (available after a Claude Code restart that registers `.claude/agents/codex-delegate.md`):
   ```
   Agent(
     subagent_type: "codex-delegate",
     description: "delegate to codex",
     prompt: "TASK: <full self-contained spec>\nWORKDIR: <abs path>\nSANDBOX: workspace-write\nVERIFY: <test/build cmd or omit>",
     run_in_background: true
   )
   ```

   **Fallback** — if that errors with `Agent type 'codex-delegate' not found` (the definition isn't loaded in this session yet), spawn a generic Sonnet subagent that reads the same playbook file:
   ```
   Agent(
     subagent_type: "general-purpose",
     model: "sonnet",
     description: "delegate to codex",
     prompt: "First Read ~/.claude/agents/codex-delegate.md and adopt it as your complete role and instructions. Then carry out:\nTASK: <full self-contained spec>\nWORKDIR: <abs path>\nSANDBOX: workspace-write\nVERIFY: <test/build cmd or omit>",
     run_in_background: true
   )
   ```

3. When it returns its compact summary, **review the actual change yourself** before accepting: run `git diff` / `git status`, sanity-check the files it reports, and re-run VERIFY if correctness matters. Codex is fast but not infallible — you own the merge.

## Safety notes

- `workspace-write` lets Codex edit **any file under WORKDIR**, including things like `.env` or config/DB files. For a sensitive repo, pass a narrower WORKDIR (a subdir) or `read-only`.
- The subagent is instructed to never use approval-bypass flags; it relies on the sandbox. Don't override that.
- This needs the `codex` CLI installed and authenticated (`codex login`). If missing, `codex:setup`-style checks: `codex --version`.
