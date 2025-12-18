# Suwayomi (Tachidesk) Setup

## Access
- UI: http://localhost:4567
- Downloads folder (inside container): `/home/suwayomi/.local/share/Tachidesk/downloads`
- Host path: `${COMICS_ROOT}/Manga` (example: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/Manga`)

## Initial setup checklist
1) Open the UI and add sources/extensions you want.
2) Set **download location** to the default downloads path (already mounted).
3) Enable **auto-download** / **auto-update** for followed series.
4) Optional: enable CBZ conversion if available in settings.

## Komga/Kavita scan
- Komga scans hourly via `KOMGA_LIBRARIES_SCAN_CRON` and should ingest new manga automatically.
- You can force a scan manually:
  - `curl -u <user>:<pass> -X POST http://localhost:8081/api/v1/libraries/<id>/scan`

## Notes
- The Suwayomi container runs as uid/gid 1000; host paths are chowned to 1000:1000.
- If Suwayomi fails to start, check permissions on `${COMICS_ROOT}/Manga` and `${CONFIG_ROOT}/suwayomi`.
