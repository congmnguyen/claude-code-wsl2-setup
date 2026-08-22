# Claude Code WSL2 Setup

My active Claude Code setup for WSL2 + Windows Terminal.

The repo only tracks the pieces I actually use: LSP navigation, screenshot paste, Windows
notifications, statusline, and token/context hygiene hooks. Anything optional is marked as
such — my own Claude Code config is deliberately minimal beyond the above: no custom
skills, no MCP servers, no global `CLAUDE.md`.

## Who this is for

Use this if you run Claude Code from WSL2 and want the Windows side to stop feeling
bolted on: screenshots paste as WSL paths, notifications land in Windows, browser
links open in your normal browser, and long implementation loops can move to Codex
without filling Claude's main conversation.

Where to start, depending on what hurts most:

- **Context burn** → [`lsp-setup`](lsp-setup.md).
- **Windows/WSL friction** → [`image-paste`](image-paste.md) and [`claude-notify`](claude-notify.md).
- **No visibility into what Claude did** → [`statusline`](statusline.md), plus optional
  [`langsmith-tracing`](langsmith-tracing.md) when you want full turn-level traces.

## Preview

<p align="center">
  <img src="assets/preview-statusline.png" alt="Custom statusline showing project, context bar, 5h and weekly usage" width="720"><br>
  <em>claude-code-wsl2-setup | main | [░░░░░░░░░░] 6% | 5h:10% | W:95%</em>
</p>

<p align="center">
  <img src="assets/preview-notification.png" alt="Windows balloon tip notification — Claude Code Done!" width="720"><br>
  <em>Balloon tip fires on Claude Code <code>Notification</code> events, skipped when Windows Terminal is focused</em>
</p>

<p align="center">
  <img src="assets/preview-codex-notification.png" alt="Windows balloon tip notification showing Codex's last reply" width="720"><br>
  <em>Codex's top-level <code>notify</code> command shows the completed turn's last reply</em>
</p>

<p align="center">
  <img src="assets/preview-terminal-title.png" alt="Windows Terminal tabs labelled by directory and active coding agent" width="720"><br>
  <em>Shell-managed titles keep Claude Code and Codex tabs distinguishable.</em>
</p>

## Setup

```bash
git clone https://github.com/congmnguyen/claude-code-wsl2-setup.git
cd claude-code-wsl2-setup
claude
```

Then prompt:

> Set this up

Claude will read the docs and configure everything.

For a manual install, copy the relevant files from [`agents/`](agents/) and [`skills/`](skills/)
into the matching `~/.claude/` directories, then read the linked setup page for the feature
you want.

## What's included

### Claude Code core

| File | Fix |
|------|-----|
| [`lsp-setup.md`](lsp-setup.md) | Official LSP plugins + language servers for TypeScript, Python, Go, and Rust, so Claude uses real Go-to-Definition / find-references instead of burning tokens on broad file search |
| [`statusline.md`](statusline.md) | Project dir, git branch, context-window fill bar, and 5-hour / 7-day usage, color-coded by severity |
| [`langsmith-tracing.md`](langsmith-tracing.md) | **Optional.** Project-level LangSmith traces for turns, tool calls, subagent runs, and compaction events — without enabling telemetry for every local session |
| [`settings.md`](settings.md) | Disabling the `Co-authored-by: Claude` git attribution and session links, and pre-accepting the project trust dialog |

### Agent workflows

| File | Fix |
|------|-----|
| [`mcp-setup.md`](mcp-setup.md) | Optional project-specific Figma Desktop MCP |

### WSL / Windows bridge

