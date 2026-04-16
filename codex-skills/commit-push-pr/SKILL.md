---
name: commit-push-pr
description: Prepare a branch, create a commit, push it, and open a GitHub pull request. Use when the user wants Codex to finish the git workflow after changes are ready to ship.
---

# Commit Push Pr

Finish the git handoff after implementation is complete. Inspect the working tree first, then branch, commit, push, and open a PR with a concise summary.

## Workflow

1. Inspect state with `git status --short`, `git diff --stat`, `git diff HEAD`, and `git branch --show-current`.
2. Stop if there are no relevant changes, if the repo is in a conflicted state, or if unrelated dirty changes make it unsafe to continue.
3. If currently on `main` or `master`, create a short descriptive branch before committing.
4. Stage only the files relevant to the requested work.
5. Write one clear commit message that describes the user-facing or developer-facing outcome.
6. Push the branch to `origin`.
7. Open a PR with `gh pr create` using a concise title and body grounded in the actual diff.

## Guardrails

- Do not amend or rewrite history unless the user explicitly asks.
- Do not stage unrelated changes.
- If push or PR creation needs credentials or approval, request it instead of working around it.
- After completion, report the branch name, commit hash, and PR URL.
