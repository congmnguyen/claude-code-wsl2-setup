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
| `image-paste.md` | `~/.local/bin/clip2png` (BMP→PNG clipboard poller) + `~/.claude/keybindings.json` (Alt+V) + `SessionStart` hook only (no SessionEnd) |
| `shift-enter.md` | VSCode `/terminal-setup` + Windows Terminal `settings.json` action (`\u001b\r`) |
| `claude-notify.md` | `~/bin/claude-notify` (bash → PowerShell balloon tip) + `PermissionRequest` hook only — **WSL2 only** |
| `claude-notify-powershell.md` | `%USERPROFILE%\.claude\claude-hook-toast.ps1` + `PermissionRequest` hook only — **native Windows PowerShell only** |
| `statusline.md` | `~/.claude/statusline-command.sh` + `statusLine` in `~/.claude/settings.json` |
| `settings.md` | `~/.claude/settings.json` `attribution` field + `~/.claude.json` `hasTrustDialogAccepted` |
| `browser.md` | `BROWSER` env var in `~/.zshrc` pointing to Windows `.exe` |
| `mcp-setup.md` | DeepWiki (HTTP, user-scoped), Playwright (npx), Figma Desktop (localhost:3845) |
| `lsp-setup.md` | LSP binaries: typescript-language-server, pyright, gopls (Go 1.26+), rust-analyzer; PATH in `~/.zshrc`; install official LSP plugins; `enabledPlugins` in `settings.json`; optional `ENABLE_LSP_TOOL` workaround |
| `voice.md` | `pulseaudio-utils` + `libasound2-plugins`; `~/.asoundrc` routing ALSA default PCM to `pulse` plugin at WSLg socket; `PULSE_SERVER` in `~/.zshrc` |
| `tmux.md` | tmux auto-attach block appended to `~/.zshrc`; creates persistent `main` session + grouped session per terminal tab with `destroy-unattached on` |

## Key Technical Details

**clip2png polling**: WSLg does not support the wlroots data-control protocol, so `wl-paste --watch` cannot be used. The script polls every 1 second instead. The background subshell **must** redirect to `/dev/null 2>&1` before `&` — without it, the hook's stdout pipe never closes and Claude Code hangs forever.

**clip2png SessionEnd pitfall**: Do not add a `SessionEnd` hook to stop the poller. Claude Code fires `SessionStart`/`SessionEnd` for every subagent spawned by the Task tool. The subagent's `SessionEnd` would kill the poller mid-session for the main session.

**claude-notify async (WSL2)**: The `PermissionRequest` hook command must be wrapped as `bash -c '... &'` because the PowerShell script sleeps 6 s. Running it synchronously blocks Claude Code's UI for that duration.

**claude-notify async (Windows PowerShell)**: Uses the Windows Toast API (`Windows.UI.Notifications`) via [soulee-dev/claude-code-notify-powershell](https://github.com/soulee-dev/claude-code-notify-powershell). The script reads hook event JSON from stdin. No async wrapper needed — toast fires and exits immediately. Only the `PermissionRequest` hook is used — notifications fire only when Claude needs you to approve a tool. Script lives at `%USERPROFILE%\.claude\claude-hook-toast.ps1`; hook configured in `C:\Users\cong\.claude\settings.json`. Both variants skip the notification when Windows Terminal is the foreground window.

**clip2png re-serve logic**: When `image/png` disappears from the clipboard (WSLg clipboard sync can take back ownership) and no new content was copied, the script re-serves `/tmp/clip2png-last.png`. The detection condition is: no `image/png` AND no `text/` type AND the last PNG file exists.

**keybindings.json format**: Must be `{ "bindings": [...] }` (object with array), not a bare array — a bare array silently fails to load.

**settings.json attribution**: The correct field is `"attribution": { "commit": "", "pr": "" }`. The deprecated `includeCoAuthoredBy` key and non-existent `gitAttribution` key have no effect.

**statusline JSON parsing**: Claude Code pipes a JSON blob to the script stdin on every refresh. Four fields are extracted in a single `jq -r '@tsv'` call assigned via `IFS=$'\t' read`: working dir, context %, 5-hour usage %, 7-day usage %. The git branch is resolved with `git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD` using the working dir from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files. The `statusLine` setting takes `{ "type": "command", "command": "..." }` — the command must be a single string (no array form). Format: `cong | branch | [bar] % | 5h:X% | W:X%` — username hardcoded, branch omitted outside git repos, no model name, no reset timers.

## When Asked to "Set This Up"

Read all `*.md` files, then:
1. Install `wl-clipboard` and `imagemagick` if not present.
2. Create `~/.local/bin/clip2png` and `~/bin/claude-notify` with the exact script contents from the docs, then `chmod +x` both.
3. Merge the hooks (`SessionStart`, `PermissionRequest`) into `~/.claude/settings.json`. Do NOT add a `SessionEnd` hook for clip2png — subagents fire `SessionEnd` too, which would kill the poller mid-session.
4. Create/update `~/.claude/keybindings.json` with the Alt+V binding.
5. Set `attribution` in `~/.claude/settings.json`. Save `~/.claude/statusline-command.sh` from `statusline.md` and set `statusLine` in `~/.claude/settings.json`.
6. Copy `agents/*.md` → `~/.claude/agents/`, `skills/*/SKILL.md` → `~/.claude/skills/<name>/SKILL.md`, and `codex-skills/<name>/` → `~/.codex/skills/<name>/` when setting up Codex too.
7. Install `pulseaudio-utils` and `libasound2-plugins`, create `~/.asoundrc` with the pulse PCM config, and add `PULSE_SERVER` to `~/.zshrc` (see `voice.md`).
8. Remind the user to manually apply the Windows-side changes (Windows Terminal `settings.json`, `~/.zshrc` `BROWSER` export) since WSL cannot edit Windows files.
