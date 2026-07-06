# Claude Code WSL2 Setup

My active Claude Code setup for WSL2 + Windows Terminal, built around one idea:
keep Claude focused on orchestration and hand implementation churn to Codex.

The repo only tracks the pieces I actually use: Codex delegation, LSP navigation, screenshot
paste, Windows notifications, statusline, and token/context hygiene hooks.

## Delegate implementation without filling Claude's main context

Large implementation tasks are expensive twice: Claude spends tokens doing the work, then
keeps every file read, edit, test run, and retry in the main conversation. That history
competes with the architecture and product context Claude needs to orchestrate well.

[`codex-delegate`](codex-delegate.md) sends a well-specified implementation task to Codex
through an isolated Claude subagent. Codex does the read/edit/test loop; the main session gets
back a short result and keeps its context for planning, steering, and review.

In the real run below, two Codex delegates handled tens of thousands of worker tokens in
parallel while the main Claude session still showed 8% context and 6% five-hour usage.

<p align="center">
  <img src="assets/preview-codex-delegate.png" alt="Claude Code running two Codex delegate subagents while the main context and five-hour usage stay low" width="720"><br>
  <em>Claude keeps the decisions; Codex absorbs the implementation transcript.</em>
</p>

**[Set up Codex delegation →](codex-delegate.md)**

---

## Featured fixes

Start with these — they are the highest-leverage pieces in the repo:

- **[Codex delegate](codex-delegate.md)** — routes large mechanical implementation to Codex
  through an isolated Sonnet wrapper, keeping the premium Claude orchestrator context clean.
- **[LSP setup](lsp-setup.md)** — lets Claude use real Go-to-Definition / reference
  navigation instead of burning tokens on broad file search.
- **[Image paste](image-paste.md)** — paste a Windows screenshot into Claude Code or Codex as
  a usable WSL file path.
- **[Notifications](claude-notify.md)** — get a Windows notification when Claude is done,
  needs permission, or a background agent completes, without interrupting you while Windows
  Terminal is focused.
- **[Secrets hygiene hook](secrets-hygiene-hook.md)** — blocks credential-file reads before
  secrets can land in the transcript.
- **[Bash output truncation hook](truncate-bash-output.md)** — trims huge command output to
  head+tail so one verbose test/build log does not bloat the rest of the context.

---

## Preview

<p align="center">
  <img src="assets/preview-statusline.png" alt="Custom statusline showing project, context bar, 5h and weekly usage" width="720"><br>
  <em>claude-code-wsl2-setup | main | [░░░░░░░░░░] 6% | 5h:10% | W:95%</em>
</p>

<p align="center">
  <img src="assets/preview-notification.png" alt="Windows balloon tip notification — Claude Code Done!" width="720"><br>
  <em>Balloon tip fires on Claude Code <code>Notification</code> events, skipped when Windows Terminal is focused</em>
</p>

## What it fixes

- **Image paste** — copy a screenshot on Windows and paste the file path straight into Claude Code or Codex. A small Go daemon ([wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli)) polls the Windows clipboard, saves new screenshots under `/tmp/.wsl-screenshot-cli/`, and rewrites the clipboard so paste returns the WSL path.
- **Shift+Enter newline** — insert a newline without submitting, in both the VSCode integrated terminal and Windows Terminal.
- **CapsLock → Escape** — remap CapsLock to Escape system-wide via SharpKeys (registry-level, works in WSL2, Vim, games, and elevated processes).
- **"Needs your input" Windows notification** — fires on Claude Code `Notification` events when Claude finishes, asks for permission, or a background agent completes; suppressed automatically when Windows Terminal is already focused. WSL2 variant uses a balloon tip; the native PowerShell variant uses a modern Windows toast.
- **Status line** — project directory, git branch, context-window fill bar, and 5-hour / 7-day usage, color-coded by severity.
- **Secrets hygiene hook** — blocks Claude from reading credential files into the transcript with `Read`, `Grep`, or content-printing shell commands.
- **Bash output truncation hook** — cuts huge command output (test runs, build logs, JSON dumps) down to head+tail with an omission marker, so one verbose command doesn't eat the context window for the rest of the session.
- **Settings tweaks** — disable the `Co-authored-by: Claude` git attribution and pre-accept the project trust dialog.
- **Windows browser** — open links and OAuth flows in your existing Windows browser instead of Chromium inside WSL2.

