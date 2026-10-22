#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

scripts=()
while IFS= read -r -d '' file; do
  bash -n "$file"
  scripts+=("$file")
done < <(find bin scripts -type f \( -name '*.sh' -o -path 'bin/*' \) -print0)

# CI sets CHECKS_REQUIRE_ALL so optional tools cannot be skipped silently there.
if command -v shellcheck >/dev/null; then
  shellcheck "${scripts[@]}"
  printf 'shellcheck OK (%d scripts).\n' "${#scripts[@]}"
elif [[ -n ${CHECKS_REQUIRE_ALL:-} ]]; then
  echo 'shellcheck is required when CHECKS_REQUIRE_ALL is set' >&2
  exit 1
else
  echo 'shellcheck not installed; skipped.'
fi
python3 scripts/check_links.py
python3 -m unittest discover -s tests -v
