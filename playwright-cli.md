# Claude Code — Playwright CLI (token-efficient browser automation)

`playwright-cli` drives the same Playwright browser tools as the [Playwright MCP server](mcp-setup.md#playwright),
but as a **plain CLI** instead of an MCP server. For a coding agent it is usually the better
default — it costs far fewer context tokens.

## The problem with Playwright MCP

An MCP server has to load all of its **tool schemas** into the context window: every tool
name, parameter, type, and description. Playwright MCP exposes a lot of tools, and the page
`snapshot` (accessibility tree) it returns is verbose on top of that.

When a coding agent is working, the context window already holds the codebase, the test
files, and the reasoning trace — *plus* the browser state. The MCP schemas eat a large slice
of that budget on every turn, even when the agent only needs one or two browser actions.

A CLI is just a bash command. The agent already knows how to run bash; it only needs the
command *syntax*, which loads **once** from the skill file. After that it runs
`playwright-cli click e21`, `playwright-cli snapshot`, etc. as normal shell commands. Output
is compact too.

> Analogy: MCP is like calling an API with the full OpenAPI spec pasted into the prompt every
> time. CLI is like calling `curl` — the agent already knows the tool, it just needs the one
> line.

## Install

```bash
npm install -g @playwright/cli@latest
playwright-cli install --skills        # installs the SKILL.md (default: claude)
playwright-cli install-browser         # download browser binaries (once)
```

`--skills` writes the agent skill so Claude Code knows the command surface; `claude` is the
default target (`agents` is also available). No global install? Fall back to
`npx playwright-cli <command>`.

## What it can do

Same surface as the MCP server, driven from the shell:

```bash
playwright-cli open https://example.com   # open + navigate
playwright-cli snapshot                    # accessibility tree with element refs (e3, e5…)
playwright-cli click e15                    # act on a ref from the snapshot
playwright-cli fill e7 "user@example.com" --submit
playwright-cli eval "el => el.getAttribute('data-testid')" e5
playwright-cli console                      # console logs
playwright-cli requests                     # network requests
playwright-cli close
```

The workflow is **snapshot → act on refs**: `snapshot` returns elements tagged `e3`, `e5`, …
and every action targets one of those refs. `screenshot` exists but is rarely needed since the
snapshot is more compact and machine-readable. It also covers tracing, video recording,
storage state (cookies/localStorage), request mocking, and spec-driven test generation/healing
— run `playwright-cli --help` for the full list.

## CLI vs MCP — which to use

Keep **both** installed; they solve different problems and are not upgrade/replacement of each
other.

**Prefer the CLI when** the agent is *coding* (writing tests, building a feature) and the
browser is just one part of the workflow. Token savings dominate — schemas don't sit in
context, output is compact.

**Prefer [the MCP server](mcp-setup.md#playwright) when** the agent is doing *browser
automation as the main task*: persistent browser state with rich DOM introspection,
self-healing test loops that re-read page structure, or long-running autonomous workflows that
keep the browser context alive across many steps. The JSON-RPC protocol maintains that state
better than discrete CLI invocations.

## Troubleshooting

**`playwright-cli: command not found`**
- Confirm the global install: `npm ls -g @playwright/cli`. Otherwise use `npx playwright-cli`.

**No browser / "browser not installed"**
- Run `playwright-cli install-browser` once to download the binaries.
- On WSL2, headed (visible) mode needs a display server; use headless or set up an X server —
  same constraint as the MCP server.

**Agent doesn't know the commands**
- Re-run `playwright-cli install --skills` so the `SKILL.md` is present where Claude Code loads
  skills.
