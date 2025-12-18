# Komga + Komf Quickstart (Comics/OPDS)

This project ships a reusable compose file to stand up Komga (library + OPDS) and Komf (metadata enrichment; UI labeled **Komelia**) on any host.

## TL;DR
```bash
cp -r config/komga-example ./config/komga   # optional: seed config
cp -r config/komf-example ./config/komf     # optional: seed config
COMICS_ROOT=/srv/usenet/books/Comics \
CONFIG_ROOT=/srv/usenet/config \
KOMGA_TMP=/srv/usenet/config/komga/tmp \
KOMGA_PORT=8081 \
KOMF_PORT=8085 \
docker compose -f docker-compose.komga.yml up -d
```

Then:
- Komga UI/OPDS: http://localhost:8081  • OPDS: http://localhost:8081/opds/v1.2
- Komf UI (Komelia): http://localhost:8085 (configure providers, point at Komga if not auto-detected)

## Paths & env
- `COMICS_ROOT` (required): path to your comics library (read/write inside the container for shared tooling).
- `CONFIG_ROOT` (default `/srv/usenet/config`): base config path.
- `KOMGA_TMP` (default `/srv/usenet/config/komga/tmp`): temp extraction dir.
- `KOMGA_PORT` (default 8081): host port mapped to Komga’s internal 25600.
- `KOMF_CONFIG` optional override (defaults to `${CONFIG_ROOT}/komf`): Komf application.yml and DB.
- `KOMF_PORT` (default 8085): host port for Komf UI.

## Resource profile
- Host tested on: Ryzen 7 7840HS / 96 GB RAM. Compose sets Komga heap to 4–8 GB and an hourly scan (`KOMGA_LIBRARIES_SCAN_CRON=0 0 * * * *`). Adjust `JAVA_OPTS` if you’re on smaller hardware.

## Podman notes
- Works with `podman compose` for the Komga‑only stack. For long‑running units, prefer Quadlet or a simple `podman compose` systemd unit (avoid `podman generate systemd`).

## Gap reporting
- Use `scripts/komga-gap-report.py`:
  ```bash
  KOMGA_URL=http://localhost:8081 \
  KOMGA_USER=you@example.com \
  KOMGA_PASS=yourpass \
  python3 scripts/komga-gap-report.py > /tmp/komga_gap_report.md
  ```
  The script is read-only and lists missing chapters/volumes inferred from filenames.

## Panels / OPDS
- Panels (iOS/macOS): add OPDS source `http://<host>:8081/opds/v1.2`, auth = your Komga user.

## Backups
- Back up `KOMGA_CONFIG` and `KOMF_CONFIG`; your comics stay in `COMICS_ROOT`.
- Note: Komga’s SQLite tuning may create a file named `database.sqlite?wal_autocheckpoint=1000` in `/config`; that is the active DB file to back up.
