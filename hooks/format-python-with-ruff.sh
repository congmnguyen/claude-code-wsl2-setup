#!/bin/bash
# PostToolUse hook for Python file edits. Runs Ruff only when the edited file
# belongs to a project that declares Ruff configuration.

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")

case "$file_path" in
  *.py) ;;
  *) exit 0 ;;
esac

[[ -n "$file_path" ]] || exit 0
[[ -f "$file_path" ]] || exit 0

dir=$(dirname "$file_path")
while [[ "$dir" != "/" ]]; do
  if [[ -f "$dir/ruff.toml" ]] \
    || [[ -f "$dir/.ruff.toml" ]] \
    || grep -qs '^\[tool\.ruff' "$dir/pyproject.toml"; then
    uvx ruff@0.16.0 format "$file_path" \
      && uvx ruff@0.16.0 check --fix "$file_path"
    break
  fi

  [[ -e "$dir/.git" ]] && break
  dir=$(dirname "$dir")
done

exit 0
