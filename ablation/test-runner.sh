#!/usr/bin/env bash
set -euo pipefail

ablation_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(dirname "$ablation_dir")
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

cd "$repo_dir"

for profile in minimal instructions no-mcp full; do
  output=$(
    ABLATION_CLAUDE_BIN="$ablation_dir/fixtures/fake-claude.sh" \
      "$ablation_dir/run.sh" \
      "$profile" \
      "$ablation_dir/tasks/01-verification-audit.txt" \
      "$test_root"
  )
  test -s "$output/result.json"
  test -s "$output/summary.json"
  grep -Fx "profile=$profile" "$output/metadata.txt" >/dev/null
  jq -e '.is_error == false and .num_turns == 1' "$output/summary.json" >/dev/null
done

matrix_output="$test_root/matrix-output.txt"
ABLATION_CLAUDE_BIN="$ablation_dir/fixtures/fake-claude.sh" \
  "$ablation_dir/run-matrix.sh" \
  "$ablation_dir/tasks/01-verification-audit.txt" \
  "$test_root/matrix" > "$matrix_output"
test "$(wc -l < "$matrix_output")" -eq 4

printf 'PASS: four profiles and matrix output validated\n'
