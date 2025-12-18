#!/bin/sh
set -e
: "${ARIA2_SECRET:?set ARIA2_SECRET}"
# ensure dirs (namespaced for aria2)
mkdir -p /config /downloads/aria2/complete /downloads/aria2/incomplete /downloads/aria2/watch
chown -R 1000:1000 /config /downloads
# generate session if missing
touch /config/aria2.session
mkdir -p /tmp
# use bundled config and pass secret explicitly to avoid templating
exec aria2c --conf-path="/aria2.conf" --rpc-secret="${ARIA2_SECRET}"
