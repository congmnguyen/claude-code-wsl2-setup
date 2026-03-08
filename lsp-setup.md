# Claude Code — LSP Setup

Claude Code uses Language Server Protocol (LSP) to navigate code semantically — finding
definitions, references, and types — instead of falling back to text search. This gives
Claude more accurate context when reading and editing code.

LSP has been built into Claude Code since v2.0.74 and is enabled by default. No env var
or setting is needed; you just need the language server binaries on your PATH.

---

## TypeScript / JavaScript

```bash
npm install -g typescript typescript-language-server
```

Uses nvm? The binary lands in the active Node version's bin — no PATH changes needed.

---

## Python — pyright

pyright is Microsoft's Python type checker (same engine as Pylance in VSCode). It's
faster and more accurate than pylsp for type inference and go-to-definition.

```bash
python3 -m pip install pyright --break-system-packages
```

`--break-system-packages` is required on Ubuntu 24.04+ due to PEP 668. The binary
installs to `~/.local/bin/pyright`, which should already be on your PATH via
`export PATH="$HOME/.local/bin:$PATH"` in `.zshrc`.

---

## Go — gopls

`apt` only provides Go 1.22, but gopls requires Go 1.25+. Install a current Go release
to `~/.local/go` (no sudo needed), then install gopls with it.

```bash
# Download Go 1.26.1 (check https://go.dev/dl/ for the latest)
wget https://go.dev/dl/go1.26.1.linux-amd64.tar.gz -O /tmp/go.tar.gz
mkdir -p ~/.local/go
tar -xf /tmp/go.tar.gz -C ~/.local/go --strip-components=1

# Install gopls
~/.local/go/bin/go install golang.org/x/tools/gopls@latest
```

gopls lands in `~/go/bin/` by default. Add both to PATH (see below).

---

## Rust — rust-analyzer

Install Rust via rustup; rust-analyzer comes bundled as a component.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

rust-analyzer lands in `~/.cargo/bin/rust-analyzer`.

---

## PATH — add to `~/.zshrc`

```bash
# LSP tooling paths
export PATH=$PATH:$HOME/.local/go/bin:$HOME/go/bin:$HOME/.cargo/bin
source "$HOME/.cargo/env" 2>/dev/null || true
```

The `2>/dev/null || true` guard prevents an error in non-interactive shells where
`$HOME` may not be set when the file is first sourced.

---

## Verify

```bash
source ~/.zshrc
which typescript-language-server   # ~/.nvm/.../bin/typescript-language-server
which pyright                      # ~/.local/bin/pyright
which gopls                        # ~/go/bin/gopls
which rust-analyzer                # ~/.cargo/bin/rust-analyzer
```

---

## Troubleshooting

**gopls: command not found**
- Ensure both `~/.local/go/bin` and `~/go/bin` are in PATH.
- Confirm the Go version: `~/.local/go/bin/go version` should print 1.25+.

**pip install fails with "externally-managed-environment"**
- Add `--break-system-packages` to the pip command (Ubuntu 24.04+ / PEP 668).

**rust-analyzer: command not found after rustup**
- Run `rustup component add rust-analyzer` to install it explicitly.
- Ensure `~/.cargo/bin` is in PATH and restart your shell.

**typescript-language-server: command not found**
- Confirm Node is active: `node --version`.
- With nvm, run `nvm use` or set a default: `nvm alias default node`.
