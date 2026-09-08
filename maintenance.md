# Verify, maintain, and remove the setup

This repository preserves a WSL2 + Windows Terminal setup. Linux checks cover
scripts and documentation; Windows notifications, clipboard integration, and
terminal input still need testing on a real WSL2 installation.

## Before changing configuration

Install one feature at a time and keep your existing settings. Save a copy of each
file you will edit. For example, before changing Claude Code settings:

```bash
if [ -f ~/.claude/settings.json ]; then
  cp --backup=numbered ~/.claude/settings.json ~/.claude/settings.json.bak
fi
```

Do the same for a script, shell startup file, keybindings file, or service unit
before replacing it. For Windows Terminal and VSCode, save copies through Windows
before editing. Record the settings you add so removal does not affect other tools.

Merge JSON objects and append only the required array entries. Do not replace an
existing settings file with a small example from a guide. After editing, check JSON:

```bash
jq empty ~/.claude/settings.json
```

For JSON files with comments, use the application's editor/validator instead of
plain `jq`. Restart the relevant application and confirm it loads the change.

## Check each installed feature

| Component | Check after installation | Remove or restore |
| --- | --- | --- |
| [Statusline](statusline.md#verify) | Run the sample payload, then open Claude Code and inspect available fields | Remove this `statusLine` setting, restore any previous setting/script, and delete the installed script only if unused |
| [Notifications](claude-notify.md#verify-and-remove) | Send a forced test balloon, test foreground suppression, then trigger a hook event | Remove only handlers calling this script; retain the script while Codex or tmux uses it |
| [Screenshot paste](image-paste.md#verify) | Check the user service, paste a screenshot, and repeat after restarting WSL | Disable the service before deleting its unit; remove only the added keybinding and unused binary |
| [LSP](lsp-setup.md#verify) | Check each selected server's executable/version, then navigate to a definition with Claude | Disable the selected plugins; remove server binaries only if your editor does not need them |
| [Browser routing](browser.md#verify-and-undo) | Test both the quoted `BROWSER` executable and `xdg-open` | Restore the previous environment setting and HTTP/HTTPS handlers before removing the desktop file |
| [Terminal titles](terminal-title.md#verify) | Open a fresh zsh tab and check directory and command titles | Remove the added `_wt_*` functions, their two `add-zsh-hook` registrations, and the added environment export; restore previous terminal/agent title settings and start a fresh shell |
| [Shift+Enter](shift-enter.md) | Type two lines in Claude Code; Shift+Enter should insert a newline | Remove only the added binding in Windows Terminal or VSCode, or restore the binding you replaced; reopen the terminal |
| [CapsLock remap](capslock-esc.md) | Check that CapsLock acts as Escape after signing in again | Delete only that mapping in SharpKeys, write to the registry, then sign out and back in |
| [Attribution preference](settings.md#verify-and-undo) | Check the next commit/PR you request from Claude | Restore the previous values, or remove the added fields to use defaults |
| [tmux helper](claude-notify.md#long-running-tmux-jobs) | Run the disposable job below and inspect its exit status and log | Let jobs finish; remove the helper if unused, retaining logs/state until no longer needed |

For a tmux smoke check, choose a session name not already in use. From the cloned
repository, with `tmux` and `setsid` available:

```bash
bash bin/tmux-notify-run setup-check -- /bin/echo 'setup check'
# After the job finishes:
bash bin/tmux-notify-run --status setup-check
cat "${XDG_STATE_HOME:-$HOME/.local/state}/tmux-notify-run/setup-check/job.log"
```

Expect `exit=0` and `setup check` in the log. A missing notification script does
not fail the job; verify Windows delivery separately. The helper creates files
under the state directory above and can reuse a finished session name, replacing
that job's state/log, so use a dedicated name for this check.

## Optional integrations

- [Agents and skills](optional-extras.md): install one at a time. Confirm it is
  available in a fresh Claude session; remove only the file or directory you
  copied, or restore its previous version. Check both project and user scope if
  you installed copies in more than one place.
- [Figma Desktop MCP](mcp-setup.md): use `/mcp` in the intended project and request
  a small selection from Figma. To remove it, use `/mcp` to identify its scope,
  then `claude mcp remove figma-desktop --scope <scope>` for that scope. Keep
  unrelated servers. Turn off Figma's local server only if nothing else needs it.
- [LangSmith tracing](langsmith-tracing.md): check that a turn appears in the
  intended project. To stop tracing, remove only the added trace environment
  entries from that project's local settings and restart Claude. Remove the
  plugin through `/plugin` if no other project uses it. Existing remote traces
  are not deleted by disabling the integration.
- [Codex notification](codex-notify.md): check a completed turn while Windows
  Terminal is unfocused. To undo, restore or remove only the top-level `notify`
  entry you added, then restart Codex. Keep the shared notification script if
  Claude or tmux still uses it.
- Third-party tools such as liteparse: follow their upstream verification and
  uninstall guidance. Remove copied skills separately; retain shared dependencies
  such as LibreOffice if other applications need them.

## Automated checks

Requires Bash 4.4+, Python 3, Git, and `jq`. From the cloned repository:

```bash
bash scripts/check.sh
```

The same command runs in [GitHub Actions](.github/workflows/checks.yml):

- Bash syntax for scripts in `bin/`, `scripts/`, and `archive/scripts/`.
- Local inline Markdown links, heading anchors, and HTML image paths. External
  links, reference-style links, and fenced command examples are not checked.
- Statusline behavior with missing/null/zero values, malformed data, literal path
  characters, percentage rounding, and Git branches/detached HEADs.
- Notification argument generation with a mock PowerShell executable, plus
  portable hook JSON and errors for invalid options or a missing executable.

The notification tests do not run PowerShell or display a balloon. Passing CI
does not certify Windows interoperability, GUI behavior, third-party installers,
or configuration loading in a live Claude Code session.

When reporting a WSL2 issue, include Windows, WSL, distro, terminal, and Claude
Code versions, the relevant feature, reproduction steps, and the observed error.
