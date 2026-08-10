# Claude Code — MCP Setup

MCP (Model Context Protocol) servers extend Claude Code with external tools. I do not
keep a global MCP server enabled by default. Figma Desktop remains available as an
optional, project-specific integration.

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

**Figma Desktop MCP not connecting**
- Confirm Figma Desktop is running and the MCP server option is enabled in Settings.
- The server only listens on `127.0.0.1:3845` — it won't work if Figma isn't open.
- Restart Figma Desktop after enabling the setting.
