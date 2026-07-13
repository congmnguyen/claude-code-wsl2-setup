---
name: codex-delegate
description: Delegate a heavy or mechanical coding task to the configured Codex CLI model via a low-effort Sonnet wrapper, so Codex's large transcript stays OUT of the main orchestrator context. Trigger when the user says "delegate to codex", "hand this to codex", "let codex do X", or when a well-specified implementation/refactor/migration/bulk task is large enough that doing it inline would flood context with tool round-trips. Do NOT use for small tasks you can one-shot.
allowed-tools: Bash, Read, Glob, Grep, LS
---

## What this does

Spawns the **`codex-delegate` subagent** (low-effort Sonnet), which runs `codex exec` with output redirected to a log and returns only a ~10-line summary. Routing lives in `~/.claude/CLAUDE.md` § *Codex Delegation*; wrapper mechanics live in the agent definition. This file covers only the orchestrator side: how to spawn and what to do with the result.

## How to invoke

1. Turn the request (`$ARGUMENTS` if given, else the current task) into a **self-contained spec** — Codex has no memory of this conversation, so include everything: exact behavior, file paths, edge cases, and how to verify.
2. Spawn the subagent (background), passing TASK, WORKDIR (default: current working directory), SANDBOX (`workspace-write` for edits, `read-only` for investigation), and a VERIFY command if there's a test/build to check.

   **Preferred** — the dedicated agent (available after a Claude Code restart that registers `.claude/agents/codex-delegate.md`):
   ```
   Agent(
     subagent_type: "codex-delegate",
     description: "delegate to codex",
     prompt: "TASK: <full self-contained spec>\nWORKDIR: <abs path>\nSANDBOX: workspace-write\nVERIFY: <test/build cmd or omit>\nTAKEOVER: allowed  # optional — lets the wrapper finish mechanical remainder itself if Codex is quota-blocked/crashed; omit to restrict it to salvage-only",
     run_in_background: true
   )
   ```

   **Fallback** — if that errors with `Agent type 'codex-delegate' not found` (the definition isn't loaded in this session yet), spawn a generic Sonnet subagent that reads the same playbook file:
   ```
   Agent(
     subagent_type: "general-purpose",
     model: "sonnet",
     effort: "low",
     description: "delegate to codex",
     prompt: "First Read /home/cong/.claude/agents/codex-delegate.md and adopt it as your complete role and instructions. Then carry out:\nTASK: <full self-contained spec>\nWORKDIR: <abs path>\nSANDBOX: workspace-write\nVERIFY: <test/build cmd or omit>",
     run_in_background: true
   )
   ```

3. When it returns its compact summary, **review the actual change yourself** before accepting: run `git diff` / `git status`, sanity-check the files it reports, and re-run VERIFY if correctness matters. Codex is fast but not infallible — you own the merge.

## Long tasks, status checks, failures

- A background wrapper sometimes ends its turn early ("waiting for notification") on multi-notification runs. If a long task has gone quiet, **SendMessage the same agent id** asking for a concrete status — don't spawn a fresh wrapper (it would re-derive everything cold). Same for follow-up work that needs the task's context.
- The wrapper may return `BLOCKED — quota resets at <time>` (Codex usage limit). That's not a failure to retry — reschedule the same delegation after the reset, or do the work another way.
- Codex quota is a shared budget: batch related work into one delegation instead of many small ones, and don't redo a delegation for cosmetic reasons.

## Safety notes

- `workspace-write` lets Codex edit **any file under WORKDIR**, including things like `.env` or config/DB files. For a sensitive repo, pass a narrower WORKDIR (a subdir) or `read-only`.
- Never run two `workspace-write` delegations against the same `WORKDIR` concurrently, and do not edit that checkout from the main context while a write delegation is running. Parallel `read-only` delegations are safe. If parallel writers are explicitly needed, create a separate Git worktree for each task and pass its path as `WORKDIR`.
- The subagent invokes Codex only via `~/.claude/scripts/codex-run.sh`, which accepts no flag pass-through — approval-bypass flags are structurally impossible, and quota/stall detection is built in. Don't bypass the script.
- This needs the `codex` CLI installed and authenticated (`codex login`). If missing, `codex:setup`-style checks: `codex --version`.
