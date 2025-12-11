# Reading Stack (Comics, Ebooks, Audiobooks)

## Overview
- **Comics**: Komga (already running on Podman, port 8081). Source sync from OneDrive → `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics` via `rsync-comics` systemd user unit.
- **Ebooks**: Calibre + Calibre-Web planned (post-reboot when Docker is available). Compose definitions live in `docker-compose.reading.yml`.
- **Audiobooks/Podcasts**: Audiobookshelf planned (same compose file).
- **Kometa**: Optional (Plex-first metadata); config skeleton at `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/KometaConfig/config.yml`.

## Paths (OneDrive-backed on Fast_8TB_Ser7)
- Comics: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics`
- Ebooks (to create): `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Books`
- Audiobooks: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Audiobooks`
- Podcasts: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Podcasts`
- Calibre config: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/CalibreConfig`
- Audiobookshelf config: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/AudiobookshelfConfig`
- Kometa config: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/KometaConfig`

## Compose (post-reboot)
- File: `docker-compose.reading.yml`
- Ports: Calibre 18080 (content) / 18081 (noVNC), Calibre-Web 18083, Audiobookshelf 13378.
- Bring up after Docker is enabled: `docker compose -f docker-compose.reading.yml up -d`

## Ordering / Constraints
1. **Do not reboot** until `rsync-comics` and other active transfers are done.
2. After reboot: enable Docker, start reading stack compose, then (optionally) add Kometa and the main arr stack.
3. Add Komga library once comics sync completes (path `/comics` inside container mount).

## OPDS / Clients
- Komga OPDS: `http://<host>:8081/opds/v1.2` (Panels, Marvin, etc.)
- Calibre-Web OPDS (after bring-up): `http://<host>:18083/opds`
- Audiobookshelf clients: web `http://<host>:13378`, native apps available; supports OPML/Podcast ingest.

## Health / Maintenance
- Consider a nightly systemd user timer to re-rsync OneDrive → Comics once GVFS proves stable.
- Keep `.env.local` updated with indexer/API keys before starting Arr services.
- Snapshot config dirs with restic/borg once services are live (configs live under OneDrive-backed paths above).
