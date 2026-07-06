---
name: text2sql-eval-triage
description: Use when debugging or comparing Text-to-SQL agent eval results in /home/cong/code/text2sql-agent, especially Promptfoo BI20/VNP failures, strict-vs-smoke differences, queryData mismatches, metadata fixes, regression checks, and deciding whether a failure is real or a checker issue.
---

# Text-to-SQL Eval Triage

Use this for repeated Text-to-SQL evaluation work in `/home/cong/code/text2sql-agent`.

## Workflow

1. Ground the run first.
   - Check `git status --short`.
   - Identify the exact eval config, result JSON, dataset, model, workspace, and branch.
   - Do not assume BI20, BI20 strict, VNP-100, smoke, and ablation runs are comparable unless the grader and provider are the same.

2. Read the evidence before recommending a fix.
   - Open the failing result JSON under `evaluation/results/`.
   - For each failing case, capture: question, generated SQL, assertion reason, `queryData`, expected rows or anchors, selected tables, and relevant `_metrics`.
   - If the result only shows a rubric message, find the provider output metadata before judging.

3. Classify the failure.
   - `real_agent_failure`: wrong table, wrong column, wrong aggregation, wrong filter, bad join/union, empty schema, repair loop.
   - `metadata_gap`: Platform metadata, glossary, SQL expression, workspace prompt, or join hint is missing or misleading.
   - `checker_issue`: assertion too strict, alias mismatch, unit mismatch, regex/token matching bug, CTE parsing problem.
   - `runtime_issue`: MCP/Trino unavailable, model endpoint mismatch, timeout, rate limit, stale image/config.
   - `jitter`: rerun changed output without code/config change.

4. Pick the smallest useful fix.
   - Prefer Platform metadata, glossary, SQL examples, or workspace config for business truth.
   - Prefer assertion fixes when queryData is correct but the checker rejects it.
   - Prefer code changes only when the orchestration, validator, provider, or repair behavior is actually wrong.
   - Keep experimental features behind flags when they affect retrieval or generation behavior.

5. Verify with the narrowest meaningful run.
   - Rerun the specific failing case or shard first.
   - Then run BI20 strict or the relevant regression set if behavior changed.
   - Compare before/after by case, not just aggregate pass count.

## Common Commands

Run these only after checking the current repo state and exact filenames:

```bash
cd /home/cong/code/text2sql-agent
git status --short
promptfoo eval --no-cache -j 4 -c evaluation/promptfooconfig-bi20-strict.yaml
promptfoo eval --no-cache -j 4 -c evaluation/promptfooconfig-bi20.yaml
```

## Output

Lead with the verdict:

- Is this a real agent failure, metadata gap, checker issue, runtime issue, or jitter?
- What is the smallest fix?
- What command verifies it?

For Vietnamese-facing answers, explain terms plainly and preserve Vietnamese diacritics.
