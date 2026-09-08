#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find bin scripts archive/scripts -type f \( -name '*.sh' -o -path 'bin/*' \) -print0)
python3 scripts/check_links.py
python3 -m unittest discover -s tests -v
