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

   The credential-directory patterns end in `(/|$)`, so a bare directory target such as
   `~/.ssh` is blocked as well as `~/.ssh/id_ed25519`.
2. **Grep** applies the same credential pattern to `path` and `glob`, so a content-search
   command does not print a matching file such as `.env` into the conversation. The bare
   directory form matters most here: `Grep path=~/.ssh` prints matching lines out of every
   key in the directory.
3. **Bash** blocks two command shapes aimed at credential paths:
   - **print-like verbs** — `cat`, `head`, `tail`, `sed`, `awk`, `vim`, `base64`, `xxd`, and
     similar content-dumping commands
   - **content-search verbs** — `grep`, `egrep`, `fgrep`, `rg`, `ag`, `ack`, which leak the
     same way `cat` does because they print the matching lines

The Bash branch intentionally keeps inspection commands available. Commands such as `ls`,
`stat`, `wc -l`, or `jq -r 'keys'` can still extract non-secret metadata without dumping
credential values, because none of them is a print or search verb.

**There is no flag-based escape hatch for the search verbs.** `grep -c ~/.aws/credentials`
is blocked along with everything else. That is deliberate. An earlier version exempted
aggregate flags (`-c`, `-l`, `-q`) on the grounds that they print counts rather than
content, and every regex approximation of that rule turned out to be bypassable:

- a safe `grep -c ok safe.log` earlier in the command exempted a leaking `grep` behind it
- `grep -- -c .env` and `grep -e -c .env` pass `-c` as the *pattern*, so the file is printed
- `echo "$(grep -c x .env)" "$(grep PASSWORD .env)"` hides a leaking call behind a safe one
- a quoted pattern containing `|` or `;` broke any splitting on shell control characters

Deciding which invocation actually owns a flag requires a real shell parser — quoting,
comments, `--`, options that consume the next token, nested substitutions. A hook is the
wrong place for one. Blocking the whole shape is the conservative trade: a false positive
costs one rerun with a different command, a miss costs a credential rotation.

Two details keep the check accurate within that conservative stance:

- **Per-argument allowlisting, by exact filename.** The search branch does not use the
  shared substring allowlist. It compares each argument's basename against exact safe names
  (`.env.example`, `.env.sample`, `.env.template`), so `grep PASSWORD .env .env.example`
  still blocks on `.env`, a credential under a benign-looking directory
  (`/tmp/tokenizer/.env`) is not exempted by its parent path, and names that merely contain
  a safe substring (`.env-tokenizer`, `.env.example.backup`, `.env{,.example}`) are blocked.
- **Quoted, nested, redirected and suffixed paths still match.** Boundaries accept quotes,
  parentheses, backticks, `=`, `*`, `,` and the redirection operators, so
  `grep -R . "$HOME/.ssh"`, `echo $(grep PASSWORD .env)`, `` echo `grep PASSWORD .env` ``,
  `rg --glob=.env PASSWORD .`, `grep -R --include=*.env PASSWORD .` and
  `grep PASSWORD<.env` all match. `.env` takes any suffix, so `.env.local`, `.envrc` and
  `.env_prod` are covered alongside plain `.env`, while `.env.example` and friends stay on
  the benign allowlist.

The search-verb check matches only concrete credential paths (`~/.ssh`, `~/.aws`, `.env`,
`.netrc`, `id_rsa`, …), never the bare words `credential`, `secret`, or `token`. Otherwise
an ordinary `grep -i credential /var/log/app.log` would be blocked for searching *for* the
word rather than *inside* a secret.

---

## Verify

`hooks/test-block-secret-reads.sh` feeds synthetic tool-use payloads to the hook and asserts
the exit status of each, covering both the blocked cases and the false positives that must
stay allowed:

```bash
bash hooks/test-block-secret-reads.sh                       # the repo copy
bash hooks/test-block-secret-reads.sh ~/.claude/hooks/block-secret-reads.sh   # the live copy
```

It prints `pass=N fail=0` and exits non-zero on any failure. Run it after every pattern
change — file presence alone proves nothing about the regexes.

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

Two false positives are accepted rather than fixed, because removing them would require the
shell parser described above:

- **A credential name used as a search pattern.** `grep .env README.md` is blocked even
  though `.env` is the pattern and only `README.md` is read.
- **An example command inside a string.** `printf '%s' 'grep PASSWORD .env'` is blocked
  even though it reads nothing.
- **A path that merely starts with `.env`.** `grep -r x .environment/` is blocked, the price
  of covering `.envrc` and `.env_prod`. The Read and Grep branches have always behaved this
  way; the Bash branch now matches them.

Both are covered by the test suite so a future change cannot flip them silently. Work around
either by renaming the pattern (`grep 'dotenv' README.md`) or by asking the user to run the
command.

---

## Known Gaps

This hook is pattern-based by design. It blocks common file-read paths, not every possible
secret exposure.

It does **not** catch:

- environment dumps such as `env`
- direct shell expansion such as `echo $TOKEN`
- secrets already present inside command output or logs
- glob-shaped evasion that avoids the literal credential-looking path
- interpreter-mediated reads such as `python -c "print(open('.env').read())"`, `node -e`, or
  a script that opens the file itself — the verb list cannot cover every language runtime
- deliberately obfuscated spellings of a command, such as `g""rep PASSWORD .env` or a
  backslash-newline split through the middle of a path

The last two are structural, and they mark the hook's threat model. It defends against
*accidental* exposure — Claude reaching for `cat .env` because that is the obvious way to
answer a question — not against a caller deliberately hiding what a command does. Anything
that can run arbitrary Bash can defeat a matcher that only sees command text, so trying to
normalize every equivalent spelling is unwinnable; each round of hardening buys one more
obfuscation and costs another false positive.

Cover both with the
[`sandbox.filesystem.denyRead` rule](settings.md#block-sandboxed-access-to-claude-authentication-data)
instead, which acts on the file access itself rather than on the command text, and is
therefore indifferent to how the command was spelled.

The hook does normalize the spellings that appear in *ordinary* commands: backslash escaping
(`.e\nv`), quoting, brace expansion, `--glob=`/`--include=` filters, attached redirections,
and paths written relative to the working directory.

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
- Prefer a non-printing or aggregate command such as `stat`, `ls -l`, `wc -l`, or
  `jq -r 'keys'`.
- Avoid commands that print or search file contents. `grep -c` is *not* an escape hatch on
  a credential path — the search verbs are blocked regardless of their flags.

**A secret still appears in the transcript**
- Treat it as exposed.
- Say that a secret leaked into the transcript.
- Rotate the affected token, key, cookie, or credential.
- Add a narrower rule or hook pattern for the missed path.
