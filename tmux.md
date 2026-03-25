# Claude Code WSL2 — tmux Auto-Attach

## Problem

Every time you open a new Windows Terminal tab in WSL2, you get a fresh shell with no context — no scrollback from your last session, no persistent working environment.

---

## How It Works

Two-line tmux strategy: one persistent background session (`main`) that holds your windows and history, plus a new grouped session for each terminal you open. Grouped sessions share the same windows as `main` but have independent views — you can look at different windows in different tabs simultaneously. When you close the terminal tab, the grouped session self-destructs (`destroy-unattached on`), but `main` stays alive with all your work.

---

## Setup

Install tmux if not already installed:

```bash
sudo apt-get install -y tmux
```

Add to the end of `~/.zshrc`:

```bash
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  tmux new-session -d -s main 2>/dev/null
  tmux new-session -t main \; set-option destroy-unattached on
fi
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## Result

Every new terminal tab automatically joins the `main` session as a grouped view. Windows and scrollback persist across tab opens and closes. Closing a tab cleans up its grouped session without affecting the shared state.

---

## Troubleshooting

**tmux not found**
- Run `sudo apt-get install -y tmux`

**Session not persisting**
- Verify `main` is alive: `tmux ls`
- Check that `[ -z "$TMUX" ]` is true before the block runs (i.e., you're not already inside tmux when sourcing `.zshrc`)

**Nested tmux (tmux inside tmux)**
- The `[ -z "$TMUX" ]` guard prevents this — the block only runs in bare shells, not inside an existing tmux session.
