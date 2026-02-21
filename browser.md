# Claude Code WSL2 — Open Links in Windows Browser

## Problem

Claude Code opens links (e.g. OAuth login, documentation) using Chromium inside WSL2
by default. On a WSL2 setup you almost certainly want links to open in your existing
Windows browser instead.

---

## How It Works

Set the `BROWSER` environment variable to the path of your Windows browser executable
under `/mnt/c/...`. Claude Code and most Linux tools read `BROWSER` to decide which
program to launch for URLs.

---

## Setup

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
export BROWSER="/mnt/c/Users/<YourUsername>/AppData/Local/BraveSoftware/Brave-Browser/Application/brave.exe"
```

Replace the path with your browser of choice. Common paths:

| Browser | Path |
|---------|------|
| Brave | `C:\Users\<user>\AppData\Local\BraveSoftware\Brave-Browser\Application\brave.exe` |
| Chrome | `C:\Program Files\Google\Chrome\Application\chrome.exe` |
| Edge | `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` |
| Firefox | `C:\Program Files\Mozilla Firefox\firefox.exe` |

Then reload your shell:

```bash
source ~/.zshrc
```

---

## Result

Any tool that respects the `BROWSER` variable — including Claude Code — will open URLs
directly in your Windows browser instead of launching Chromium inside WSL2.

---

## Troubleshooting

**Browser doesn't open**
- Confirm the `.exe` path is correct: `ls "/mnt/c/Users/<user>/AppData/..."`
- Test manually: `$BROWSER "https://example.com"`

**Wrong browser still opens**
- Make sure `source ~/.zshrc` was run in the current session after editing.
- Check no other config is overriding `BROWSER`: `echo $BROWSER`
