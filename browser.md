# Claude Code WSL2 — Open Links in Windows Browser

## Problem

If links from Claude Code or other CLI tools open in a browser inside WSL2,
you can route them to your existing Windows browser instead.

---

## How It Works

Set the `BROWSER` environment variable to the path of your Windows browser executable
under `/mnt/c/...`. Claude Code and many Linux tools read `BROWSER` to decide which
program to launch for URLs.

Some CLI tools ignore `BROWSER` and delegate to `xdg-open` instead. For those tools,
register the same Windows browser as WSL's HTTP/HTTPS MIME handler.

---

## Setup

Add to `~/.bashrc`:

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
source ~/.bashrc
```

These commands target Ubuntu's default `bash`; if you use `zsh`, use `~/.zshrc`
instead.

### XDG fallback for OAuth and CLI tools

First check whether WSL still points to another browser:

```bash
xdg-settings get default-web-browser
xdg-mime query default x-scheme-handler/https
```

Record the existing HTTP and HTTPS handlers so you can restore them later:

```bash
xdg-mime query default x-scheme-handler/http
xdg-mime query default x-scheme-handler/https
mkdir -p ~/.local/share/applications
```

Then create `~/.local/share/applications/brave-windows.desktop`:

```ini
[Desktop Entry]
Name=Brave Browser (Windows)
Comment=Open web links in the Windows Brave profile
Exec=/mnt/c/Users/<YourUsername>/AppData/Local/BraveSoftware/Brave-Browser/Application/brave.exe %U
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=false
```

Register it as the URL handler:

```bash
mkdir -p ~/.local/share/applications
xdg-mime default brave-windows.desktop x-scheme-handler/http
xdg-mime default brave-windows.desktop x-scheme-handler/https
```

Replace `<YourUsername>` with the Windows username and adjust `Exec` when using a
different browser. Desktop entries do not expand `$BROWSER`, so `Exec` must contain
the real executable path. Put the executable path in double quotes in `Exec`
if it contains spaces, as with Chrome under `Program Files`.

---

## Result

Claude Code and tools that respect `BROWSER` open URLs directly in the selected
Windows browser. Tools that use `xdg-open`, including some OAuth CLIs, use the XDG
fallback and reach the same browser profile.

Playwright CLI is intentionally unaffected: it launches an isolated automation
browser unless explicitly attached to an existing browser through CDP.

---

## Troubleshooting

**Browser doesn't open**
- Confirm the `.exe` path is correct: `ls "/mnt/c/Users/<user>/AppData/..."`
- Test manually: `"$BROWSER" "https://example.com"`

**Wrong browser still opens**
- Make sure `source ~/.bashrc` was run in the current session after editing.
- Check no other config is overriding `BROWSER`: `echo $BROWSER`
- Check both XDG handlers: `xdg-mime query default x-scheme-handler/http` and
  `xdg-mime query default x-scheme-handler/https`
- Confirm the desktop entry exists: `test -f ~/.local/share/applications/brave-windows.desktop`


## Verify and undo

Run `"$BROWSER" "https://example.com"` and `xdg-open "https://example.com"`
separately. Both should reach the intended Windows browser.

To undo, restore your previous `BROWSER` assignment (or remove the added export
and run `unset BROWSER` if it was previously unset). Restore each recorded handler
using `xdg-mime default <previous-handler.desktop> x-scheme-handler/http` and the
corresponding HTTPS command. If there was no previous handler, remove only the
association you added from your user `mimeapps.list`. Remove the desktop entry
only after restoring associations. Open a fresh shell and test again.
