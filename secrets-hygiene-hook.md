# Claude Code Secrets Hygiene Hook

## Problem

Claude Code can read credential files into the conversation with `Read`, `Grep`, or shell
commands such as `cat ~/.ssh/id_ed25519` or `cat .env`.

That is a permanent exposure: once a private key, token, cookie, kubeconfig, Docker auth
file, or cloud credential lands in the transcript, the practical fix is to rotate it.

A prompt rule in `CLAUDE.md` is useful, but it is soft. A deterministic `PreToolUse` hook
blocks the dangerous tool call before the file contents are printed.

---

## Install

### Step 1: Save the hook script

Save the script to `~/.claude/hooks/block-secret-reads.sh`:

```bash
mkdir -p ~/.claude/hooks
cp hooks/block-secret-reads.sh ~/.claude/hooks/block-secret-reads.sh
chmod +x ~/.claude/hooks/block-secret-reads.sh
```

### Step 2: Wire it into `~/.claude/settings.json`

Add the hook under the top-level `"hooks"` object:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Grep|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-secret-reads.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have other `PreToolUse` hooks, merge this entry into the existing array.

Restart Claude Code after editing `settings.json`.

For defense in depth, also add the targeted
[`sandbox.filesystem.denyRead` rule](settings.md#block-sandboxed-access-to-claude-authentication-data). It prevents
indirect reads by scripts and dependencies that do not expose the authentication path in the
original Bash command.

---

## How It Works

Claude Code sends the tool-use event JSON to the hook on stdin before running the tool.
The hook inspects the requested tool and exits with status `2` when it should be blocked.
Claude Code treats exit `2` as a hard block and shows the hook's stderr as the reason.

The script has three branches:

1. **Read** blocks `file_path` when it matches a broad credential pattern:
   - SSH keys and config under `~/.ssh/*`
   - AWS credentials under `~/.aws/credentials`
   - Kubernetes config under kube paths such as `~/.kube/*`
   - gcloud config under `~/.config/gcloud/*`
   - Docker auth at `~/.docker/config.json`
   - `.env`, `.netrc`, `.npmrc`
   - common private-key names such as `id_rsa` and `id_ed25519`
   - generic path words such as `credential`, `secret`, and `token`
2. **Grep** applies the same credential pattern to `path` and `glob`, so a content-search
   command does not print a matching file such as `.env` into the conversation.
3. **Bash** blocks only print-like verbs aimed at credential paths: `cat`, `head`, `tail`,
   `sed`, `awk`, `vim`, `base64`, `xxd`, and similar content-dumping commands.

The Bash branch intentionally keeps inspection commands available. Commands such as `ls`,
`stat`, `jq -r 'keys'`, or `grep -c` can still extract non-secret metadata without dumping
credential values.

---

## False Positives

The hook includes a benign allowlist regex for common non-secret matches:

- tokenizer-related paths
- `.env.example`, `.env.sample`, and `.env.template`
- code identifiers such as `token_count`, `max_token`, and `num_token`
- the hook script's own filename

If a legitimate workflow trips the hook, tune the benign allowlist first. Keep the allowlist
narrow: prefer one explicit filename or identifier over weakening the main credential
pattern.

---

## Known Gaps

This hook is pattern-based by design. It blocks common file-read paths, not every possible
secret exposure.

It does **not** catch:

- environment dumps such as `env`
- direct shell expansion such as `echo $TOKEN`
- secrets already present inside command output or logs
- glob-shaped evasion that avoids the literal credential-looking path

Pair the hook with a short `CLAUDE.md` rule:

```markdown
Never print secrets, tokens, private keys, cookies, credential files, env dumps, or
secret-bearing logs into the transcript. If secret material leaks anyway, say so
immediately and tell the user to rotate it.
```

---

## Troubleshooting

**Claude says the tool call was blocked**
- Read the hook error shown in Claude Code. It is printed from stderr by
  `~/.claude/hooks/block-secret-reads.sh`.
- If the target is genuinely non-secret, add a narrow benign allowlist entry.

**A metadata command is blocked**
- Prefer a non-printing or aggregate command such as `stat`, `ls -l`, `grep -c`, or
  `jq -r 'keys'`.
- Avoid commands that print full file contents.

**A secret still appears in the transcript**
- Treat it as exposed.
- Say that a secret leaked into the transcript.
- Rotate the affected token, key, cookie, or credential.
- Add a narrower rule or hook pattern for the missed path.
