# Launch Kit

Repo: https://github.com/congmnguyen/claude-code-wsl2-setup

Current angle: Claude Code on WSL2, but actually usable daily.

Primary hook: delegate long implementation loops to Codex so Claude keeps the main
architecture and product context clean.

## Launch post

```text
I open-sourced my Claude Code setup for WSL2 + Windows Terminal.

It fixes the annoying daily stuff:

- paste Windows screenshots into Claude/Codex as WSL paths
- get Windows notifications when Claude needs input
- use LSP navigation instead of broad file search
- block credential-file reads before secrets hit the transcript
- show context/usage in the statusline
- delegate implementation work to Codex without filling Claude's main context

Repo:
https://github.com/congmnguyen/claude-code-wsl2-setup
```

## Technical thread

```text
Claude Code is great at orchestration, but long implementation loops burn context.

My WSL2 setup uses a Claude subagent to call Codex in an isolated loop:

1. Claude keeps architecture/product context
2. Codex does read/edit/test
3. Claude receives only a compact summary
4. Main context stays clean

The real run in the README had two Codex delegates handling tens of thousands of
worker tokens in parallel while the main Claude session stayed at 8% context.

Full setup:
https://github.com/congmnguyen/claude-code-wsl2-setup
```

## Hacker News

Title:

```text
Show HN: My Claude Code setup for WSL2 and Windows Terminal
```

Text:

```text
I put my active Claude Code setup for WSL2 in a repo.

The main pieces are Codex delegation for context isolation, screenshot paste from
the Windows clipboard into WSL paths, Windows notifications, LSP navigation, a
statusline, and hooks for secrets/context hygiene.

The Codex delegation part is the most opinionated piece: Claude stays focused on
planning/review while Codex handles long read/edit/test loops through an isolated
subagent.
```

## Reddit

Suggested communities: `r/ClaudeAI`, `r/bashonubuntuonwindows`, `r/commandline`.
Check each community's self-promotion rules before posting.

```text
I documented my active Claude Code setup for WSL2 + Windows Terminal:

https://github.com/congmnguyen/claude-code-wsl2-setup

The pieces I use most:

- Windows screenshot clipboard -> pasted WSL file path
- Windows notification when Claude needs input
- statusline with context/usage
- LSP setup
- secrets hygiene hook
- Codex delegate so long implementation loops do not fill Claude's main context

The repo is not a general dotfiles dump; it only tracks the Claude Code pieces I
actually use on WSL2.
```

## Demo checklist

Record a 30-45 second clip:

1. Open Claude Code in Windows Terminal on WSL2.
2. Show the custom statusline.
3. Ask Claude to delegate a small implementation task with `codex-delegate`.
4. Show Codex doing the read/edit/test loop.
5. Return to Claude and show the compact delegate summary.
6. End on the README hero image and repo URL.

Caption:

```text
Claude orchestrates. Codex implements. Main context stays clean.

My WSL2 setup:
https://github.com/congmnguyen/claude-code-wsl2-setup
```

## Comment reply

Use only when someone is already asking about Claude Code on WSL2, Windows
Terminal, screenshots, notifications, hooks, or context usage.

```text
I hit the same issue on WSL2. I documented my working setup here:
https://github.com/congmnguyen/claude-code-wsl2-setup

The relevant part is <file>, especially <specific fix>.
```

## Awesome-list PR

Highest-priority targets found with GitHub search:

- https://github.com/hesreallyhim/awesome-claude-code - broad Claude Code ecosystem list.
- https://github.com/sirredbeard/awesome-wsl - WSL-specific list; pitch the Windows/WSL bridge features.
- https://github.com/ccplugins/awesome-claude-code-plugins - Claude Code plugins/hooks list; pitch the hooks, agents, and skills.
- https://github.com/rohitg00/awesome-claude-code-toolkit - toolkit-style Claude Code list.
- https://github.com/Transcenda/awesome-agentic-coding - smaller agentic-coding list; pitch Codex delegation.

Submission status:

- https://github.com/sirredbeard/awesome-wsl/pull/114 - opened PR to refresh the existing stale entry.
- https://github.com/hesreallyhim/awesome-claude-code - already lists this repo, but issue creation is restricted to collaborators; cannot update by CLI.

Title:

```text
Add Claude Code WSL2 setup
```

Description:

```text
Adds a practical Claude Code setup for WSL2 + Windows Terminal, covering Codex
delegation, screenshot paste, Windows notifications, LSP setup, statusline, and
secrets/context hygiene hooks.
```

One-line listing:

```text
- [Claude Code WSL2 Setup](https://github.com/congmnguyen/claude-code-wsl2-setup) - Practical Claude Code setup for WSL2 + Windows Terminal with Codex delegation, screenshot paste, Windows notifications, LSP, statusline, and safety/context hooks.
```
