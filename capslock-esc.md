# CapsLock → Escape with SharpKeys (Windows)

## Problem

CapsLock is a wasted key for most developers. Escape is critical for Vim-style editing
(including Claude Code's `/vim` mode) but is physically far away. Swapping them system-wide
makes modal editing significantly less painful.

## Fix

[SharpKeys](https://github.com/randyrants/sharpkeys) remaps keys at the Windows registry level
(`Scancode Map`), so the remap works everywhere — WSL2, Windows Terminal, VSCode, games — even
before any user logs in.

### Install

```
winget install RandyRants.SharpKeys
```

Or download from the [Microsoft Store](https://apps.microsoft.com/detail/sharpkeys/9PKX3HX4HMR7)
or [GitHub Releases](https://github.com/randyrants/sharpkeys/releases).

### Configure

1. Open **SharpKeys** as a normal user (no admin needed for the UI).
2. Click **Add**.
3. Set **From key**: `Special: Caps Lock (00_3A)`
4. Set **To key**: `Special: Escape (00_01)`
5. Click **OK**, then **Write to Registry**.
6. Log off and back on (or reboot) — the remap is active immediately after.

### Verify

Open any terminal and press CapsLock — you should see `^[` in `cat` or the cursor should enter
normal mode in `vim`.

## Notes

- The remap is stored in `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout`
  and applies to all users and all applications system-wide.
- SharpKeys does not need to run in the background — it only writes to the registry.
- To reverse: open SharpKeys, delete the entry, click **Write to Registry**, then log off.
- If you use the actual CapsLock occasionally, consider swapping it to `Shift+Escape` in
  SharpKeys (`To key`: `Special: Caps Lock (00_3A)`, add a second entry mapping a spare key).

## Why Not AutoHotkey?

AutoHotkey remaps in user space — it only works when the AHK script is running and can break
inside WSL2 windows or elevated processes. SharpKeys's registry remap is handled by the kernel
driver and is unconditional.
