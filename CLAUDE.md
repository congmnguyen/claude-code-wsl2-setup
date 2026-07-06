# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo documents the active Claude Code setup used on this WSL2 machine. There is no build system, test suite, or package manager — the "deliverables" are markdown docs, shell scripts, and Claude Code config files that mirror the live local setup.

## Repository Structure

- **`*.md` at root** — Active setup docs plus a small number of optional/legacy notes. Do not promote optional notes in README unless the live local machine uses them.
- **`agents/`** — Custom Claude Code subagent definitions (YAML frontmatter + instructions). Installed to `~/.claude/agents/`.
- **`skills/`** — Custom Claude Code slash-command skills. Installed to `~/.claude/skills/`.
- **`hooks/`** — Claude Code hook scripts. Installed to `~/.claude/hooks/`.

Codex skills are maintained in the separate `congmnguyen/codex-skills` repo; do not add
that backup tree back here.

## The Fixes

| File | What it configures |
|------|-------------------|
| `image-paste.md` | `~/.local/bin/wsl-screenshot-cli` (Go daemon polling Windows clipboard) + `~/.claude/keybindings.json` (Alt+V) + `SessionStart` hook only (no SessionEnd) |
| `shift-enter.md` | VSCode `/terminal-setup` + Windows Terminal `settings.json` action (`\u001b\r`) |
| `claude-notify.md` | `~/bin/claude-notify` (bash → PowerShell balloon tip) + Claude `Notification` hooks (`idle_prompt`, `permission_prompt`, `agent_completed`, `agent_needs_input`) — **WSL2 only** — skips if Windows Terminal is foreground |
| `codex-notify.md` | Reuses `~/bin/claude-notify` via Codex top-level `notify` key in `~/.codex/config.toml`; `jq` pulls `last-assistant-message` into the balloon — **WSL2 only** |
| `statusline.md` | `~/.claude/statusline-command.sh` + `statusLine` in `~/.claude/settings.json` |
| `secrets-hygiene-hook.md` | `~/.claude/hooks/block-secret-reads.sh` + `PreToolUse` hook for `Read|Grep|Bash`; blocks credential-file reads before transcript exposure |
| `truncate-bash-output.md` | `~/.claude/hooks/truncate-bash-output.sh` + `PostToolUse` hook for `Bash`; truncates >200-line / >30k-char output to head+tail with an omission marker |
| `settings.md` | `~/.claude/settings.json` `attribution` field + `~/.claude.json` `hasTrustDialogAccepted` |
| `browser.md` | `BROWSER` env var in `~/.zshrc` pointing to Windows `.exe` |
| `mcp-setup.md` | DeepWiki (HTTP, user-scoped); Figma Desktop is project-specific; Playwright MCP is not the active default |
| `playwright-cli.md` | `@playwright/cli` global install + `install --skills`; CLI alternative to Playwright MCP, token-efficient, preferred for coding agents |
| `lsp-setup.md` | LSP binaries: typescript-language-server, pyright, gopls (Go 1.26+), rust-analyzer; PATH in `~/.zshrc`; install official LSP plugins; `enabledPlugins` in `settings.json`; optional `ENABLE_LSP_TOOL` workaround |
| `capslock-esc.md` | SharpKeys registry remap: CapsLock → Escape, system-wide, Windows-side only — no WSL config needed |

## Key Technical Details

