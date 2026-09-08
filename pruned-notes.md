# Hooks and components I removed

Native Windows PowerShell notifications, WSLg voice-mode audio, Playwright browser
automation, and uninstalled Claude skills were removed from the main repo because they are
not part of the WSL2 setup I kept at the time. Git history keeps them if you want the old versions.

The three `PreToolUse` / `PostToolUse` hooks were removed for a different reason: each one
judged tool input by pattern, and the failures below were observed in my previous setup.

- `truncate-bash-output` rewrote `.stdout` to head + tail. At the time, Claude Code saved
  oversized output to a file and showed a preview, losing nothing; truncating below that
  threshold suppressed the built-in behaviour and destroyed the middle permanently — where
  test failures and stack traces live. It also cost more context than the preview it
  replaced, and died on long lines (`jq: Argument list too long`), passing the full
  untruncated output through.
- `block-secret-reads` blocked reads of credential files by regex. Probed with synthetic
  payloads it caught 1 of 11 trivial rephrasings (`dd`, `od`, `nl`, `tac`, `rev`, `perl`,
  `tee`, a `while read` loop, `tar | base64`, `python3 -c`) while rejecting all 5 ordinary
  source files named like `token_manager.py` or `credentials_service.py`. I switched to exact-match
  `permissions.deny` rules for specific paths instead of maintaining this hook.
- `format-python-with-ruff` ran `ruff check --fix` after every Python edit, which deleted an
  `import` out of a file the moment it was written — leaving what is on disk different from
  what the agent believes it wrote. It could also spin forever on a relative path, since
  `dirname .` never reaches `/`.

`Notification` hooks stayed because they served a different purpose: reporting events.
Their delivery still depends on hook configuration and Windows notification behavior.


These are historical observations, not fresh benchmarks against current Claude Code.
Return to the [setup guide](README.md).
