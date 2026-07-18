# Claude Code Settings Tweaks

## Disable git attribution and session links

By default Claude Code appends `Co-authored-by: Claude` to commits and PR descriptions.
Web and Remote Control sessions can also append a `Claude-Session` link to commits
and PR descriptions. To remove both, update `~/.claude/settings.json`:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

Empty strings disable commit and PR attribution. `sessionUrl: false` disables the
session link. The deprecated `includeCoAuthoredBy` key and the non-existent
`gitAttribution` key do nothing — `attribution` is the correct field.

---

## Bash sandbox: filesystem rules staged, toggle off

The live config keeps the Bash sandbox **disabled globally** (`"enabled": false`) but
stages the filesystem rules so enabling it is a one-flag change:

```json
{
  "sandbox": {
    "enabled": false,
    "filesystem": {
      "allowWrite": ["~/.cache/uv", "~/.codex"],
      "denyRead": ["~/.claude/.credentials.json"]
    }
  }
}
```

`~/.cache/uv` keeps `uvx`-based hooks (e.g. the Ruff format hook) working under the
sandbox; `~/.codex` lets the Codex delegate wrapper write its session state. To enable
the sandbox everywhere, flip `enabled` to `true`; project-local
`.claude/settings.local.json` entries can still tune sandbox behavior for one repository.

---

## Block sandboxed access to Claude authentication data

The secrets hygiene hook blocks explicit attempts to print authentication files, but a
script or dependency can read a file indirectly. Add a targeted sandbox rule in
`~/.claude/settings.json` so subprocesses cannot open Claude's login data:

```json
{
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/.claude/.credentials.json"]
    }
  }
}
```

Merge this into the existing `sandbox` object. Keep the rule targeted: denying all of
`~/.ssh`, `~/.aws`, or `~/.kube` can break legitimate CLI authentication.

---

## Skip the trust dialog for a project

Claude Code shows a trust prompt the first time you open a new directory.
To pre-accept it, add `"hasTrustDialogAccepted": true` under the project path
in `~/.claude.json`:

```json
{
  "projects": {
    "/home/you/your-project": {
      "hasTrustDialogAccepted": true
    }
  }
}
```

Claude Code merges new fields in on next launch, so existing project data is preserved.
