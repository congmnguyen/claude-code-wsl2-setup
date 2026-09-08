# Optional extras

| Path | Contents |
|------|----------|
| [`agents/`](agents/) | `code-architect` |
| [`skills/`](skills/) | Skills to copy in as needed: `commit-push-pr`, `deep-teach`, `pytorch-training`. In my previous setup, I installed these per project rather than globally to keep unrelated work free of extra instructions |

Copy the matching files to `~/.claude/agents/` and `~/.claude/skills/`.

After adding or updating a skill, run `/reload-skills` to make it available without
restarting the session. Custom agents still require a restart.

Dropped pieces (Codex delegation and its companion repo) live in [`archive/`](archive/).

## Recommended third-party skills

Skills not authored here but worth installing alongside the setup:

- **[liteparse](https://github.com/run-llama/liteparse)** (LlamaIndex, MIT) — parse PDF, DOCX, PPTX, XLSX, and images locally with no cloud calls. Useful for feeding unstructured documents into Claude or Codex without uploading them. Try it in the browser first: [simonw.github.io/liteparse](https://simonw.github.io/liteparse/). Then install the npm package globally and copy the upstream `SKILL.md` into `~/.claude/skills/liteparse/`:

  ```bash
  npm i -g @llamaindex/liteparse
  sudo apt-get install -y libreoffice   # required for DOCX/PPTX/XLSX
  ```

These extras are independent of the WSL2 fixes. Install only what your project needs.
See [maintenance](maintenance.md) for verification and removal.
