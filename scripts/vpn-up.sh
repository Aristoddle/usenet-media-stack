#!/usr/bin/env bash
set -euo pipefail

envfile=${ENVFILE:-$HOME/.config/usenet-media-stack/mullvad.env}
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v op >/dev/null 2>&1; then
  echo "op CLI not found; install 1Password CLI" >&2
  exit 1
fi

if ! op whoami >/dev/null 2>&1; then
  echo "Not signed in to 1Password. Run: eval \"$(op signin --account my)\"" >&2
  exit 1
fi

item_json=$(op item get "Mullvad" --vault Personal --format json)
wg_priv=$(echo "$item_json" | jq -r '.fields[] | select(.label=="WireGuard Private Key") | .value')
wg_addr=$(echo "$item_json" | jq -r '.fields[] | select(.label=="WireGuard Address") | .value')
account=$(echo "$item_json" | jq -r '.fields[] | select(.label=="Mullvad Account") | .value')
country=$(echo "$item_json" | jq -r '.fields[] | select(.label=="Country") | .value')
city=$(echo "$item_json" | jq -r '.fields[] | select(.label=="City") | .value')

if [[ -z "$wg_priv" || -z "$wg_addr" ]]; then
  echo "Missing Mullvad WireGuard fields in 1Password item 'Mullvad'." >&2
  exit 1
fi

install -d -m 700 "$(dirname "$envfile")"
umask 077
cat > "$envfile" <<ENV
MULLVAD_WG_PRIVATE_KEY=$wg_priv
MULLVAD_WG_ADDRESSES=$wg_addr
MULLVAD_ACCOUNT=$account
MULLVAD_COUNTRY=${country:-USA}
MULLVAD_CITY=${city:-"New York NY"}
ENV

set -a
source "$envfile"
set +a

cd "$repo_root"
sudo -E docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vpn-mullvad.yml up -d gluetun transmission

echo "gluetun/transmission started via Mullvad. Env loaded from $envfile" 
