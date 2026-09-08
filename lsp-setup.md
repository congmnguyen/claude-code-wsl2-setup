# Claude Code — LSP Setup

Claude Code uses Language Server Protocol (LSP) to navigate code semantically — finding
definitions, references, and types — instead of falling back to text search. This gives
Claude more accurate context when reading and editing code.

For each language you use, you need:

1. The language server binaries on your PATH (see sections below)
2. The official LSP plugins installed in Claude Code
3. The installed plugins enabled in `~/.claude/settings.json`

---

## Install the official plugins

Inside Claude Code, run `/plugin` and install these official plugins:

- `pyright-lsp`
- `typescript-lsp`
- `gopls-lsp`
- `rust-analyzer-lsp`

Install only the plugins for languages you use. If already installed, enable them
in settings. The example below shows all four; merge only your selected entries.

---

## Enable the installed plugins

Merge these keys into your existing `~/.claude/settings.json` file. Do not replace the
whole file if you already have hooks, attribution, or other settings:

```jsonc
{
  "enabledPlugins": {
    "pyright-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "gopls-lsp@claude-plugins-official": true,
    "rust-analyzer-lsp@claude-plugins-official": true
  }
}
```

If your current Claude Code build still does not expose the `LSP` tool after the plugins
are installed and enabled, try this workaround by merging it into the same settings file:

```jsonc
{
  "env": {
    "ENABLE_LSP_TOOL": "1"
  }
}
```

`ENABLE_LSP_TOOL` is not officially documented (discovered via GitHub Issue #15619). Use
it as a version-specific workaround, not as the baseline requirement.

---

## TypeScript / JavaScript

```bash
npm install -g typescript typescript-language-server
```

Uses nvm? The binary lands in the active Node version's bin — no PATH changes needed.

---

## Python — pyright

Pyright is Microsoft's Python type checker. With Node.js available (for example
through nvm), install its npm package:

```bash
npm install -g pyright
```

This follows [Pyright's installation guide](https://github.com/microsoft/pyright/blob/main/docs/installation.md)
and avoids changing Ubuntu's system Python packages. With nvm, the executable is
in the active Node version's bin directory. The LSP plugin uses `pyright-langserver`;
`pyright` is the companion command-line checker.

---

## Go — gopls

Check the Go toolchain you already have:

```bash
go version
```

If you need to install or update Go, follow the [official installation guide](https://go.dev/doc/install)
for your architecture. Distro package versions vary; do not unpack a new release
on top of an existing Go tree. Check the [gopls requirements](https://go.dev/gopls/)
when choosing a toolchain.

```bash
go install golang.org/x/tools/gopls@latest
```

The executable goes to `go env GOBIN` when that is set, or the `bin` directory
under `go env GOPATH` otherwise (normally `~/go/bin`). Add that directory to PATH.

---

## Rust — rust-analyzer

If Rust is not installed, install it with rustup:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Then load the Rust environment and explicitly install the language server:

```bash
. "$HOME/.cargo/env"
rustup component add rust-analyzer
```

The executable is available through `~/.cargo/bin/rust-analyzer`. This is the
[rust-analyzer installation procedure](https://rust-analyzer.github.io/book/rust_analyzer_binary.html).

---

## PATH — add to `~/.bashrc`

```bash
# LSP tooling paths
export PATH="$HOME/go/bin:$HOME/.cargo/bin:$PATH"
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
```

Keep only the paths for tools you installed. If you set a custom `GOBIN` or
`GOPATH`, use its actual bin directory. The file check allows shells without a
Rust installation to load normally.

---

## Verify

```bash
source ~/.bashrc
command -v typescript-language-server
command -v pyright-langserver
command -v gopls
command -v rust-analyzer

# Run for the tools you installed:
typescript-language-server --version
pyright --version
gopls version
rust-analyzer --version
```

These commands target Ubuntu's default `bash`; if you use `zsh`, use `~/.zshrc`
instead.

Then restart Claude Code, run `/plugin`, and confirm the plugins you selected are
installed and enabled. In a project using one of those languages, ask Claude to
find a symbol definition and confirm the LSP tool is used. If the `LSP` tool is
still missing, try the version-specific `ENABLE_LSP_TOOL` workaround above and
restart Claude Code again.

---

## Troubleshooting

**gopls: command not found**
- Check `go env GOBIN GOPATH` and put the corresponding bin directory on PATH.
- Check `go version` against the linked gopls requirements.

**An old pip-based install fails with "externally-managed-environment"**
- Use the npm installation above; it does not modify system Python.
- Check `command -v pyright-langserver` to ensure the plugin finds the intended copy.

**rust-analyzer: command not found after rustup**
- Run `rustup component add rust-analyzer` to install it explicitly.
- Ensure `~/.cargo/bin` is in PATH and restart your shell.

**typescript-language-server: command not found**
- Confirm Node is active: `node --version`.
- With nvm, run `nvm use` or set a default: `nvm alias default node`.

## Remove

Use `/plugin` to disable or uninstall only the LSP plugins you added. Remove their
entries from `enabledPlugins` and the `ENABLE_LSP_TOOL` workaround if you added it.
Keep other plugins and settings.

Language servers may also be used by your editor. If no other tools need them,
remove npm packages with `npm uninstall -g pyright` or
`npm uninstall -g typescript-language-server typescript`, as appropriate. Remove
only your installed `gopls` binary from the location reported above. To remove the
Rust component, use `rustup component remove rust-analyzer`. Keep the Go/Rust
toolchains and shared PATH entries if other projects use them.
