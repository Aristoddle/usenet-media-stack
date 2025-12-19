#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

files=(
  docker-compose.yml
  docker-compose.override.yml
)

echo "Using compose files:"
printf '  - %s\n' "${files[@]}"

sudo -E docker compose \
  -f "${files[0]}" \
  -f "${files[1]}" \
  up -d
