# Claude Code Settings Tweaks

## Disable git attribution and session links

By default Claude Code appends `Co-authored-by: Claude` to commits and PR descriptions.
Web and Remote Control sessions can also append a `Claude-Session` link to commits
and PR descriptions. To remove both, merge the following into `~/.claude/settings.json`.
[Back up the file](maintenance.md) first and preserve unrelated settings:

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


## Verify and undo

Parse the edited file with `jq empty ~/.claude/settings.json`, then restart Claude
Code. Check the next commit or PR you ask Claude to create; no extra commit is
needed just to test this preference.

To undo, restore the previous values of the attribution fields you changed. If
those fields did not exist before, remove only those fields to use the defaults.
