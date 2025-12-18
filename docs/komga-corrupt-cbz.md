# Komga Corrupt CBZ Report

Generated: 18Dec25 @ 06:28:59 -0500 (rerun `scripts/komga-corrupt-scan.sh docs/komga-corrupt-cbz.md` after any library changes)
Validated: 18Dec25 @ 13:12:56 -0500 (script reported all listed files OK; Komga still logs errors → likely real corruption despite zip validation)
Quarantined: 18Dec25 @ 13:14:12 -0500 (all listed files moved to /var/mnt/fast8tb/Local/quarantine/komga; Komga library now missing these until replaced)

Source: Komga task logs (ZipException/EOFException) mapped to Komga DB book URLs.

## Affected files (last scan)
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v01 (2022) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v02 (2023) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v03 (2023) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v04 (2023) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v05 (2023) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v06 (2023) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v07 (2023) (Digital) (1r0n) (f).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v08 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v09 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v10 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v11 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v12 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v13 (2024) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v14 (2025) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v16 (2025) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v17 (2025) (Digital) (1r0n).cbz
- /comics/Blue Box (Viz) [EN]/1. Volumes/Blue Box v18 (2025) (Digital) (1r0n).cbz
- /comics/Sand Land (Viz) [EN]/1. Volumes/Sand Land (2003) (Digital) (BlurPixel-Empire).cbr

## Notes
- Komga is throwing ZipException/EOFException during hash page tasks.
- A Python zip validation pass may still report OK even when Komga errors persist; treat Komga as the source of truth.

## Suggested actions
- Re-download/repair the listed CBZs from your preferred source.
- Optionally quarantine the listed files (see script below).
- Re-run Komga library scan after repairs:
  - `curl -u <user>:<pass> -X POST http://localhost:8081/api/v1/libraries/<id>/scan`

## Optional validation/quarantine script
- Validate the listed files (non-destructive):
  - `scripts/komga-corrupt-scan.sh docs/komga-corrupt-cbz.md`
- Quarantine the listed files:
  - `QUARANTINE_DIR=/var/mnt/fast8tb/Local/quarantine DO_QUARANTINE=1 scripts/komga-corrupt-scan.sh docs/komga-corrupt-cbz.md`
