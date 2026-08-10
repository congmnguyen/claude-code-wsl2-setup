# Claude Code customization ablation

This harness compares the live Claude Code setup without renaming, deleting, or
editing files under `~/.claude`. Each run starts a new non-interactive session,
uses plan mode, and writes its output under `.ablation-results/`.

## Profiles

| Profile | What it measures |
|---|---|
| `minimal` | Default model and built-in tools with customizations disabled by `--safe-mode` |
| `instructions` | Marginal value of the live global `~/.claude/CLAUDE.md` over `minimal` |
| `no-mcp` | Normal setup with MCP discovery explicitly disabled |
| `full` | Current live setup |

`instructions` is the cleanest single-factor comparison. `no-mcp` versus `full`
isolates MCP value. `instructions` versus `no-mcp` is intentionally a bundle
comparison: it adds normal skills, plugins, hooks, memory, and project context,
so it must not be interpreted as the effect of skills alone.

The harness uses `--safe-mode`, not `--bare`, for the minimal profiles. Both
remove automatic customization, but `--bare` deliberately skips OAuth/keychain
authentication and therefore cannot run against a Claude Pro login without an
API key.

## Run

From the repository or target project being evaluated:

```bash
/home/cong/code/claude-code-wsl2-setup/ablation/run-matrix.sh \
  /home/cong/code/claude-code-wsl2-setup/ablation/tasks/01-verification-audit.txt
```

Pin the model when comparing runs over time:

```bash
ABLATION_MODEL=opus ABLATION_EFFORT=high ABLATION_MAX_BUDGET=5 \
  ./ablation/run-matrix.sh ablation/tasks/01-verification-audit.txt
```

Run profiles separately when a full matrix would spend unnecessary tokens:

```bash
./ablation/run.sh minimal ablation/tasks/01-verification-audit.txt
./ablation/run.sh instructions ablation/tasks/01-verification-audit.txt
```

The runner prints the result directory. It contains raw JSON, stderr, metadata,
and a compact `summary.json` when Claude returned valid JSON.
`run-matrix.sh` attempts every profile even if one fails, then exits non-zero if
any profile failed.
Result files are created with user-only permissions because prompts and inspected
repository evidence may be sensitive. The result directory is also gitignored.

These runs send the task and any files Claude chooses to inspect to Anthropic and
may incur API or subscription usage. Review the task and repository sensitivity,
then set an appropriate `ABLATION_MAX_BUDGET` before running a matrix.

Run the offline runner check with:

```bash
./ablation/test-runner.sh
```

## Evaluation discipline

- Use the same task text, working directory, model, and effort for every profile.
- Start with read-only tasks. Use a disposable worktree for implementation tasks.
- Score correctness against tests or explicit acceptance criteria, not writing style.
- Repeat close results at least three times because model output is stochastic.
- Do not preserve a customization merely because it was invoked; preserve it only
  when it measurably improves correctness, verification, safety, or interventions.
- Record human scoring in `scorecard.tsv`. Lower tool calls, cost, and duration are
  useful only after the quality and safety threshold is met.

## Interpreting the current setup

The live global `CLAUDE.md` is already small and mostly contains behavioral
guardrails. Treat its removal as an experiment, not an expected cleanup. The
global skill collection and plugin-provided context are the larger candidates for
project scoping. MCP should be judged on tasks that genuinely require third-party
library internals; otherwise a no-MCP win is not meaningful.
