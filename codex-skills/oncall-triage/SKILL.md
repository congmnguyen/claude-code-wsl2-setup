---
name: oncall-triage
description: Triage GitHub issues for immediate operational impact and identify which ones need urgent oncall attention. Use when the user wants help reviewing recent bug reports and labeling only the truly blocking cases.
---

# Oncall Triage

Review recent bug reports conservatively. The bar for `oncall` should be high: label issues only when they are genuinely blocking users or breaking core workflows.

## Workflow

1. Gather the candidate bug issues with `gh issue list` using the repository, labels, and recency window the user wants.
2. Create a complete checklist so every candidate is processed exactly once.
3. For each issue, read the title, body, labels, and comments with `gh issue view`.
4. Evaluate user impact:
   - Does this stop users from completing core tasks?
   - Is the product crashing, hanging, or becoming unusable?
   - Is there a reasonable workaround?
5. Add the `oncall` label only when the impact is immediate and severe.

## Guardrails

- Do not comment on issues unless the user asks.
- Do not remove labels.
- If an issue is severe but evidence is incomplete, explain why instead of over-labeling it.

## Output

List which issues were labeled, which were reviewed but not labeled, and the short reasoning for each decision.
