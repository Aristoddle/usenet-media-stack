# Reading Stack (Comics, Ebooks, Audiobooks)

## Overview
- **Comics**: Komga + Komf via `docker-compose.komga.yml` (Komga on 8081, Komf on 8085; UI title shows **Komelia**). Point `COMICS_ROOT` at your comics library (e.g., OneDrive). Hourly scans keep metadata fresh.
- **Ebooks**: Kavita (in the main compose stack). Canonical path will be `/Books/Ebooks` once legacy folders are merged.
- **Audiobooks**: Audiobookshelf via `docker-compose.reading.yml`.
- **Podcasts**: Optional — add a `/Books/Podcasts` mount only when you decide on a canonical path.
- **Kometa**: Optional (Plex-first metadata); config skeleton at `/var/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml`.

## Paths (OneDrive-backed on fast8tb mount)
- Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- Ebooks (planned): `/var/mnt/fast8tb/Cloud/OneDrive/Books/Ebooks`
- Audiobooks: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`
- Podcasts (optional): `/var/mnt/fast8tb/Cloud/OneDrive/Books/Podcasts` (not created yet)
- Audiobookshelf config: `/var/mnt/fast8tb/Cloud/OneDrive/AudiobookshelfConfig`
- Kometa config: `/var/mnt/fast8tb/Cloud/OneDrive/KometaConfig`

## Compose (post-reboot)
- Comics: `docker compose -f docker-compose.komga.yml up -d`
- Audiobookshelf: `docker compose -f docker-compose.reading.yml up -d`
- Ports: Komga 8081, Komf 8085, Kavita 5000, Audiobookshelf 13378.

## Ordering / Constraints
1. Start Docker, then bring up the reading stack compose files.
2. Komga library path: `/comics` (host `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`). Run a rescan after library is set.
3. Komf handles metadata once Komga is reachable.
4. Kavita library paths should follow the finalized `/Books/Ebooks` layout.
5. Kavita uses the official image; config bind is `/var/mnt/fast8tb/config/kavita` → `/kavita/config`.
5. Books reorg plan: see `docs/books-reorg-plan.md`.

## OPDS / Clients
- Komga OPDS: `http://<host>:8081/opds/v1.2` (Panels, Marvin, etc.)
- Kavita OPDS: `http://<host>:5000/opds`
- Audiobookshelf clients: web `http://<host>:13378`, native apps available; supports OPML/Podcast ingest.

## Health / Maintenance
- Consider a nightly systemd user timer to re-rsync OneDrive → Comics once GVFS proves stable.
- Keep `.env` updated with indexer/API keys before starting Arr services.
- Snapshot config dirs with restic/borg once services are live (configs live under OneDrive-backed paths above).
