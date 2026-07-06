---
name: drawio
description: Create native editable draw.io diagrams as .drawio files and optionally export them to PNG, SVG, PDF, JPG, or browser URLs. Use when Codex needs to create, generate, draw, or design a diagram, flowchart, architecture diagram, ER diagram, sequence diagram, class diagram, network diagram, mockup, wireframe, UI sketch, or work with draw.io, drawio, drawoi, .drawio files, or diagram export.
---

# Draw.io Diagram

## Overview

Generate diagrams as native mxGraphModel XML in `.drawio` files. Export only when requested, and preserve editability for PNG, SVG, and PDF exports by embedding the diagram XML.

## Workflow

1. Infer the requested diagram type and output format from the user request.
2. Generate well-formed mxGraphModel XML directly; do not use Mermaid or CSV as an intermediate.
3. Write a descriptive lowercase hyphenated `.drawio` file in the current working directory.
4. If the user requested `png`, `svg`, or `pdf`, export with draw.io CLI and `--embed-diagram`; delete the intermediate `.drawio` file only after successful export.
5. If the user requested `url`, generate an `app.diagrams.net` URL from the `.drawio` XML and keep the local `.drawio` file.
6. Open the result when feasible. If opening fails, print the absolute path or URL.

## Output Formats

- No format: keep `name.drawio`.
- `png`, `svg`, `pdf`: export to `name.drawio.png`, `name.drawio.svg`, or `name.drawio.pdf` with embedded XML.
- `jpg`: export to `name.drawio.jpg`, but note that JPG cannot embed editable XML.
- `url`: open a browser URL and keep `name.drawio` as the persistent editable copy.

## XML Requirements

Every `.drawio` file must use this root structure:

```xml
<mxGraphModel adaptiveColors="auto">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
  </root>
</mxGraphModel>
```

- Use `parent="1"` for normal diagram cells.
- Use unique `id` values for all `mxCell` elements.
- Escape XML attribute values: `&amp;`, `&lt;`, `&gt;`, `&quot;`.
- Never include XML comments in generated diagram XML.
- Edge cells must include a child geometry such as `<mxGeometry relative="1" as="geometry"/>`; self-closing edge cells often render incorrectly.

## Export With draw.io CLI

Locate the CLI by environment:

- WSL2 default install: `` `/mnt/c/Program Files/draw.io/draw.io.exe` ``
- WSL2 per-user install: `` `/mnt/c/Users/$WIN_USER/AppData/Local/Programs/draw.io/draw.io.exe` ``
- macOS: `/Applications/draw.io.app/Contents/MacOS/draw.io`
- Linux: `drawio` on `PATH`

Export command:

```bash
drawio -x -f <format> -e -b 10 -o <output> <input.drawio>
```

Use `-e` only for PNG, SVG, and PDF. If the CLI is unavailable, keep the `.drawio` file and tell the user they can install draw.io Desktop, use `url` mode, or open the `.drawio` file manually.

## Browser URL Mode

Generate a URL with Node.js built-ins:

```bash
URL=$(node -e '
const fs = require("fs");
const zlib = require("zlib");
const xml = fs.readFileSync(process.argv[1], "utf8");
const compressed = zlib.deflateRawSync(encodeURIComponent(xml)).toString("base64");
const payload = encodeURIComponent(JSON.stringify({ type: "xml", compressed: true, data: compressed }));
console.log("https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=" + payload);
' DIAGRAM.drawio)
```

On WSL2 or Windows, do not pass the URL directly to `cmd.exe /c start`; `&` and the `#create=` fragment can be stripped. Write a temporary `.url` file instead:

```bash
TMPFILE=$(mktemp --suffix=.url)
printf '[InternetShortcut]\r\nURL=%s\r\n' "$URL" > "$TMPFILE"
cmd.exe /c start "" "$(wslpath -w "$TMPFILE")"
```

For macOS/Linux, use `open "$URL"` or `xdg-open "$URL"`.

## Open Local Files

Use the platform opener:

- WSL2: `cmd.exe /c start "" "$(wslpath -w <file>)"`
- macOS: `open <file>`
- Linux: `xdg-open <file>`

## Troubleshooting

- Blank diagram: verify the `id="0"` and `id="1"` root cells exist.
- Empty or corrupt export: validate XML well-formedness and remove comments.
- Browser URL opens an empty diagram on WSL2: use the `.url` shortcut workaround.
- URL is too long: keep the `.drawio` file and open it locally instead.
