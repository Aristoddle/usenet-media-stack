# Reading Stack (Comics, Ebooks, Audiobooks)

## Overview
- **Comics**: Komga + Komf via `docker-compose.komga.yml` (Komga on 8081, Komf on 8085; UI title shows **Komelia**). Point `COMICS_ROOT` at your comics library (e.g., OneDrive). Hourly scans keep metadata fresh.
- **Ebooks**: Kavita (in the main compose stack). Canonical path will be `/Books/Ebooks` once legacy folders are merged.
- **Audiobooks**: Audiobookshelf via `docker-compose.reading.yml`.
- **Podcasts**: Optional — add a `/Books/Podcasts` mount only when you decide on a canonical path.
- **Kometa**: Optional (Plex-first metadata); config at `${KOMETA_CONFIG:-/srv/usenet/config/kometa}/config.yml`.

## Paths (set via `.env`)
- `BOOKS_ROOT` (default `/srv/usenet/books`)
- `COMICS_ROOT` (default `/srv/usenet/books/Comics`)
- `EBOOKS_ROOT` (default `/srv/usenet/books/eBooks`)
- `AUDIOBOOKS_ROOT` (default `/srv/usenet/books/Audiobooks`)
- `PODCASTS_ROOT` (default `/srv/usenet/books/Podcasts`)
- `AUDIOBOOKSHELF_CONFIG` (default `/srv/usenet/config/audiobookshelf`)
- `KOMETA_CONFIG` (if used; recommend `/srv/usenet/config/kometa`)

Example (fast8tb + OneDrive):
- Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- Ebooks: `/var/mnt/fast8tb/Cloud/OneDrive/Books/eBooks`
- Audiobooks: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`
- Podcasts: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Podcasts`

> Note: ensure your `.env` paths match your host before bringing up the reading stack.

## Compose (post-reboot)
- Comics: `docker compose -f docker-compose.komga.yml up -d`
- Audiobookshelf: `docker compose -f docker-compose.reading.yml up -d`
- Ports: Komga 8081, Komf 8085, Kavita 5000, Audiobookshelf 13378.

## Ordering / Constraints
1. Start Docker, then bring up the reading stack compose files.
2. Komga library path: `/comics` (host `${COMICS_ROOT}`). Run a rescan after library is set.
3. Komf handles metadata once Komga is reachable.
4. Kavita library paths should follow the finalized `/Books/Ebooks` layout.
5. Kavita uses the official image; config bind is `${CONFIG_ROOT}/kavita` → `/kavita/config`.
5. Books schema: see `docs/BOOKS_SCHEMA_SPECIFICATION.md`.

## OPDS / Clients
- Komga OPDS: `http://<host>:8081/opds/v1.2` (Panels, Marvin, etc.)
- Kavita OPDS: `http://<host>:5000/opds`
- Audiobookshelf clients: web `http://<host>:13378`, native apps available; supports OPML/Podcast ingest.

## Health / Maintenance
- Consider a nightly systemd user timer to re-rsync OneDrive → Comics once GVFS proves stable.
- Keep `.env` updated with indexer/API keys before starting Arr services.
- Snapshot config dirs with restic/borg once services are live (configs live under OneDrive-backed paths above).
