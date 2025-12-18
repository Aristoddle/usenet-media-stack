# Download Clients & Paths

## Shared roots
- Host downloads root: `/var/mnt/fast8tb/Local/downloads` (mounted as `/downloads` in containers).
- Per-client subfolders (only these remain; legacy top-level `complete/incomplete/watch` removed):
  - Transmission: `/downloads/transmission/{complete,incomplete,watch}`
  - Aria2: `/downloads/aria2/complete` (incomplete/watch optional for now)
  - SABnzbd: `/downloads/sabnzbd/{complete,incomplete}`

## Transmission
- RPC: `http://localhost:9091/transmission/rpc` (no auth).
- Paths (in container): `download-dir=/downloads/transmission/complete`, `incomplete-dir=/downloads/transmission/incomplete`, `watch-dir=/downloads/transmission/watch` (watch shows null in RPC but is set in settings.json).
- Watch folder requires the `.torrent` file to be readable by UID 1000; otherwise it will be ignored.
- Config file: `/var/mnt/fast8tb/config/transmission/settings.json`.

## Aria2
- XML-RPC (Prowlarr): `http://localhost:6800/rpc` (secret entered **without** `token:`; Prowlarr prefixes it).
- JSON-RPC (manual): `http://localhost:6800/jsonrpc`, token `token:${ARIA2_SECRET}` (from `.env`).
- Paths: `dir=/downloads/aria2/complete`.
- Image is built locally from `aria2/` (custom entrypoint). Rebuild with `docker compose build aria2 && docker compose up -d aria2` after config changes.

## SABnzbd
- Web: `http://localhost:8080`.
- Paths: `download_dir=/downloads/sabnzbd/incomplete`, `complete_dir=/downloads/sabnzbd/complete` in `/var/mnt/fast8tb/config/sabnzbd/sabnzbd.ini`.
- API key stored in that ini; not committed.

## Prowlarr wiring
- Current download clients: SABnzbd (category `tv`), Transmission, Aria2.
- Aria2 settings: host `aria2`, port `6800`, rpcPath `/rpc`, secret **without** `token:` (Prowlarr adds it).

## Indexers present in Prowlarr (names and bases)
- NZBgeek – https://api.nzbgeek.info
- NZBFinder – https://nzbfinder.ws
- NZB.su – https://api.nzb.su
- NZBPlanet – https://api.nzbplanet.net
- Nyaa – https://nyaa.si (Cardigann)
(API keys live inside the Prowlarr DB; rotate and keep out of git.)

## Housekeeping
- `.env` is the single runtime env file; `.env.example` is the template. Keep secrets out of git.
- Legacy `/var/mnt/fast8tb/Local/Media/SabNzbd/...` removed; top-level legacy download dirs under `/var/mnt/fast8tb/Local/downloads` removed.
