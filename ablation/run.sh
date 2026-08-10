#!/usr/bin/env bash
set -euo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: ablation/run.sh PROFILE TASK_FILE [RUN_DIR]

Profiles:
  minimal       --safe-mode: customizations disabled while preserving OAuth auth
  instructions  minimal + the live global CLAUDE.md appended explicitly
  no-mcp        normal Claude Code setup, but with an explicitly empty MCP set
  full          normal live Claude Code setup

Environment:
  ABLATION_MODEL       Model override (default: current Claude Code default)
  ABLATION_EFFORT      Effort level (default: high)
  ABLATION_MAX_BUDGET  Per-run USD limit (default: 5)
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

profile=$1
task_file=$2
run_root=${3:-.ablation-results}

if [[ ! -f $task_file ]]; then
  printf 'Task file not found: %s\n' "$task_file" >&2
  exit 2
fi

case $profile in
  minimal|instructions|no-mcp|full) ;;
  *)
    printf 'Unknown profile: %s\n' "$profile" >&2
    usage >&2
    exit 2
    ;;
esac

claude_bin=${ABLATION_CLAUDE_BIN:-$(command -v claude)}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
task_name=$(basename "$task_file")
task_name=${task_name%.*}
output_dir="$run_root/$timestamp-$task_name-$profile"
mkdir -p "$output_dir"

args=(
  --print
  --output-format json
  --permission-mode plan
  --effort "${ABLATION_EFFORT:-high}"
  --max-budget-usd "${ABLATION_MAX_BUDGET:-5}"
)

if [[ -n ${ABLATION_MODEL:-} ]]; then
  args+=(--model "$ABLATION_MODEL")
fi

case $profile in
  minimal)
    args+=(--safe-mode --strict-mcp-config --mcp-config '{"mcpServers":{}}')
    ;;
  instructions)
    args+=(
      --safe-mode
      --append-system-prompt-file "$HOME/.claude/CLAUDE.md"
      --strict-mcp-config
      --mcp-config '{"mcpServers":{}}'
    )
    ;;
  no-mcp)
    args+=(--strict-mcp-config --mcp-config '{"mcpServers":{}}')
    ;;
  full) ;;
esac

{
  printf 'profile=%s\n' "$profile"
  printf 'task_file=%s\n' "$task_file"
  printf 'cwd=%s\n' "$PWD"
  printf 'claude_version=%s\n' "$($claude_bin --version)"
  printf 'model=%s\n' "${ABLATION_MODEL:-default}"
  printf 'effort=%s\n' "${ABLATION_EFFORT:-high}"
  printf 'max_budget_usd=%s\n' "${ABLATION_MAX_BUDGET:-5}"
  printf 'started_at=%s\n' "$timestamp"
} > "$output_dir/metadata.txt"

set +e
"$claude_bin" "${args[@]}" < "$task_file" > "$output_dir/result.json" 2> "$output_dir/stderr.log"
exit_code=$?
set -e

printf 'exit_code=%s\n' "$exit_code" >> "$output_dir/metadata.txt"
printf 'finished_at=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" >> "$output_dir/metadata.txt"

if jq -e . "$output_dir/result.json" >/dev/null 2>&1; then
  jq '{subtype, is_error, duration_ms, duration_api_ms, num_turns, total_cost_usd, usage, result}' \
    "$output_dir/result.json" > "$output_dir/summary.json"
fi

printf '%s\n' "$output_dir"
exit "$exit_code"
