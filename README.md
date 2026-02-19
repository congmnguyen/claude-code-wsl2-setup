# Claude Code WSL2 Setup

Fixes for the most annoying Claude Code papercuts on WSL2 + Windows Terminal.

## What it fixes

- **Image paste** — copy a screenshot on Windows, press `Alt+V` in Claude Code and it just works. (Ctrl+V is intercepted by Windows Terminal; the Windows clipboard gives BMP not PNG — both fixed.)
- **Shift+Enter newline** — insert a newline without submitting, in both VSCode integrated terminal and Windows Terminal.
- **"Needs your input" Windows notification** — get a system tray balloon tip when Claude finishes a long task and is waiting for you.

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

| File | Fix |
|------|-----|
| [`image-paste.md`](image-paste.md) | Alt+V image paste — BMP→PNG converter + keybinding |
| [`shift-enter.md`](shift-enter.md) | Shift+Enter newline in VSCode terminal and Windows Terminal |
| [`claude-notify.md`](claude-notify.md) | Windows balloon tip notification via PowerShell |
| [`settings.md`](settings.md) | Disable git attribution, skip trust dialog |

## Custom agents and skills

| Path | Contents |
|------|----------|
| [`agents/`](agents/) | `code-architect`, `code-simplifier` |
| [`skills/`](skills/) | `commit-push-pr`, `dedupe`, `frontend-design`, `oncall-triage` |

Copy to `~/.claude/agents/` and `~/.claude/skills/` respectively, or let Claude do it with **"set this up"**.
