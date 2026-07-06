# Claude Code — MCP Setup

MCP (Model Context Protocol) servers extend Claude Code with external tools. My active
global MCP setup is intentionally small: **DeepWiki** only. Figma Desktop is useful for
specific design projects, but it is not a global default. For browser automation, use
[`playwright-cli.md`](playwright-cli.md) instead of Playwright MCP.

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

## Optional: Figma Desktop

Reads Figma design files directly from the Figma Desktop app running locally. Provides
design context (layout, styles, components, variables) for accurate design-to-code
implementation.

This is project-specific on my machine, not a global default.

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

**Figma Desktop MCP not connecting**
- Confirm Figma Desktop is running and the MCP server option is enabled in Settings.
- The server only listens on `127.0.0.1:3845` — it won't work if Figma isn't open.
- Restart Figma Desktop after enabling the setting.
