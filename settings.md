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
