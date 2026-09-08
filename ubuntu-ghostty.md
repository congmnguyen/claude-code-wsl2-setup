# Why I moved from WSL2 to Ubuntu + Ghostty

I previously used Claude Code in WSL2 with Windows Terminal. This repository
documents the configuration I used to make that workflow more comfortable.

I now use Ubuntu with Ghostty. For my day-to-day use, that combination has
resolved the friction that led me to build this setup. I no longer need to
maintain the same Windows/WSL integration around my terminal workflow.

## What the old setup was doing

Several guides here exist specifically to connect a Windows desktop to tools
running inside WSL2:

| Need in the previous workflow | What this repository documented |
| --- | --- |
| Paste a Windows screenshot into a coding session | A [screenshot monitor and systemd user service](image-paste.md) that saved an image and copied its WSL path |
| Know when Claude needed attention | [Windows notifications](claude-notify.md), suppressed when Windows Terminal was focused |
| Open links from WSL in the Windows browser | [`BROWSER` configuration and an XDG fallback](browser.md) |
| Adjust terminal input and keyboard behavior | [Shift+Enter configuration](shift-enter.md) and a [Windows CapsLock remap](capslock-esc.md) |

Moving to Ubuntu removes the Windows/WSL boundary from my workflow. Those
Windows-specific instructions no longer describe the environment I use.

That does not mean Ghostty replaces every component in this repository.
[LSP navigation](lsp-setup.md) and a [Claude Code statusline](statusline.md)
address separate needs. Their usefulness is independent of why I stopped
using the Windows integration pieces.

## Why there is no Ubuntu edition of this repo

Ubuntu + Ghostty already meets my current needs. I do not have another set of
workarounds to package into a comparable Ubuntu setup.

This is a note about my own experience, not a claim that every terminal feature
works without configuration on every Ubuntu installation. I am not publishing
a tested Ubuntu installation guide or a feature-by-feature Ghostty comparison
here.

## If you still use WSL2

The guides remain available. If your workflow needs Windows and WSL2, the
screenshot, notification, and browser integration documented here may still be
useful. Start with the specific problem you want to solve in the
[README](README.md#who-this-is-for).

Switching operating systems changes more than a terminal. Consider the Windows
applications and workflows you depend on before following the same path.

I no longer test this setup daily on WSL2. Reports with reproduction steps and
fixes tested on WSL2 are welcome. Please include the relevant Windows, WSL,
terminal, and Claude Code versions so others can understand the result.

The repository keeps its WSL2 name and purpose. It records a setup that was
useful to me and remains available to people working in that environment.
