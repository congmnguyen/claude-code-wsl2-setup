# Claude Code Settings Tweaks

## Disable git attribution

By default Claude Code appends `Co-authored-by: Claude` to commits and PR descriptions.
To remove it, set empty strings in `~/.claude/settings.json`:

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

Empty string = no attribution. The deprecated `includeCoAuthoredBy` key and the
non-existent `gitAttribution` key do nothing — `attribution` is the correct field.

---

## Enable Bash sandbox globally

Set the Bash sandbox in user settings so it applies across projects:

```json
{
  "sandbox": {
    "enabled": true
  }
}
```

Project-local `.claude/settings.local.json` entries can still tune sandbox behavior
for one repository. Keep global settings minimal unless a rule should apply
everywhere.

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
