#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

files=(
  docker-compose.yml
  docker-compose.override.yml
  docker-compose.traefik.yml
)

echo "Using compose files:"
printf '  - %s\n' "${files[@]}"

sudo docker compose -f "${files[0]}" -f "${files[1]}" -f "${files[2]}" up -d
