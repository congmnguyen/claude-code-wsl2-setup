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
