---
name: dedupe
description: Find likely duplicate GitHub issues by comparing problem statements, reproduction details, and user impact. Use when the user wants help triaging an issue or linking it to earlier reports.
---

# Dedupe

Find up to three likely duplicates with evidence. Optimize for precision over recall: a short trustworthy list is better than a broad noisy one.

## Workflow

1. Open the target issue with `gh issue view` and summarize the core problem, trigger, environment, and user impact.
2. Skip duplicate hunting if the issue is closed, is broad product feedback, or already has a convincing duplicate comment.
3. Search GitHub with several query shapes:
   - exact or near-exact error text
   - user-impact wording
   - subsystem or file names
   - alternative phrasing for the same symptom
4. Read each candidate issue before keeping it. Compare root cause, reproduction, and severity, not just keywords.
5. Keep at most three candidates that are genuinely close.

## False Positives To Reject

- same area but clearly different failure mode
- same symptom caused by a different workflow or platform
- broad feature requests that only overlap at a high level
- stale issues with no evidence they match the current report

## Output

For each duplicate candidate, cite the issue number, title, and the specific evidence that makes it a match. If no strong duplicates exist, say so instead of forcing weak matches.