## Setup

```bash
git clone https://github.com/congmnguyen/claude-code-wsl2-setup.git
cd claude-code-wsl2-setup
claude
```

Then prompt:

> Set this up

Claude will read the docs and configure everything.

## What's included

### Claude Code core

| File | Fix |
|------|-----|
| [`lsp-setup.md`](lsp-setup.md) | Official LSP plugins + language servers for TypeScript, Python, Go, Rust |
| [`statusline.md`](statusline.md) | Project dir, git branch, context bar, 5h / 7d usage |
| [`settings.md`](settings.md) | Disable git attribution, skip trust dialog |

### Agent workflows

| File | Fix |
|------|-----|
| [`codex-delegate.md`](codex-delegate.md) | Codex delegation with token isolation via a Sonnet wrapper instead of direct MCP/plugin foreground output |
| [`mcp-setup.md`](mcp-setup.md) | DeepWiki MCP; Figma Desktop is project-specific |
| [`playwright-cli.md`](playwright-cli.md) | Token-efficient browser automation; preferred over Playwright MCP for coding agents |

### Safety and context hygiene

| File | Fix |
|------|-----|
| [`secrets-hygiene-hook.md`](secrets-hygiene-hook.md) + [`hooks/block-secret-reads.sh`](hooks/block-secret-reads.sh) | PreToolUse hook — block credential-file reads before they hit the transcript |
| [`truncate-bash-output.md`](truncate-bash-output.md) + [`hooks/truncate-bash-output.sh`](hooks/truncate-bash-output.sh) | PostToolUse hook — truncate huge Bash output to head+tail before it eats context |

### WSL / Windows bridge

| File | Fix |
|------|-----|
| [`image-paste.md`](image-paste.md) | Screenshot paste — wsl-screenshot-cli daemon + optional Alt+V keybinding |
| [`claude-notify.md`](claude-notify.md) | Windows balloon tip — WSL2 variant for Claude Code `Notification` hooks and Codex `notify` |
| [`shift-enter.md`](shift-enter.md) | Shift+Enter newline in VSCode terminal and Windows Terminal |
| [`browser.md`](browser.md) | Open links in your Windows browser via `BROWSER` env var |
| [`capslock-esc.md`](capslock-esc.md) | CapsLock → Escape registry remap via SharpKeys |

## Custom agents and skills

| Path | Contents |
|------|----------|
| [`agents/`](agents/) | `code-architect`, `codex-delegate` |
| [`skills/`](skills/) | Active local skills: `codex-delegate`, `commit-push-pr`, `deep-teach`, `pytorch-training` |
| [`hooks/`](hooks/) | `block-secret-reads.sh` PreToolUse hook, `truncate-bash-output.sh` PostToolUse hook |
| [`scripts/`](scripts/) | `codex-run.sh` wrapper used by the `codex-delegate` Claude agent |

Copy the matching files from [`agents/`](agents/), [`skills/`](skills/), [`hooks/`](hooks/),
and [`scripts/`](scripts/) to `~/.claude/agents/`, `~/.claude/skills/`,
`~/.claude/hooks/`, and `~/.claude/scripts/` for Claude Code.

Codex skills are maintained separately at
[`congmnguyen/codex-skills`](https://github.com/congmnguyen/codex-skills).

## Pruned notes

Native Windows PowerShell notifications, WSLg voice-mode audio, and uninstalled Claude
skills were removed from the main repo because they are not part of the active local setup.

## Recommended third-party skills

Skills not authored here but worth installing alongside the setup:

- **[liteparse](https://github.com/run-llama/liteparse)** (LlamaIndex, MIT) — parse PDF, DOCX, PPTX, XLSX, and images locally with no cloud calls. Useful for feeding unstructured documents into Claude or Codex without uploading them. Try it in the browser first: [simonw.github.io/liteparse](https://simonw.github.io/liteparse/). Then install the npm package globally and copy the upstream `SKILL.md` into `~/.claude/skills/liteparse/`:

  ```bash
  npm i -g @llamaindex/liteparse
  sudo apt-get install -y libreoffice   # required for DOCX/PPTX/XLSX
  ```

## License

[MIT](LICENSE) — feel free to copy, fork, or adapt for your own setup.
