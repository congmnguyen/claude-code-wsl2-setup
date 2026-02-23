# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is a collection of documentation files and scripts that fix Claude Code papercuts on WSL2 + Windows Terminal. There is no build system, test suite, or package manager — the "deliverables" are markdown docs (explaining problems and fixes), shell scripts, and Claude Code config files (agents, skills).

## Repository Structure

- **`*.md` at root** — Each file documents one fix: the problem, root cause, exact config or script to install, and troubleshooting steps. These are the primary artifacts.
- **`agents/`** — Custom Claude Code subagent definitions (YAML frontmatter + instructions). Installed to `~/.claude/agents/`.
- **`skills/`** — Custom Claude Code slash-command skills. Installed to `~/.claude/skills/`.

## The Fixes

| File | What it configures |
|------|-------------------|
| `image-paste.md` | `~/.local/bin/clip2png` (BMP→PNG clipboard poller) + `~/.claude/keybindings.json` (Alt+V) + `SessionStart` hook only (no SessionEnd) |
| `shift-enter.md` | VSCode `/terminal-setup` + Windows Terminal `settings.json` action (`\u001b\r`) |
| `claude-notify.md` | `~/bin/claude-notify` (bash → PowerShell balloon tip) + `Notification`/`PermissionRequest` hooks — **WSL2 only** |
| `claude-notify-powershell.md` | `%USERPROFILE%\.claude\claude-hook-toast.ps1` + `Stop`/`Notification`/`PermissionRequest` hooks — **native Windows PowerShell only** |
| `settings.md` | `~/.claude/settings.json` `attribution` field + `~/.claude.json` `hasTrustDialogAccepted` |
| `browser.md` | `BROWSER` env var in `~/.zshrc` pointing to Windows `.exe` |

## Key Technical Details

**clip2png polling**: WSLg does not support the wlroots data-control protocol, so `wl-paste --watch` cannot be used. The script polls every 1 second instead. The background subshell **must** redirect to `/dev/null 2>&1` before `&` — without it, the hook's stdout pipe never closes and Claude Code hangs forever.

**clip2png SessionEnd pitfall**: Do not add a `SessionEnd` hook to stop the poller. Claude Code fires `SessionStart`/`SessionEnd` for every subagent spawned by the Task tool. The subagent's `SessionEnd` would kill the poller mid-session for the main session.

**claude-notify async (WSL2)**: The `Notification` hook command must be wrapped as `bash -c '... &'` because the PowerShell script sleeps 6 s. Running it synchronously blocks Claude Code's UI for that duration.

**claude-notify async (Windows PowerShell)**: Uses the Windows Toast API (`Windows.UI.Notifications`) via [soulee-dev/claude-code-notify-powershell](https://github.com/soulee-dev/claude-code-notify-powershell). The script reads hook event JSON from stdin. No async wrapper needed — toast fires and exits immediately. The key hook is `Stop` (fires when Claude finishes a response), not just `Notification`. Script lives at `%USERPROFILE%\.claude\claude-hook-toast.ps1`; hook configured in `C:\Users\cong\.claude\settings.json`. Both variants skip the notification when Windows Terminal is the foreground window.

**clip2png re-serve logic**: When `image/png` disappears from the clipboard (WSLg clipboard sync can take back ownership) and no new content was copied, the script re-serves `/tmp/clip2png-last.png`. The detection condition is: no `image/png` AND no `text/` type AND the last PNG file exists.

**keybindings.json format**: Must be `{ "bindings": [...] }` (object with array), not a bare array — a bare array silently fails to load.

**settings.json attribution**: The correct field is `"attribution": { "commit": "", "pr": "" }`. The deprecated `includeCoAuthoredBy` key and non-existent `gitAttribution` key have no effect.

## When Asked to "Set This Up"

Read all five `*.md` files, then:
1. Install `wl-clipboard` and `imagemagick` if not present.
2. Create `~/.local/bin/clip2png` and `~/bin/claude-notify` with the exact script contents from the docs, then `chmod +x` both.
3. Merge the hooks (`SessionStart`, `Notification`, `PermissionRequest`) into `~/.claude/settings.json`. Do NOT add a `SessionEnd` hook for clip2png — subagents fire `SessionEnd` too, which would kill the poller mid-session.
4. Create/update `~/.claude/keybindings.json` with the Alt+V binding.
5. Set `attribution` in `~/.claude/settings.json`.
6. Copy `agents/*.md` → `~/.claude/agents/` and `skills/*/SKILL.md` → `~/.claude/skills/<name>/SKILL.md`.
7. Remind the user to manually apply the Windows-side changes (Windows Terminal `settings.json`, `~/.zshrc` `BROWSER` export) since WSL cannot edit Windows files.
