---
name: code-review
description: Review local changes or GitHub pull requests for bugs, regressions, risky assumptions, and missing verification. Use when the user asks for a review, PR review, or a correctness-focused second pass instead of implementation work.
---

# Code Review

Review with a bug-finding mindset. Prioritize correctness, regressions, safety, and missing coverage over style or refactoring advice.

## Workflow

1. Define scope first.
   - For local changes, inspect `git status --short`, `git diff --stat`, and the relevant diffs.
   - For a PR, use `gh pr view` and `gh pr diff` if the repository and auth are available.
2. Read the changed code and enough surrounding context to understand behavior.
3. Look for concrete issues:
   - broken logic or incorrect edge-case handling
   - behavior regressions
   - config or docs drift that makes the instructions wrong
   - unsafe assumptions about state, ordering, paths, or user input
   - missing validation or missing tests where the change is risky
4. Ignore low-value nitpicks unless the repo's local guidance explicitly requires them.
5. Verify suspicions before reporting them. Read adjacent code, existing tests, and call sites instead of guessing.

## Output

Report findings first, ordered by severity, with file references. After findings, list open questions or assumptions, then give a brief summary of residual risk or testing gaps.

If no issues are found, say that explicitly and still mention any residual risk from untested areas or incomplete context.
