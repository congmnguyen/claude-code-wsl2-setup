# Claude Code WSL2 Setup

Fixes for the most annoying Claude Code papercuts on WSL2 + Windows Terminal.

## There's a hidden setting that makes Claude Code ~600x faster at finding code

By default, Claude Code finds functions by grepping through your files as text. It doesn't understand your code — it just searches for strings. That's why "find the auth handler" takes 30–60 seconds and sometimes returns the wrong file.

There's a flag called `ENABLE_LSP_TOOL` that connects Claude to language servers — the same technology that powers VS Code's Ctrl+Click to jump to a definition.

After enabling it:

- `"add a stripe webhook to my payments page"` — Claude finds your existing payment logic in ~50ms instead of grepping through hundreds of files
- `"fix the auth bug on my dashboard"` — traces the actual call hierarchy instead of guessing which file handles auth
- After every edit, it auto-catches type errors immediately instead of you finding them 10 prompts later

It also saves tokens because Claude stops wasting context searching the wrong files.

2-minute setup. Works for TypeScript, Python, Go, Rust, and 7 other languages. **[→ LSP setup guide](lsp-setup.md)**

---

## What it fixes

- **Image paste** — copy a screenshot on Windows, press `Alt+V` in Claude Code and it just works. (Ctrl+V is intercepted by Windows Terminal; the Windows clipboard gives BMP not PNG — both fixed.) The last converted image is re-served automatically if clipboard ownership is lost mid-session, so you don't need to re-copy.
- **Shift+Enter newline** — insert a newline without submitting, in both VSCode integrated terminal and Windows Terminal.
- **"Needs your input" Windows notification** — get a notification when Claude finishes a task or needs permission approval. Skipped automatically when Windows Terminal is already the active window. WSL2 variant uses a balloon tip; native PowerShell variant uses a modern Windows toast.
- **Settings tweaks** — disable the `Co-authored-by: Claude` git attribution and pre-accept the project trust dialog.
- **Windows browser** — open links and OAuth flows in your existing Windows browser instead of Chromium inside WSL2.
- **Voice mode** — fix ALSA errors so `/voice` works, routing audio through WSLg's PulseAudio server.

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
| [`lsp-setup.md`](lsp-setup.md) | **LSP** — `ENABLE_LSP_TOOL` + language servers for TypeScript, Python, Go, Rust |
| [`image-paste.md`](image-paste.md) | Alt+V image paste — BMP→PNG converter + keybinding |
| [`shift-enter.md`](shift-enter.md) | Shift+Enter newline in VSCode terminal and Windows Terminal |
| [`claude-notify.md`](claude-notify.md) | Windows balloon tip notification — WSL2 variant (bash → PowerShell) |
| [`claude-notify-powershell.md`](claude-notify-powershell.md) + [`claude-hook-toast.ps1`](claude-hook-toast.ps1) | Windows toast notification — native PowerShell variant |
| [`settings.md`](settings.md) | Disable git attribution, skip trust dialog |
| [`browser.md`](browser.md) | Open links in your Windows browser via `BROWSER` env var |
| [`mcp-setup.md`](mcp-setup.md) | DeepWiki, Playwright, and Figma Desktop MCP servers |
| [`voice.md`](voice.md) | Voice mode — ALSA → PulseAudio → WSLg bridge, `~/.asoundrc` + `PULSE_SERVER` |

## Custom agents and skills

| Path | Contents |
|------|----------|
| [`agents/`](agents/) | `code-architect`, `code-simplifier` |
| [`skills/`](skills/) | `commit-push-pr`, `dedupe`, `frontend-design`, `oncall-triage`, `spec` |
| [`codex-skills/`](codex-skills/) | Codex-native versions of `code-review`, `commit-push-pr`, `dedupe`, `frontend-design`, `oncall-triage`, `spec` |

Copy [`agents/`](agents/) and [`skills/`](skills/) to `~/.claude/agents/` and `~/.claude/skills/` for Claude Code. Copy [`codex-skills/`](codex-skills/) to `~/.codex/skills/` for Codex.
