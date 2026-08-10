#!/bin/bash
# PreToolUse hook (matcher: Read|Grep|Bash) — blocks printing credential files into the transcript.
# Exit 2 = block the tool call; stderr is shown to Claude as the reason.
# Tune the patterns below if you hit a false positive.

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")

# Things that look secret but aren't (ML tokenizers, templates, counters, this hook itself)
benign='(tokeniz|\.env\.(example|sample|template)|token_count|max_token|num_token|block-secret-reads\.sh|secrets-hygiene-hook\.md)'

# Broad pattern for direct file targets (Read tool file_path, Grep path/glob).
# Credential dirs use (/|$) so a bare directory target such as `~/.ssh` is caught
# too — Grep on a directory prints matching lines from every file inside it.
secret_file='((^|/)\.ssh(/|$)|(^|/)\.aws(/|$)|(^|/)\.kube(/|$)|(^|/)\.config/gcloud(/|$)|(^|/)\.docker/config\.json|(^|/)\.env|\.netrc|\.npmrc|id_rsa|id_ed25519|credential|secret|token)'

block() {
  echo "Blocked by secrets-hygiene hook: $1 Extract only the non-secret field you need instead (jq -r 'keys', wc -l, docker info | grep username), or ask the user to run it themselves." >&2
  exit 2
}

case "$tool" in
  Read)
    target=$(jq -r '.tool_input.file_path // empty' <<<"$input")
    if [[ "$target" =~ $secret_file ]] && ! [[ "$target" =~ $benign ]]; then
      block "'$target' looks like a credential file."
    fi
    ;;
  Grep)
    target=$(jq -r '[.tool_input.path // empty, .tool_input.glob // empty] | join(" ")' <<<"$input")
    if [[ "$target" =~ $secret_file ]] && ! [[ "$target" =~ $benign ]]; then
      block "'$target' targets credential files; Grep content output would print them."
    fi
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
    # The shell strips escaping before it opens the file, so `.e\nv` names `.env`.
    # Match the de-escaped spelling, not the raw text.
    cmd=${cmd//\\/}
    # Only block print-style verbs aimed at concrete credential paths;
    # ls/stat/jq-keys style inspection stays allowed per user's hygiene rule.
    read_verb='(^|[|;&[:space:]])(cat|less|more|head|tail|bat|strings|xxd|hexdump|base64|sed|awk|cut|source|vim|nano)[[:space:]]'
    # Concrete credential paths always match; the bare words secret/token/credential
    # only match when standalone (file-like), so LLM flags such as
    # --max-num-batched-tokens or grep patterns like 'token|api' don't trip it.
    secret_path='(\.ssh/|\.aws/(credentials|config)|\.kube/config|\.config/gcloud/|\.docker/config\.json|(^|[[:space:]"'"'"'/])\.env|\.netrc|\.npmrc|id_rsa|id_ed25519|(^|[[:space:]"'"'"'/])(secret|token|credential)s?(\.[A-Za-z0-9]+)?([[:space:]"'"'"'/]|$))'
    if [[ "$cmd" =~ $read_verb ]] && [[ "$cmd" =~ $secret_path ]] && ! [[ "$cmd" =~ $benign ]]; then
      block "this command appears to print credential-file contents."
    fi

    # Content search leaks the same way cat does: grep prints the matching lines.
    # Restricted to concrete credential paths (not the bare words secret/token/
    # credential) so searching logs *for* the word "credential" stays allowed.
    # Boundaries accept quotes, parens and backticks so both `grep -R . "$HOME/.ssh"`
    # and `echo $(grep PASSWORD .env)` are still recognised.
    #
    # There is deliberately NO flag-based escape hatch here (no "`grep -c` is fine"
    # exemption). Deciding that a specific invocation only prints a count needs a
    # real shell parser — quoting, comments, `--`, options that consume the next
    # token, nested substitutions — and every regex approximation of one turned out
    # to be bypassable. So the whole shape is blocked: a false positive costs one
    # rerun with a different command, a miss costs a credential rotation.
    # A path token starts and ends at any character that cannot appear in a
    # filename. Enumerating the separators instead (quotes, parens, `=` for
    # --glob=.env, `<` for grep PASSWORD<.env, `{` for .env{,.example}, …) just
    # invites the next one to be missed, so the classes are negated rather than
    # listed. `.` and `-` and `~` stay filename characters, so `myapp.env` and
    # `--max-num-batched-tokens` are still not treated as credential paths.
    bnd='([^A-Za-z0-9_.~-]|$)'
    lead='(^|[^A-Za-z0-9_.~-])'
    search_verb="$lead(grep|egrep|fgrep|rg|ag|ack)$bnd"
    # `.env` takes any suffix, matching the Read/Grep branch: `.envrc` and
    # `.env_prod` hold secrets exactly like `.env.local` does.
    search_secret_path="($lead\.ssh$bnd|$lead\.aws$bnd|$lead\.kube$bnd|\.config/gcloud|\.docker/config\.json|$lead\.env[A-Za-z0-9_.-]*$bnd|\.netrc|\.npmrc|id_rsa|id_ed25519)"
    if [[ "$cmd" =~ $search_verb ]]; then
      # Judge each argument separately, so `grep X .env .env.example` still blocks
      # on .env rather than being waved through by the template beside it. The
      # benign test looks at the basename only: a credential file must not inherit
      # an exemption from a parent directory such as /tmp/tokenizer/.env.
      # The allowlist here is exact filenames, not the shared substring regex:
      # `.env-tokenizer` and `.env.example.backup` are credential files that merely
      # contain a benign-looking substring, and `.env{,.example}` is two targets at
      # once. Only the first run of filename characters is compared, so surrounding
      # quotes or braces cannot smuggle a real credential past the check.
      benign_name='^\.env\.(example|sample|template)$'
      read -ra args <<<"${cmd//$'\n'/ }"
      for arg in "${args[@]}"; do
        [[ "$arg" =~ $search_secret_path ]] || continue
        name=""
        [[ "${arg##*/}" =~ [A-Za-z0-9_.~-]+ ]] && name=${BASH_REMATCH[0]}
        [[ "$name" =~ $benign_name ]] && continue
        block "this command would print matching lines out of a credential file."
      done
    fi
    ;;
esac
exit 0
