#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == --version ]]; then
  printf 'test-version\n'
  exit 0
fi

prompt=$(cat)
jq -n --arg result "$prompt" '{
  type: "result",
  subtype: "success",
  is_error: false,
  duration_ms: 1,
  duration_api_ms: 1,
  num_turns: 1,
  total_cost_usd: 0,
  usage: {input_tokens: 1, output_tokens: 1},
  result: $result
}'