| File | Fix |
|------|-----|
| [`image-paste.md`](image-paste.md) | Copy a screenshot on Windows, paste the file path straight into Claude Code or Codex. A systemd user service keeps [wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli) running, saves shots under `/tmp/.wsl-screenshot-cli/`, and restarts the monitor if it exits. Optional Alt+V keybinding |
| [`terminal-title.md`](terminal-title.md) | Distinct zsh tab titles for the current project and active agent, such as `text2sql-agent · ✳ Claude` or `text2sql-agent · >_ Codex` |
| [`claude-notify.md`](claude-notify.md) | Windows balloon tip on Claude Code `Notification` events — Claude finished, needs permission, or a background agent completed — suppressed when Windows Terminal is already focused |
| [`codex-notify.md`](codex-notify.md) | Reuse the same balloon script through Codex's top-level `notify` command |
| [`bin/tmux-notify-run`](bin/tmux-notify-run) | Detached tmux jobs with logs, exit status, and Windows completion notification |
| [`shift-enter.md`](shift-enter.md) | Shift+Enter inserts a newline instead of submitting, in both the VSCode integrated terminal and Windows Terminal |
| [`browser.md`](browser.md) | Open links and OAuth flows in your Windows browser via `BROWSER`, plus an XDG fallback for OAuth CLIs |
| [`capslock-esc.md`](capslock-esc.md) | CapsLock → Escape via a SharpKeys registry remap — works in WSL2, Vim, games, and elevated processes |

## Custom agents and skills

| Path | Contents |
|------|----------|
| [`agents/`](agents/) | `code-architect` |
| [`skills/`](skills/) | Skills to copy in as needed: `commit-push-pr`, `deep-teach`, `pytorch-training`. My own `~/.claude/skills/` stays empty — I install per project instead of globally, so nothing competes for context on unrelated work |

Copy the matching files to `~/.claude/agents/` and `~/.claude/skills/`.

After adding or updating a skill, run `/reload-skills` to make it available without
restarting the session. Custom agents still require a restart.

Dropped pieces (Codex delegation and its companion repo) live in [`archive/`](archive/).

## Troubleshooting

If a hook, plugin, or other customization breaks Claude Code, start a clean diagnostic
session with `claude --safe-mode`. Use `/doctor`, `/hooks`, and `/mcp` to inspect the
installation and loaded integrations.

## Pruned notes

Native Windows PowerShell notifications, WSLg voice-mode audio, Playwright browser
automation, and uninstalled Claude skills were removed from the main repo because they are
not part of the active local setup. Git history keeps them if you want the old versions.

The three `PreToolUse` / `PostToolUse` hooks were removed for a different reason: each one
judged tool input by pattern, and each was measurably wrong in both directions.

- `truncate-bash-output` rewrote `.stdout` to head + tail. Claude Code already saves
  oversized output to a file and shows a preview, losing nothing; truncating below that
  threshold suppressed the built-in behaviour and destroyed the middle permanently — where
  test failures and stack traces live. It also cost more context than the preview it
  replaced, and died on long lines (`jq: Argument list too long`), passing the full
  untruncated output through.
- `block-secret-reads` blocked reads of credential files by regex. Probed with synthetic
  payloads it caught 1 of 11 trivial rephrasings (`dd`, `od`, `nl`, `tac`, `rev`, `perl`,
  `tee`, a `while read` loop, `tar | base64`, `python3 -c`) while rejecting all 5 ordinary
  source files named like `token_manager.py` or `credentials_service.py`. Exact-match
  `permissions.deny` rules do the same job without guessing.
- `format-python-with-ruff` ran `ruff check --fix` after every Python edit, which deleted an
  `import` out of a file the moment it was written — leaving what is on disk different from
  what the agent believes it wrote. It could also spin forever on a relative path, since
  `dirname .` never reaches `/`.

`Notification` hooks stayed. They react to events rather than judging tool input, so there
is no pattern to get wrong.

## Recommended third-party skills

Skills not authored here but worth installing alongside the setup:

- **[liteparse](https://github.com/run-llama/liteparse)** (LlamaIndex, MIT) — parse PDF, DOCX, PPTX, XLSX, and images locally with no cloud calls. Useful for feeding unstructured documents into Claude or Codex without uploading them. Try it in the browser first: [simonw.github.io/liteparse](https://simonw.github.io/liteparse/). Then install the npm package globally and copy the upstream `SKILL.md` into `~/.claude/skills/liteparse/`:

  ```bash
  npm i -g @llamaindex/liteparse
  sudo apt-get install -y libreoffice   # required for DOCX/PPTX/XLSX
  ```

## License

[MIT](LICENSE) — feel free to copy, fork, or adapt for your own setup.
