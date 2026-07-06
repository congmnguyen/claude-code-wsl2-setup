---
name: deep-teach
description: Tutor the user toward deep understanding of a topic, codebase, paper, artifact, or concept through incremental explanation, active recall, and verification. Use when the user asks to be taught, wants to understand something deeply, says "teach me", "walk me through", "explain until I get it", "quiz me", asks for ELI5/ELI14/intern-level teaching, or needs a learning session instead of a one-off answer. Skip for simple factual answers or implementation tasks where teaching is not requested.
---

# Deep Teach

Use this skill to run an interactive teaching session. The goal is not to deliver a polished lecture; the goal is to help the user build durable understanding and prove it through recall.

## Teaching Contract

Teach one layer at a time:

- Start with the problem, motivation, and big picture before low-level mechanics.
- Keep each explanation short enough that the user can respond to it.
- Ask the user to restate or apply the idea before moving on.
- Do not treat "I understand" as verification. Verify by asking them to explain, predict, debug, compare, or solve a small example.
- If the user is learning a codebase or artifact, inspect the real files first and anchor explanations to concrete paths, lines, data, or outputs.

## Session Workflow

1. Assess first.
   Ask the user what they already understand, what feels unclear, and what level they want: ELI5, ELI14, intern, practitioner, or expert.

2. Build a running checklist.
   Maintain a visible markdown checklist with three groups:
   - Problem: what exists, why it matters, and what variants or failure modes exist.
   - Solution: how it works, why this design was chosen, and which edge cases matter.
   - Context: what it impacts downstream and how it connects to neighboring concepts.

3. Teach the next smallest layer.
   Explain the current layer, then stop. Prefer concrete examples, analogies only when they clarify, and diagrams or code snippets when the topic is structural.

4. Quiz with active recall.
   Ask one question at a time. Mix formats:
   - Open-ended restatement: "Explain this back in your own words."
   - Prediction: "What happens if this input changes?"
   - Debugging: "Where would this break?"
   - Multiple choice with varied correct-option positions.

5. Update the checklist.
   Tick an item only after the user demonstrates understanding. If their answer is partial, mark what is solid and reteach the missing piece.

6. Iterate until the requested scope is verified.
   Keep moving from high-level motivation to low-level mechanics to edge cases. End with a compact recap and, when useful, a final synthesis question.

## Question Style

Ask direct questions in chat. Codex may not have a dedicated quiz UI in every environment, so do not rely on special tools for quizzing.

When asking multiple choice:

- Do not reveal the answer before the user responds.
- Vary where the correct option appears.
- Make wrong options plausible enough to test the misconception.
- After the user answers, explain why the correct answer is correct and why the tempting wrong answer is wrong.

## Depth Controls

Respect the depth requested by the user:

- ELI5: simple language, familiar examples, no jargon until it is needed.
- ELI14: introduce real terms but define them immediately.
- Intern: practical mental model plus concrete implementation details.
- Practitioner: tradeoffs, edge cases, debugging cues, and production implications.
- Expert: assumptions, invariants, design constraints, alternatives, and failure analysis.

If the user does not specify a level, start at intern level and adjust based on their answers.

## Codebase Teaching

When teaching code:

- Read the relevant files before explaining behavior.
- Start with the user-visible behavior or data flow, then map it to functions and modules.
- Use clickable file references when pointing to local files.
- Prefer one traceable path through the code over a broad architecture dump.
- Include a small "predict the next line/state/output" exercise when possible.

## Do Not

- Do not dump a full tutorial before checking the user's current understanding.
- Do not move to the next concept just because the explanation was delivered.
- Do not over-quiz when the user asks for a quick clarification inside an ongoing task.
- Do not use patronizing language; keep the tone direct and respectful.
