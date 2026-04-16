---
name: spec
description: Interview the user to clarify requirements, constraints, edge cases, and tradeoffs, then write a complete implementation spec to SPEC.md. Use when a request is still ambiguous or the user explicitly wants a spec before coding.
---

# Spec

Turn a rough idea into an actionable specification. Ask focused follow-up questions first, then write `SPEC.md` only after the core product and implementation choices are clear.

## Interview

Ask concise, high-signal questions in rounds. Prefer the hardest unknowns over obvious basics. Cover:

- user goals and success criteria
- target users and workflows
- technical constraints, stack, and integration points
- UI or UX expectations
- edge cases, failure handling, and data validation
- performance, security, rollout, and testing requirements

If the user already provided enough detail, summarize the open questions instead of re-asking everything.

## Write SPEC.md

Write the finished spec to `SPEC.md` in the current working directory. Include:

- problem statement
- goals and non-goals
- user stories or workflows
- functional requirements
- non-functional requirements
- technical approach
- open risks and tradeoffs
- implementation plan
- testing and rollout plan

State assumptions explicitly so the spec remains usable even when some details were not provided.
