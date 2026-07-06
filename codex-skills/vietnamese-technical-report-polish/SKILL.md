---
name: vietnamese-technical-report-polish
description: Use when polishing Vietnamese technical reports, Desktop HTML/Markdown explainers, seminar handovers, monthly work reports, or presentation notes. Focuses on removing internal clutter, rewriting jargon into spoken Vietnamese, preserving meaning, and preparing likely Q&A.
---

# Vietnamese Technical Report Polish

Use this for repeated report and presentation cleanup tasks, especially files under `/mnt/c/Users/cong/Desktop` or `/mnt/c/Users/cong/Downloads`.

## Workflow

1. Inspect the actual artifact first.
   - Read the file before suggesting changes.
   - Preserve the current format unless the user asks for another output type.
   - For HTML, keep the existing visual language and edit the source directly.

2. Remove audience-hostile clutter.
   - Cut deploy/runtime/API-spec details unless the audience needs them.
   - Remove AI-written roadmap claims the user cannot defend.
   - Prefer a few defensible technical points over exhaustive logs.

3. Rewrite for spoken Vietnamese.
   - Keep Vietnamese diacritics.
   - Replace awkward English terms when a natural Vietnamese phrase is clearer.
   - Keep accepted technical terms when the user is comfortable with them, such as `metrics`, `repair context`, `queryData`, `MCP`, `Dify`.
   - Explain hard terms with one concrete example.

4. Make the report defensible.
   - Identify likely hard questions.
   - Prepare short answer-ready explanations.
   - Separate what was measured from what is only a plan or hypothesis.

5. Verify after editing.
   - For HTML, check basic tag balance and CSS brace balance.
   - For prose-only edits, reread the changed section and confirm it still says the same thing.

## Output

When editing a file, report:

- The file changed.
- The main sections cleaned or rewritten.
- Any validation that was run.

Do not leave the final report only in chat when the user asked for a file artifact.
