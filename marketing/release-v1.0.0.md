# Claude Code WSL2 Setup v1.0.0

First stable release of my active Claude Code setup for WSL2 + Windows Terminal.

## Highlights

- Codex delegation through an isolated Claude subagent, so long implementation
  loops do not fill Claude's main conversation.
- Screenshot paste from the Windows clipboard into Claude Code or Codex as a WSL
  file path.
- Windows notifications for Claude Code and Codex completion/input events.
- LSP setup for real go-to-definition and reference lookup.
- Statusline with project, branch, context, 5-hour usage, and weekly usage.
- Secrets hygiene and Bash-output truncation hooks for safer, cleaner transcripts.

## Start here

```bash
git clone https://github.com/congmnguyen/claude-code-wsl2-setup.git
cd claude-code-wsl2-setup
claude
```

Then prompt:

```text
Set this up
```

Repo: https://github.com/congmnguyen/claude-code-wsl2-setup
