# Claude Code — Useful MCP Servers

MCP (Model Context Protocol) servers extend Claude Code with external capabilities. These
three cover deep code research, browser automation, and Figma design-to-code workflows.

---

## DeepWiki

Answers questions about any public GitHub repository by reading its wiki and indexed
documentation. Useful for understanding how a library works internally before using or
adapting it.

### Install

```bash
claude mcp add -s user -t http deepwiki https://mcp.deepwiki.com/mcp
```

`-s user` installs it globally (not just for this project). `-t http` uses the hosted
HTTP transport — no local process needed.

### What it can do

- Summarise a repo's architecture and key modules
- Answer "how does X work in library Y" questions with source-level detail
- Walk through implementation of specific features (e.g. "how does torchao implement fp8 training?")

### Example prompt

> Use DeepWiki to understand how `torchao` implements fp8 training, then implement
> `fp8.py` that has the same API but is fully self-contained.

---

## Playwright

> **For a coding agent, prefer [`playwright-cli`](playwright-cli.md)** — it drives the same
> tools without loading MCP schemas into context, so it costs far fewer tokens. Use this MCP
> server only when you need persistent browser state, self-healing test loops, or long-running
> autonomous browser workflows.

Browser automation: navigate pages, click, fill forms, take screenshots, inspect network
requests, and run arbitrary JavaScript. Useful for testing web UIs, scraping, and
debugging front-end behaviour.

### Install

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

Runs via `npx` — no global install required. Requires Node.js on the machine.

### What it can do

- Navigate to URLs and take screenshots
- Click buttons, fill forms, select options
- Inspect console logs and network requests
- Run JavaScript in the page context
- Test multi-step UI flows interactively

### Example prompt

> Open my local dev server at localhost:3000, navigate to the login page, fill in the
> test credentials, and screenshot the dashboard.

---

## Figma Desktop

Reads Figma design files directly from the Figma Desktop app running locally. Provides
design context (layout, styles, components, variables) for accurate design-to-code
implementation.

### Prerequisites

- Figma Desktop app must be installed and running
- Enable the local MCP server: **Figma Desktop → Settings → Developer → Enable MCP**

### Install

```bash
claude mcp add --transport http figma-desktop http://127.0.0.1:3845/mcp
```

Connects to the MCP server embedded in Figma Desktop at `localhost:3845`.

### What it can do

- Read component structure, layout, spacing, and colours from any open Figma file
- Extract design tokens and variable definitions
- Generate code matching a selected frame or component
- Map Figma components to codebase components (Code Connect)

### Example prompt

> Implement the `ProfileCard` component from this Figma URL to match the design exactly.

---

## Troubleshooting

**DeepWiki returns nothing for a repo**
- Only indexes public GitHub repos. Private repos are not supported.
- Try `ask_question` with a more specific question rather than a broad summary request.

**Playwright can't find a browser**
- Run `npx playwright install` once to download browser binaries.
- On WSL2, headed (visible) browser mode may not work without a display server; use
  headless mode or set up an X server.

**Figma Desktop MCP not connecting**
- Confirm Figma Desktop is running and the MCP server option is enabled in Settings.
- The server only listens on `127.0.0.1:3845` — it won't work if Figma isn't open.
- Restart Figma Desktop after enabling the setting.
