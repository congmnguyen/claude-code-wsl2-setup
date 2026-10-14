# Repository instructions

## Purpose

- This repository preserves the maintainer's previous Claude Code setup for WSL2 + Windows Terminal. The maintainer now uses Ubuntu + Ghostty and no longer tests WSL2 daily. It has no build system or package manager; lightweight checks live in `tests/` and `scripts/`; deliverables are Markdown docs, shell scripts, and config snippets.
- The current machine's `~/.claude/` is not the source of truth for the preserved WSL2 setup. Do not synchronize it with this repository or install WSL2 components on Ubuntu as part of documentation maintenance.
- Root `*.md` files document setup components; `agents/` and `skills/` contain optional installable artifacts. Keep optional and legacy components clearly labeled. Do not present the repository as a tested Ubuntu setup.
- The separate `codex-wsl2-setup` repository no longer exists. The Codex notification and terminal-title notes stay here because they reuse this repository's scripts; Codex delegation lives only in `archive/`. Do not restore a Codex backup tree here.

## Non-obvious constraints

- Run screenshot paste only through the systemd user service; do not add shell or Claude hooks that can race or stop the supervised `wsl-screenshot-cli` process. The upstream installer offers to add exactly those, so the guide installs a pinned release instead. See `image-paste.md`.
- `bin/claude-notify` passes text to PowerShell base64-encoded. Never interpolate text into a PowerShell string literal: PowerShell also ends single-quoted strings at `‘ ’ ‚ ‛`, and Codex replies are untrusted model output.
- There are no `PreToolUse` or `PostToolUse` hooks in this setup, and none should be added. Every one tried here matched on patterns, and a pattern that is wrong in either direction is worse than nothing: a truncating hook destroyed the middle of failing test output, a credential-blocking hook rejected ordinary source files named `token_manager.py`, and a Ruff autofix hook silently deleted imports out of files Claude had just written. Prefer exact-match `permissions.deny` rules, which cannot misfire. See `pruned-notes.md`.
- `Notification` hooks remain part of the documented WSL2 setup. See `claude-notify.md`.
- Browser automation is no longer documented here; `playwright-cli.md` and the Playwright section of `mcp-setup.md` were removed. `mcp-setup.md` now covers only the project-scoped Figma Desktop MCP. Recover the old pages from git history rather than rewriting them.
- `~/.claude/keybindings.json` must be an object containing a `bindings` array; a bare array silently fails.
- In `~/.claude/settings.json`, merge settings instead of replacing the file. Use `attribution`, not deprecated or invented attribution keys. See `settings.md`.
- Normalize `assets/preview-*.png` to a 1220x788 `#0d1117` canvas and render previews at width 720 in `README.md`. `tests/test_docs.py` enforces both.
- Keep `scripts/doctor.sh` read-only: no file edits, service changes, or notifications. Its output goes into public issues, so keep home paths and Windows user names abbreviated.

## Verification

- Run `bash scripts/check.sh` for shell syntax, shellcheck, local Markdown links, documentation snippets, and focused behavior tests. These checks do not validate Windows GUI behavior.
- Checks that need `tmux`, `zsh`, `pwsh`, or `shellcheck` skip when the tool is missing; CI sets `CHECKS_REQUIRE_ALL=1`, which turns those skips into failures. Report which checks were skipped locally.
- Shell changes: also run a focused behavior check for any behavior not covered by the suite.
- JSON/config changes: parse them and verify the live consumer loads them when possible.
- Documentation changes: verify referenced paths, commands, cross-links, and consistency with the documented WSL2 scope. Do not claim WSL2 runtime verification from an Ubuntu-only check; record real WSL2 runs in `maintenance.md` under "WSL2 verification status".
- If a check cannot run, report that explicitly instead of claiming the change works.

## Setup requests

- Read `README.md`, then only the relevant component docs. Confirm the target environment is WSL2 before applying WSL2-specific configuration. Install requested components; leave optional or legacy components alone unless requested.
- Preserve existing user settings while merging hooks, permissions, plugins, and statusline configuration.
- Call out Windows-side steps that WSL cannot safely apply, including Windows Terminal settings and SharpKeys remapping.
