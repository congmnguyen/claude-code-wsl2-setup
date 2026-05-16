# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is a collection of documentation files and scripts that fix Claude Code papercuts on WSL2 + Windows Terminal. There is no build system, test suite, or package manager — the "deliverables" are markdown docs (explaining problems and fixes), shell scripts, and Claude Code config files (agents, skills).

## Repository Structure

- **`*.md` at root** — Each file documents one fix: the problem, root cause, exact config or script to install, and troubleshooting steps. These are the primary artifacts.
- **`agents/`** — Custom Claude Code subagent definitions (YAML frontmatter + instructions). Installed to `~/.claude/agents/`.
- **`skills/`** — Custom Claude Code slash-command skills. Installed to `~/.claude/skills/`.
- **`codex-skills/`** — Codex-native skills adapted from the Claude skill set. Installed to `~/.codex/skills/`.

## The Fixes

| File | What it configures |
|------|-------------------|
| `image-paste.md` | `~/.local/bin/wsl-screenshot-cli` (Go daemon polling Windows clipboard) + `~/.claude/keybindings.json` (Alt+V) + `SessionStart` hook only (no SessionEnd) |
| `shift-enter.md` | VSCode `/terminal-setup` + Windows Terminal `settings.json` action (`\u001b\r`) |
| `claude-notify.md` | `~/bin/claude-notify` (bash → PowerShell balloon tip) + Claude `Stop` and `PermissionRequest` hooks, or Codex `notify` — **WSL2 only** — skips if Windows Terminal is foreground |
| `claude-notify-powershell.md` | `%USERPROFILE%\.claude\claude-hook-toast.ps1` + `PermissionRequest` hook only — **native Windows PowerShell only** |
| `statusline.md` | `~/.claude/statusline-command.sh` + `statusLine` in `~/.claude/settings.json` |
| `settings.md` | `~/.claude/settings.json` `attribution` field + `~/.claude.json` `hasTrustDialogAccepted` |
| `browser.md` | `BROWSER` env var in `~/.zshrc` pointing to Windows `.exe` |
| `mcp-setup.md` | DeepWiki (HTTP, user-scoped), Playwright (npx), Figma Desktop (localhost:3845) |
| `lsp-setup.md` | LSP binaries: typescript-language-server, pyright, gopls (Go 1.26+), rust-analyzer; PATH in `~/.zshrc`; install official LSP plugins; `enabledPlugins` in `settings.json`; optional `ENABLE_LSP_TOOL` workaround |
| `voice.md` | `pulseaudio-utils` + `libasound2-plugins`; `~/.asoundrc` routing ALSA default PCM to `pulse` plugin at WSLg socket; `PULSE_SERVER` in `~/.zshrc` |

## Key Technical Details

**wsl-screenshot-cli architecture**: `image-paste.md` uses [wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli). A Go daemon in WSL keeps a persistent `powershell.exe -STA` subprocess alive to access the Windows clipboard through .NET (`System.Windows.Forms.Clipboard`), side-stepping WSLg/Wayland clipboard limitations.

**wsl-screenshot-cli polling**: The daemon polls the Windows clipboard every 250 ms by default. When it detects a new screenshot, it receives PNG bytes from PowerShell, deduplicates by SHA256, and stores the file under `/tmp/.wsl-screenshot-cli/<hash>.png`.

**wsl-screenshot-cli clipboard formats**: After saving the screenshot, the daemon updates the Windows clipboard with three formats at once: `CF_UNICODETEXT` for WSL terminal paste (the WSL path string), `CF_BITMAP` for image apps like Paint, and `CF_HDROP` for paste-as-file in Explorer and file dialogs. The same screenshot therefore pastes as a path in Claude Code / Codex, but still behaves like an image or file in Windows apps.

**wsl-screenshot-cli SessionEnd pitfall**: Keep the repo docs aligned with `image-paste.md`: do not add a `SessionEnd` hook in Claude Code. Claude Code fires `SessionStart`/`SessionEnd` for every Task-tool subagent, so a subagent `SessionEnd` would stop the daemon mid-session for the main agent.

**claude-notify async (WSL2)**: For Claude Code, wrap the `Stop` hook command as `bash -c '... &'` because the PowerShell script stays alive while the balloon is visible. For Codex, use `notify = ["bash", "-lc", "~/bin/claude-notify \"$1\" &", "--"]` in `~/.codex/config.toml`; Codex passes the JSON notification payload as a single argument.

**claude-notify async (Windows PowerShell)**: Uses the Windows Toast API (`Windows.UI.Notifications`) via [soulee-dev/claude-code-notify-powershell](https://github.com/soulee-dev/claude-code-notify-powershell). The script reads hook event JSON from stdin. No async wrapper needed — toast fires and exits immediately. Only the `PermissionRequest` hook is used — notifications fire only when Claude needs you to approve a tool. Script lives at `%USERPROFILE%\.claude\claude-hook-toast.ps1`; hook configured in `C:\Users\cong\.claude\settings.json`. Both variants skip the notification when Windows Terminal is the foreground window.

**keybindings.json format**: Must be `{ "bindings": [...] }` (object with array), not a bare array — a bare array silently fails to load.

**settings.json attribution**: The correct field is `"attribution": { "commit": "", "pr": "" }`. The deprecated `includeCoAuthoredBy` key and non-existent `gitAttribution` key have no effect.

**statusline JSON parsing**: Claude Code pipes a JSON blob to the script stdin on every refresh. Four fields are extracted in a single `jq -r '@tsv'` call assigned via `IFS=$'\t' read`: working dir, context %, 5-hour usage %, 7-day usage %. The git branch is resolved with `git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD` using the working dir from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files. The `statusLine` setting takes `{ "type": "command", "command": "..." }` — the command must be a single string (no array form). Format: `cong | branch | [bar] % | 5h:X% | W:X%` — username hardcoded, branch omitted outside git repos, no model name, no reset timers.

## When Asked to "Set This Up"

Read all `*.md` files, then:
1. Install `wsl-screenshot-cli` with the install script from `image-paste.md`, and create `~/bin/claude-notify` with the exact script contents from `claude-notify.md`.
2. Merge into `~/.claude/settings.json`: the `SessionStart` hook for `wsl-screenshot-cli`, and the `Stop` + `PermissionRequest` hooks for `claude-notify`. Do NOT add a `SessionEnd` hook for `wsl-screenshot-cli` — subagents fire `SessionEnd` too, which would stop the daemon mid-session.
3. Create/update `~/.claude/keybindings.json` with the Alt+V binding.
4. Set `attribution` in `~/.claude/settings.json`. Save `~/.claude/statusline-command.sh` from `statusline.md` and set `statusLine` in `~/.claude/settings.json`.
5. Install the LSP plugins per `lsp-setup.md` and set `enabledPlugins` in `~/.claude/settings.json`. Install language-server binaries for whichever languages the user works in.
6. Copy `agents/*.md` → `~/.claude/agents/`, `skills/<name>/` → `~/.claude/skills/<name>/` (copy the entire directory — some skills include sibling files like `template.html`), and `codex-skills/<name>/` → `~/.codex/skills/<name>/` when setting up Codex too.
7. Install `pulseaudio-utils` and `libasound2-plugins`, create `~/.asoundrc` with the pulse PCM config, and add `PULSE_SERVER` to `~/.zshrc` (see `voice.md`).
8. Remind the user to manually apply the Windows-side changes (Windows Terminal `settings.json`, `~/.zshrc` `BROWSER` export, and — if they also run Claude Code natively on Windows — `claude-notify-powershell.md`) since WSL cannot edit Windows files.