**wsl-screenshot-cli architecture**: `image-paste.md` uses [wsl-screenshot-cli](https://github.com/Nailuu/wsl-screenshot-cli). A Go daemon in WSL keeps a persistent `powershell.exe -STA` subprocess alive to access the Windows clipboard through .NET (`System.Windows.Forms.Clipboard`), side-stepping WSLg/Wayland clipboard limitations.

**wsl-screenshot-cli polling**: The daemon polls the Windows clipboard every 250 ms by default. When it detects a new screenshot, it receives PNG bytes from PowerShell, deduplicates by SHA256, and stores the file under `/tmp/.wsl-screenshot-cli/<hash>.png`.

**wsl-screenshot-cli clipboard formats**: After saving the screenshot, the daemon updates the Windows clipboard with three formats at once: `CF_UNICODETEXT` for WSL terminal paste (the WSL path string), `CF_BITMAP` for image apps like Paint, and `CF_HDROP` for paste-as-file in Explorer and file dialogs. The same screenshot therefore pastes as a path in Claude Code / Codex, but still behaves like an image or file in Windows apps.

**wsl-screenshot-cli SessionEnd pitfall**: Keep the repo docs aligned with `image-paste.md`: do not add a `SessionEnd` hook in Claude Code. Claude Code fires `SessionStart`/`SessionEnd` for every Task-tool subagent, so a subagent `SessionEnd` would stop the daemon mid-session for the main agent.

**claude-notify async (WSL2)**: For Claude Code, use the `Notification` hook with narrow matchers (`idle_prompt`, `permission_prompt`, `agent_completed`, `agent_needs_input`) and wrap each command as `bash -c '... &'` because the PowerShell script stays alive while the balloon is visible. `agent_completed`/`agent_needs_input` require Claude Code v2.1.198+ and only fire while agent view is open. The Codex variant lives in `codex-notify.md` (reuses the same script via the top-level `notify` key) — keep the two docs cross-linked. The Codex trap: `[tui].notifications` is in-terminal only and runs no external program; the balloon needs the separate top-level `notify` key, which passes the `agent-turn-complete` JSON as the final arg (`$1`; `"--"` is `$0`) so `jq` can pull `last-assistant-message`. Requires `jq`.

**Playwright CLI vs MCP**: `playwright-cli.md` and the Playwright section of `mcp-setup.md` are intentionally kept as two docs, not merged — they're cross-linked. The CLI is the default for coding agents (no tool schemas in context → far fewer tokens); the MCP server stays for persistent-state / self-healing / long-running browser-only workflows. When editing one, keep the cross-link and the CLI-vs-MCP guidance in the other consistent.

**keybindings.json format**: Must be `{ "bindings": [...] }` (object with array), not a bare array — a bare array silently fails to load.

**settings.json attribution**: The correct field is `"attribution": { "commit": "", "pr": "" }`. The deprecated `includeCoAuthoredBy` key and non-existent `gitAttribution` key have no effect.

**statusline JSON parsing**: Claude Code pipes a JSON blob to the script stdin on every refresh. Four fields are extracted in a single `jq -r '@tsv'` call assigned via `IFS=$'\t' read`: working dir, context %, 5-hour usage %, 7-day usage %. The git branch is resolved with `git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD` using the working dir from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files. The `statusLine` setting takes `{ "type": "command", "command": "..." }` — the command must be a single string (no array form). Format: `cong | branch | [bar] % | 5h:X% | W:X%` — username hardcoded, branch omitted outside git repos, no model name, no reset timers.

**secrets-hygiene PreToolUse hook**: `hooks/block-secret-reads.sh` is copied unchanged from the live `~/.claude/hooks/block-secret-reads.sh`. It exits `2` to block `Read`, `Grep`, or Bash content-printing commands aimed at credential-looking paths (`~/.ssh/*`, `.env`, `.aws/credentials`, kube/gcloud/docker configs, `.netrc`, `.npmrc`, private-key filenames, and generic `credential|secret|token`). It is pattern-based only: env dumps, direct variable expansion, and secrets already present in command output/logs still require a short `CLAUDE.md` prompt rule and manual rotation if leaked.

**truncate-bash-output PostToolUse hook**: `hooks/truncate-bash-output.sh` is copied unchanged from the live `~/.claude/hooks/truncate-bash-output.sh`. Schema trap: `updatedToolOutput` must match the tool's output schema — for Bash that is the full `tool_response` object, so the script replaces `.stdout` in place with jq rather than emitting a bare string (a bare string is silently ignored and truncation stops working). Requires `jq`.

## When Asked to "Set This Up"

Read `README.md`, then install the active setup docs first. Optional/legacy docs are not part of the default setup unless the user asks for them.

1. Install `wsl-screenshot-cli` with the install script from `image-paste.md`, and create `~/bin/claude-notify` with the exact script contents from `claude-notify.md`.
2. Merge into `~/.claude/settings.json`: the `SessionStart` hook for `wsl-screenshot-cli`, and the `Notification` hook entries from `claude-notify.md`. Do NOT add a `SessionEnd` hook for `wsl-screenshot-cli` — subagents fire `SessionEnd` too, which would stop the daemon mid-session.
3. Create/update `~/.claude/keybindings.json` with the Alt+V binding.
4. Set `attribution` in `~/.claude/settings.json`. Save `~/.claude/statusline-command.sh` from `statusline.md` and set `statusLine` in `~/.claude/settings.json`.
5. Install the LSP plugins per `lsp-setup.md` and set `enabledPlugins` in `~/.claude/settings.json`. Install language-server binaries for whichever languages the user works in.
6. Copy active agent/skill files only: `agents/code-architect.md`, `agents/codex-delegate.md`, `skills/codex-delegate/`, `skills/commit-push-pr/`, `skills/deep-teach/`, `skills/pytorch-training/`, `hooks/*.sh`, and `scripts/codex-run.sh`.
7. Merge the `secrets-hygiene-hook.md` `PreToolUse` hook and the `truncate-bash-output.md` `PostToolUse` hook into `~/.claude/settings.json`.
8. Remind the user to manually apply the Windows-side changes (Windows Terminal `settings.json`, `~/.zshrc` `BROWSER` export, and SharpKeys CapsLock→Escape remap from `capslock-esc.md`) since WSL cannot edit every Windows-side setting safely.
