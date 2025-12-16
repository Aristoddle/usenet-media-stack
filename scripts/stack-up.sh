#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

files=(
  docker-compose.yml
  docker-compose.override.yml
  docker-compose.traefik.yml
  docker-compose.vpn-mullvad.yml
)

echo "Using compose files:"
printf '  - %s\n' "${files[@]}"

# Load Mullvad env if present
ENVFILE="${ENVFILE:-$HOME/.config/usenet-media-stack/mullvad.env}"
if [ -f "$ENVFILE" ]; then
  echo "Loading Mullvad env from $ENVFILE"
  # shellcheck disable=SC1090
  source "$ENVFILE"
fi

sudo -E docker compose \
  -f "${files[0]}" \
  -f "${files[1]}" \
  -f "${files[2]}" \
  -f "${files[3]}" \
  up -d
