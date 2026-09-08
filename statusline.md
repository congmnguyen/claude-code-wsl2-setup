# Claude Code Status Line

A custom status line script that shows the current project directory, git branch, context window usage, and rate limits — color-coded by severity.

![Status line preview](assets/statusline.png)

```
📁 claude-code-wsl2-setup | 🌿 main | [··········] 6% | 5h:10% | W:95%
```

- **Project dir** — basename of `.workspace.current_dir` (fallback: `$PWD`), prefixed with `📁`
- **Git branch** — current branch, prefixed with `🌿` (only shown inside git repos)
- **Progress bar** — context window fill (green < 70%, yellow < 90%, red ≥ 90%); unused cells are dim gray dots
- **5h:X%** — 5-hour rolling usage
- **W:X%** — 7-day rolling usage

---

## Install

**1. Install the script**

Requires Bash 4.4+, `jq`, and Git for the branch display. On Ubuntu inside WSL:

```bash
sudo apt install jq git
```

From the cloned repository, install [the script](bin/statusline-command.sh).
If the destination already exists, back it up before replacing it:

```bash
mkdir -p ~/.claude
if [ -f ~/.claude/statusline-command.sh ]; then
  cp --backup=numbered ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.bak
fi
install -m755 bin/statusline-command.sh ~/.claude/statusline-command.sh
```

**2. Merge the setting into `~/.claude/settings.json`**

Keep the rest of your settings. Back up the file first; see [maintenance](maintenance.md).

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Restart Claude Code. The status line appears at the bottom of the interface.

---

## How it works

Claude Code pipes a JSON blob to the script's stdin on every refresh. The script reads four fields using `jq`:

| Field | JSON path |
|-------|-----------|
| Working dir | `.workspace.current_dir` |
| Context % | `.context_window.used_percentage` |
| 5-hour usage % | `.rate_limits.five_hour.used_percentage` |
| 7-day usage % | `.rate_limits.seven_day.used_percentage` |

The git branch is resolved by running `git symbolic-ref` against the working directory from the JSON — no `cd` needed, and `--no-optional-locks` avoids touching `.git/` lock files. On a detached HEAD (mid-rebase, mid-bisect) it falls back to a short SHA.

Missing or null percentages are omitted independently. The script preserves empty
fields with NUL separators, so weekly usage cannot shift into the five-hour or
context display. Invalid numeric text is omitted, and the context bar is capped
at 100%. Malformed JSON exits with an error instead of rendering misleading data.

The [Claude Code statusline reference](https://code.claude.com/docs/en/statusline)
describes the input fields. Rate limits may be absent, including before the first
API response or for accounts without the supported subscription data.

The filled cells inherit the context severity color, while unused cells use dim gray `·` characters. This keeps a nearly empty bar from looking like a solid block in terminal themes where `░` renders too heavily.

Output uses `printf '%s'`, not `%b`: a directory or branch name containing a backslash would otherwise be mangled by escape interpretation.

---

## Verify

Run this sample without starting Claude Code:

```bash
printf '%s' '{"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":null},"rate_limits":{"five_hour":{"used_percentage":34},"seven_day":{"used_percentage":56}}}' | bash ~/.claude/statusline-command.sh
```

Expect `5h:34%` and `W:56%`, with no context bar. Then open Claude Code and confirm
that the statusline appears. Missing subscription data should leave only the
available parts visible.

For the repository's regression checks, run:

```bash
python3 -m unittest discover -s tests -v
```

## Remove

Remove only this `statusLine` entry from `~/.claude/settings.json`, or restore your
previous statusline setting. Restart Claude Code, then remove the installed script
if nothing else uses it:

```bash
rm -f ~/.claude/statusline-command.sh
```

If you replaced a script, restore your saved copy instead. Keep other settings intact.
