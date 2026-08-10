# CLAUDE.md

## Purpose

- This repository documents the active Claude Code setup on this WSL2 machine. It has no build system, test suite, or package manager; deliverables are Markdown docs, shell scripts, and config snippets.
- Treat the live files under `~/.claude/` as runtime truth and this repository as their documented, version-controlled counterpart. When changing an active setup component, inspect both and keep them synchronized.
- Root `*.md` files document setup components; `agents/`, `skills/`, and `hooks/` contain installable artifacts. Do not promote optional or legacy components in `README.md` unless the live machine uses them.
- Codex skills and setup live in the separate `congmnguyen/codex-wsl2-setup` repository. Do not restore a Codex backup tree here.

## Non-obvious constraints

- Run screenshot paste only through the systemd user service; do not add shell or Claude hooks that can race or stop the supervised `wsl-screenshot-cli` process. See `image-paste.md`.
- There are no `PreToolUse` or `PostToolUse` hooks in this setup, and none should be added. Every one tried here matched on patterns, and a pattern that is wrong in either direction is worse than nothing: a truncating hook destroyed the middle of failing test output, a credential-blocking hook rejected ordinary source files named `token_manager.py`, and a Ruff autofix hook silently deleted imports out of files Claude had just written. Prefer exact-match `permissions.deny` rules, which cannot misfire. See "Pruned notes" in `README.md`.
- `Notification` hooks are fine and still in use — they react to events instead of judging tool input, so they have nothing to get wrong. See `claude-notify.md`.
- Browser automation is no longer documented here; `playwright-cli.md` and the Playwright section of `mcp-setup.md` were removed. `mcp-setup.md` now covers only the project-scoped Figma Desktop MCP. Recover the old pages from git history rather than rewriting them.
- `~/.claude/keybindings.json` must be an object containing a `bindings` array; a bare array silently fails.
- In `~/.claude/settings.json`, merge settings instead of replacing the file. Use `attribution`, not deprecated or invented attribution keys. See `settings.md`.
- Normalize `assets/preview-*.png` to a 1220x788 `#0d1117` canvas and render previews at width 720 in `README.md`.

## Verification

- Shell changes: run `bash -n` and a focused behavior check.
- JSON/config changes: parse them and verify the live consumer loads them when possible.
- Documentation changes: verify referenced paths, commands, cross-links, and consistency with the live setup.
- If a check cannot run, report that explicitly instead of claiming the change works.

## Setup requests

- Read `README.md`, then only the relevant active component docs. Install active components; leave optional or legacy components alone unless requested.
- Preserve existing user settings while merging hooks, permissions, plugins, and statusline configuration.
- Call out Windows-side steps that WSL cannot safely apply, including Windows Terminal settings and SharpKeys remapping.
