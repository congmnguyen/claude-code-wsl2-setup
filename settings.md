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

## Optional: Code Mode (experimental)

Code Mode changes how Claude calls tools. Instead of requesting each Bash, Read, or
Edit call and reading every result, Claude writes one piece of JavaScript that makes
the calls, filters the output, and returns only what it needs. Tasks with many
related calls take fewer turns and put less intermediate output in context: a change
repeated across many files, a search whose results need filtering, or independent
commands that can run in parallel.

It is experimental, off by default, and may change or be removed in any release.
This section follows the official
[Code Mode documentation](https://code.claude.com/docs/en/code-mode); it has not
been run on WSL2 (see [verification status](maintenance.md#wsl2-verification-status)).

### Requirements

- Claude Code v2.1.323 or later, native build, in an interactive `claude` terminal
  session. It does not work with `-p`, the Agent SDK, the VSCode panel, the Desktop
  app, or cloud sessions.
- A Claude subscription or Console account talking directly to the Anthropic API.
  Gateways, cloud providers, a custom `ANTHROPIC_BASE_URL`, and `apiKeyHelper` stop
  it from starting.
- No `DISABLE_TELEMETRY` and no OpenTelemetry export. Both stop it from starting.

### Turn it on

To try it for one session:

```bash
CLAUDE_CODE_EXPERIMENTAL_CODE_MODE=1 claude
```

To turn it on for every new session, merge this into `~/.claude/settings.json`.
Claude Code ignores the variable in project settings files, so a cloned repository
cannot turn it on for you:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_CODE_MODE": "1"
  }
}
```

The first start asks for confirmation, then restarts and shows:

```text
Code Mode (experimental) is on · this session can be resumed only with Code Mode on
```

Press `Ctrl+O` and expand a **Code** row to read the JavaScript behind the tool calls.

### What it costs

- **Resuming is tied to the flag.** A Code Mode session resumes only in the terminal
  with the variable still set to `1`. Turn Code Mode off and those sessions refuse to
  resume until you turn it back on. Sessions started without Code Mode are unaffected.
- **Auto mode reviews less.** The auto mode classifier reviews each piece of code
  once, not each tool call, and cannot see values computed at run time, such as a
  path taken from search output. `permissions.deny` and `ask` rules still apply to
  every call under the tool's usual name, so put anything that must be blocked in
  exact-match deny rules.
- **Features you lose in the session.** Remote Control, Claude in Chrome, and
  computer use are unavailable. The session cannot move to the Desktop app or become
  a background session, and `/fork` cannot start a background copy.
- **Long-running code is capped.** While Claude waits, code stops after ten minutes,
  including time spent at permission prompts. Code runs in the background, for up to
  two hours, only in sessions started in auto or `bypassPermissions` mode. Use
  [`tmux-notify-run`](claude-notify.md#long-running-tmux-jobs) for longer jobs.
- **Some plugins block it.** Startup can fail with `it doesn't yet work with the
  plugin`, naming the plugin. The documentation does not list which ones, so check
  this if you installed the [LSP plugins](lsp-setup.md).
- **Hooks behave differently.** A `PreToolUse` hook that fails or times out refuses
  the call, and `UserPromptSubmit` hooks can also run on code output. This setup has
  neither, only `Notification` hooks.
- **You see less by default.** The conversation shows the tool calls, not the code
  that made them.

### Verify and turn off

A line starting `Code Mode (experimental) isn't available` means it did not start;
the reason follows on the same line and in `/status`. The documentation's
[troubleshooting table](https://code.claude.com/docs/en/code-mode#code-mode-doesnt-start)
maps each reason to a fix.

To turn it off, remove the variable from your shell and from `~/.claude/settings.json`,
or set it to `0`, then start a new session. A `0` in either place wins over a `1` in
the other.
