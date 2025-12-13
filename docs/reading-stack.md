# Reading Stack (Comics, Ebooks, Audiobooks)

## Overview
- **Comics**: Komga + Komf via `docker-compose.komga.yml` (Komga on 8081, Komf on 8085). Point `COMICS_ROOT` at your comics library (e.g., OneDrive). Hourly scans keep metadata fresh.
- **Ebooks**: Calibre + Calibre-Web (post-reboot when Docker is available). Compose definitions live in `docker-compose.reading.yml`.
- **Audiobooks/Podcasts**: Audiobookshelf (same compose file).
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
- Comics: `docker compose -f docker-compose.komga.yml up -d` (Docker or Podman)
- Calibre/Audiobookshelf: `docker compose -f docker-compose.reading.yml up -d`
- Ports: Komga 8081, Komf 8085, Calibre 18080/18081, Calibre-Web 18083, Audiobookshelf 13378.

## Ordering / Constraints
1. **Do not reboot** until `rsync-comics` and other active transfers are done.
2. After reboot: enable Docker, start reading stack compose, then (optionally) add Kometa and the main arr stack.
3. Add Komga library once comics sync completes (path `/comics` inside container mount). Komf handles metadata after it sees Komga.

## OPDS / Clients
- Komga OPDS: `http://<host>:8081/opds/v1.2` (Panels, Marvin, etc.)
- Calibre-Web OPDS (after bring-up): `http://<host>:18083/opds`
- Audiobookshelf clients: web `http://<host>:13378`, native apps available; supports OPML/Podcast ingest.

## Health / Maintenance
- Consider a nightly systemd user timer to re-rsync OneDrive → Comics once GVFS proves stable.
- Keep `.env.local` updated with indexer/API keys before starting Arr services.
- Snapshot config dirs with restic/borg once services are live (configs live under OneDrive-backed paths above).
