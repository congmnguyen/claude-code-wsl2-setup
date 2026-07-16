# CLAUDE.md

## Purpose

- This repository documents the active Claude Code setup on this WSL2 machine. It has no build system, test suite, or package manager; deliverables are Markdown docs, shell scripts, and config snippets.
- Treat the live files under `~/.claude/` as runtime truth and this repository as their documented, version-controlled counterpart. When changing an active setup component, inspect both and keep them synchronized.
- Root `*.md` files document setup components; `agents/`, `skills/`, and `hooks/` contain installable artifacts. Do not promote optional or legacy components in `README.md` unless the live machine uses them.
- Codex skills and setup live in the separate `congmnguyen/codex-wsl2-setup` repository. Do not restore a Codex backup tree here.

## Non-obvious constraints

- Run screenshot paste only through the systemd user service; do not add shell or Claude hooks that can race or stop the supervised `wsl-screenshot-cli` process. See `image-paste.md`.
- `hooks/block-secret-reads.sh` and `hooks/truncate-bash-output.sh` mirror their live copies. Verify hook changes with synthetic JSON payloads, not file presence alone. The Bash post-tool hook must preserve the full `tool_response` object when replacing `.stdout`. See `secrets-hygiene-hook.md` and `truncate-bash-output.md`.
- Keep `playwright-cli.md` and the Playwright section of `mcp-setup.md` separate and cross-linked: CLI is the coding default; MCP is for persistent-state or long-running browser workflows.
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
