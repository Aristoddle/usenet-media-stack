# Komics Stack TODO (Komga + OneDrive + optional Kometa)

## Current state
- Komga running in Docker (rootful) at `http://localhost:8081` (maps to internal 25600).
- Komf (Komelia UI) running at `http://localhost:8085`, linked to Komga.
- Kavita running at `http://localhost:5000` (official image `jvmilazz0/kavita`).
- Suwayomi running at `http://localhost:4567` (Tachidesk server; manga downloads to `/comics/Manga`).
  - Setup steps: `docs/suwayomi-setup.md`.
- Comics root: `${COMICS_ROOT}` (example: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`).
- Docker Engine is active; stack is running via compose (Transmission direct, no VPN).

## Immediate tasks
- Triage Komga corrupt archives list (`/tmp/komga-zip-errors.txt`) and re-download/repair broken CBZs.
  - **Blue Box** volumes with ZipException: v02, v04, v05, v06, v07, v08, v09, v11, v12, v13, v14, v16, v17, v18.
  - Detailed list tracked in `docs/komga-corrupt-cbz.md`.
  - Use `scripts/komga-corrupt-scan.sh docs/komga-corrupt-cbz.md` to validate or quarantine.

## Post-reboot tasks (Docker needed)
- Kometa (optional, not shipped in compose): if you enable it, set `${KOMETA_CONFIG}` and `${COMICS_ROOT}`.
- Review healthchecks in compose when bringing the stack up.

## Nice-to-haves
- Create a systemd user timer for nightly rsync from OneDrive → Comics.
- Add Panels/OPDS instructions: Panels URL `http://<host>:8081/opds/v1.2`.
