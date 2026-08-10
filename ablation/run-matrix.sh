#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: ablation/run-matrix.sh TASK_FILE [RUN_DIR]\n' >&2
  exit 2
fi

task_file=$1
run_root=${2:-.ablation-results}
runner=$(dirname "$0")/run.sh
matrix_status=0

for profile in minimal instructions no-mcp full; do
  printf 'Running profile: %s\n' "$profile" >&2
  if ! "$runner" "$profile" "$task_file" "$run_root"; then
    printf 'Profile failed: %s\n' "$profile" >&2
    matrix_status=1
  fi
done

exit "$matrix_status"
