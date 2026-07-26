# Claude Code Ruff Auto-Format Hook

## Problem

Claude's Python edits can drift from a project's formatting rules, producing noisy
`ruff format` diffs later or CI failures on lint. Fixing that by telling Claude to
"run ruff after every edit" wastes a tool round-trip per file and is easy to forget.

This PostToolUse hook formats a Python file automatically after every `Edit`/`Write` —
but **only when the file belongs to a project that declares Ruff configuration**
(`ruff.toml`, `.ruff.toml`, or a `[tool.ruff]` table in `pyproject.toml`). Projects
that don't opt into Ruff are never touched.

---

## Install

### Step 1: Save the hook script

```bash
mkdir -p ~/.claude/hooks
cp hooks/format-python-with-ruff.sh ~/.claude/hooks/format-python-with-ruff.sh
chmod +x ~/.claude/hooks/format-python-with-ruff.sh
```

Requires `jq` and `uv` (the hook invokes the pinned Ruff version through
`uvx ruff@0.16.0`).

### Step 2: Wire it into `~/.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/format-python-with-ruff.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have other `PostToolUse` hooks, merge this entry into the existing array.
Restart Claude Code after editing `settings.json`.

---

## How It Works

Claude Code sends the tool event JSON to the hook on stdin after an `Edit` or `Write`
completes. The hook:

1. Extracts `.tool_input.file_path` and exits immediately unless it is an existing `*.py` file.
2. Walks up from the file's directory looking for `ruff.toml`, `.ruff.toml`, or
   `[tool.ruff]` in `pyproject.toml`.
3. On the first match, runs `uvx ruff@0.16.0 format` then
   `uvx ruff@0.16.0 check --fix` on the file.
4. Stops the walk at the repository root (`.git` — checked with `-e`, so git worktrees
   where `.git` is a file also stop the walk) or filesystem root.

The hook always exits `0`, so a Ruff failure never blocks the edit itself.

---

## Verify

Run the hook against synthetic payloads, not just by editing a file:

```bash
d=$(mktemp -d)
printf '[tool.ruff]\n' > "$d/pyproject.toml"
printf 'x=1\n' > "$d/a.py"
echo "{\"tool_input\":{\"file_path\":\"$d/a.py\"}}" | ~/.claude/hooks/format-python-with-ruff.sh
cat "$d/a.py"   # → "x = 1" (formatted)
```

A `.py` file in a directory tree without Ruff config must pass through unchanged.

---

## Troubleshooting

**Files aren't being formatted**
- Check the project actually declares Ruff config — the hook is opt-in by design.
- Check `uv` is on the PATH Claude Code hooks run with (`uvx ruff@0.16.0 --version`).

**Formatting you didn't want**
- The nearest config wins. A `[tool.ruff]` table in a parent directory inside the same
  repository applies to nested packages; add a local `ruff.toml` to override.
