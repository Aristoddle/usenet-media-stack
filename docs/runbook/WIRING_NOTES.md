# Wiring Notes (2025-12-16)

**Status:** rclone Comics copy in progress (PID 131980). Path changes deferred until copy completes.

## Service endpoints (inside Docker network)
- Prowlarr: `http://prowlarr:9696`
- Sonarr: `http://sonarr:8989`
- Radarr: `http://radarr:7878`
- Whisparr: `http://whisparr:6969`
- SABnzbd: `http://sabnzbd:8080`
- Traefik: `:80/:443` (dashboard `:8082`) — routes pending labels/DOMAIN.

## API keys (pulled at runtime, not stored here)
- Prowlarr/Sonarr/Radarr: read from `CONFIG_ROOT/<app>/config.xml` → `<ApiKey>`.
- SABnzbd: read from `CONFIG_ROOT/sabnzbd/sabnzbd.ini` → `api_key`.

## API docs / curl refs
- Prowlarr API: https://wiki.servarr.com/prowlarr/api
- Sonarr API: https://wiki.servarr.com/sonarr/api
- Radarr API: https://wiki.servarr.com/radarr/api
- Pattern: `curl -H "X-Api-Key: $KEY" http://localhost:<port>/api/v3/system/status`

## Prowlarr wiring
- Indexers added (Newznab): NZBgeek, NZBFinder, NZB.su, NZBPlanet; Torrents: Nyaa (public).
- Apps:
  - Sonarr: baseUrl `http://sonarr:8989`, prowlarrUrl `http://prowlarr:9696`, syncLevel `fullSync`, categories TV (5000/5070).
  - Radarr: baseUrl `http://radarr:7878`, prowlarrUrl `http://prowlarr:9696`, syncLevel `fullSync`, categories Movies (2000).
  - Whisparr: baseUrl `http://whisparr:6969`, prowlarrUrl `http://prowlarr:9696`, syncLevel `fullSync`, categories XXX (6000). API key auto-read from container config.
  - Mylar: baseUrl `http://mylar:8090`, prowlarrUrl `http://prowlarr:9696`, syncLevel `fullSync`, categories Books/Comics (7030), apiKey set.
  - Lidarr: baseUrl `http://lidarr:8686`, prowlarrUrl `http://prowlarr:9696`, syncLevel `fullSync`, categories Music (3000/3030), apiKey set.
- Komf: running RW; providers enabled (ComicVine, AniList, MangaUpdates, MangaDex) via env; Komga library `/comics` currently RW.
- Notes: Tests via `/api/v1/indexer/{id}/test` require redirect flag and valid appProfileId; current indexers created with `redirect=true`, `appProfileId=1`, `priority=25`.

## SABnzbd wiring
- Categories present: `tv`, `movies`, `audio`, `software`.
- Sonarr download client: host `sabnzbd`, port `8080`, category `tv`.
- Radarr download client: host `sabnzbd`, port `8080`, category `movies`.
- SAB servers (sabnzbd.ini): Newshosting (30 conns, SSL 563), UsenetExpress (20 conns, priority 1), FrugalUsenet (10 conns, priority 2). Rotate creds later.
- Threads/connections: keep within provider limits (≤30 NH, ≤20 UE, ≤10 Frugal); adjust in sabnzbd.ini or UI.

## Transmission + Mullvad VPN (torrents only)
- gluetun + transmission override `docker-compose.vpn-mullvad.yml` (uses Mullvad WireGuard, city default `New York NY`, country `USA`).
- Env vars required (not committed): `MULLVAD_WG_PRIVATE_KEY`, `MULLVAD_WG_ADDRESSES` (IPv4 only, e.g. `10.x.x.x/32`), `MULLVAD_ACCOUNT` (optional, for key refresh).
- Ports: host `9093` → Transmission UI (`/transmission/`), host `51413` TCP/UDP.
- Sonarr download client: Transmission host `gluetun`, port `9091`, urlBase `/transmission/`, category `tv-sonarr`, removeCompleted true.
- Radarr download client: Transmission host `gluetun`, port `9091`, urlBase `/transmission/`, category `radarr`, removeCompleted true.
- Torrent seeding policy: default Transmission (seed ratio 1.0, time 1440m) still in container config; tune after VPN proved stable.
- Note: removed `/gluetun` volume to avoid permission issues; gluetun stores transient data in container FS. Downloads directories `/home/deck/usenet/downloads/{complete,incomplete,watch}` now exist and are owned by UID 1000.
- Secrets: Mullvad WG key/address/account stored in 1Password item “Mullvad” under section `VPN`; local untracked env at `~/.config/usenet-media-stack/mullvad.env` for compose overrides.

## Traefik status
- Container running (compose + `docker-compose.traefik.yml`), CF DNS-01 ready with token from 1Password.
- Dashboard exposed on `:8082` (insecure); routes not yet defined. Needs `DOMAIN` in `.env` and service labels.

## Validation script
- `scripts/validate-services.py` / `scripts/validate-services.zsh`: fetches API keys from configs, hits local endpoints, exits non-zero on failure; wired to `npm test`.

## Next actions after rclone completes
- Merge `/var/mnt/fast8tb/Cloud/OneDrive/Comics` → `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`; remove `Comics_mirror`; repoint Komga/Komf (and Kavita) to single root.
- Normalize paths/mount-gating to `/var/mnt/fast8tb/{config,downloads,media}`; add systemd RequiresMountsFor; restart stack.
- Add Traefik labels + DOMAIN; secure dashboard; verify TLS.
- Run git filter-repo to purge old CF token; add gitleaks/pre-commit; rotate tokens post-scrub.
- Persist wiring snapshots: export redacted Prowlarr indexers/apps JSON and SAB category list after next restart.
