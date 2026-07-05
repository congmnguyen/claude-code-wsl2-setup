#!/bin/bash
# PreToolUse hook (matcher: Read|Grep|Bash) — blocks printing credential files into the transcript.
# Exit 2 = block the tool call; stderr is shown to Claude as the reason.
# Tune the patterns below if you hit a false positive.

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")

# Things that look secret but aren't (ML tokenizers, templates, counters, this hook itself)
benign='(tokeniz|\.env\.(example|sample|template)|token_count|max_token|num_token|block-secret-reads)'

# Broad pattern for direct file targets (Read tool file_path, Grep path/glob)
secret_file='(/\.ssh/|/\.aws/|/\.kube/|/\.config/gcloud/|/\.docker/config\.json|(^|/)\.env|\.netrc|\.npmrc|id_rsa|id_ed25519|credential|secret|token)'

block() {
  echo "Blocked by secrets-hygiene hook: $1 Extract only the non-secret field you need instead (jq -r 'keys', grep -c, docker info | grep username), or ask the user to run it themselves." >&2
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
    # Only block print-style verbs aimed at concrete credential paths;
    # ls/stat/jq-keys style inspection stays allowed per user's hygiene rule.
    read_verb='(^|[|;&[:space:]])(cat|less|more|head|tail|bat|strings|xxd|hexdump|base64|sed|awk|cut|source|vim|nano)[[:space:]]'
    secret_path='(\.ssh/|\.aws/(credentials|config)|\.kube/config|\.config/gcloud/|\.docker/config\.json|(^|[[:space:]"'"'"'/])\.env|\.netrc|\.npmrc|id_rsa|id_ed25519|credential|secret|token)'
    if [[ "$cmd" =~ $read_verb ]] && [[ "$cmd" =~ $secret_path ]] && ! [[ "$cmd" =~ $benign ]]; then
      block "this command appears to print credential-file contents."
    fi
    ;;
esac
exit 0
