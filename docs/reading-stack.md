# Reading Stack (Comics, Ebooks, Audiobooks)

## Overview
- **Comics**: Komga + Komf via `docker-compose.komga.yml` (Komga on 8081, Komf on 8085). Point `COMICS_ROOT` at your comics library (e.g., OneDrive). Hourly scans keep metadata fresh.
- **Ebooks**: Calibre + Calibre-Web (post-reboot when Docker is available). Compose definitions live in `docker-compose.reading.yml`.
- **Audiobooks/Podcasts**: Audiobookshelf (same compose file).
- **Kometa**: Optional (Plex-first metadata); config skeleton at `/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml`.

## Paths (OneDrive-backed on fast8tb mount)
- Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- Ebooks (to create): `/mnt/fast8tb/Cloud/OneDrive/Books`
- Audiobooks: `/mnt/fast8tb/Cloud/OneDrive/Audiobooks`
- Podcasts: `/mnt/fast8tb/Cloud/OneDrive/Podcasts`
- Calibre config: `/mnt/fast8tb/Cloud/OneDrive/CalibreConfig`
- Audiobookshelf config: `/mnt/fast8tb/Cloud/OneDrive/AudiobookshelfConfig`
- Kometa config: `/mnt/fast8tb/Cloud/OneDrive/KometaConfig`

## Compose (post-reboot)
- Comics: `docker compose -f docker-compose.komga.yml up -d`
- Calibre/Audiobookshelf: `docker compose -f docker-compose.reading.yml up -d`
- Ports: Komga 8081, Komf 8085, Calibre 18080/18081, Calibre-Web 18083, Audiobookshelf 13378.

## Ordering / Constraints
1. Start Docker, then bring up the reading stack compose files.
2. Komga library path: `/comics` (host `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`). Run a rescan after library is set.
3. Komf handles metadata once Komga is reachable.

## OPDS / Clients
- Komga OPDS: `http://<host>:8081/opds/v1.2` (Panels, Marvin, etc.)
- Calibre-Web OPDS (after bring-up): `http://<host>:18083/opds`
- Audiobookshelf clients: web `http://<host>:13378`, native apps available; supports OPML/Podcast ingest.

## Health / Maintenance
- Consider a nightly systemd user timer to re-rsync OneDrive → Comics once GVFS proves stable.
- Keep `.env.local` updated with indexer/API keys before starting Arr services.
- Snapshot config dirs with restic/borg once services are live (configs live under OneDrive-backed paths above).
