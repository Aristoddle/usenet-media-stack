# Komics Stack TODO (Komga + OneDrive + optional Kometa)

## Current state
- Komga running in Docker (rootful) at `http://localhost:8081` (maps to internal 25600).
- Comics root: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` (rclone copy complete).
- Docker Engine is active (gluetun/transmission via compose).

## Immediate tasks
- Ensure Komga/Komf/Mylar libraries point to `/comics` (host bind `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`); run a rescan.
- Review `config.yml` skeleton for Kometa at `/var/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml` and fill Plex token/URL if you plan to run Kometa.

## Post-reboot tasks (Docker needed)
- Enable Docker (done): `sudo systemctl enable --now docker && sudo usermod -aG docker $USER && newgrp docker`.
- Add Kometa service to compose/swarm (official image recommended):
  ```yaml
  kometa:
    image: kometateam/kometa:latest
    container_name: kometa
    user: "1000:1000"
    environment:
      - TZ=Etc/UTC
      - KOMETA_TIME=03:00
    volumes:
      - /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics:/media:ro
      - /var/mnt/fast8tb/Cloud/OneDrive/KometaConfig:/config
    restart: unless-stopped
  ```
- Note: Kometa is designed for Plex (and Jellyfin beta); it cannot manage Komga directly. We are not planning Jellyfin; Kometa is optional for Plex-only use.
- Restore/keep healthchecks and storage constraints in compose (Bazarr/Overseerr/Tdarr) when bringing the stack up.

### Additional services to add after reboot
- Audiobookshelf for audiobooks/podcasts; point it at `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks` (create after initial sync).
- Ebooks are handled by Kavita in the main compose stack; finalize `/Books/Ebooks` layout before adding libraries.

See `docker-compose.reading.yml` for the Audiobookshelf definition (ports shifted to avoid Komga collisions).

### Documentation improvements (queued)
- Add GVFS/rsync note to `docs/advanced/hot-swap.md`.
- Add nightly rsync timer templates (done): see `scripts/rsync-comics.service` and `.timer`; enable after current transfers.

### Documentation improvements (done)
- Nav links for Reading Stack and Komics TODO in `docs/.vitepress/config.js`.
- OPDS/reading-stack cards in `docs/free-media.md`.
- Runtime matrix + OneDrive comics callouts in `docs/getting-started/installation.md` and `docs/getting-started/first-deployment.md`.
- Storage/Paths table added in `docs/architecture/index.md` (no separate storage doc).
- Operations Runbook (`docs/ops-runbook.md`) covering healthchecks, rsync, reboot checklist.
- Secrets/env page for `.env` (indexer/API keys).

## Nice-to-haves
- Create a systemd user timer for nightly rsync from OneDrive → Comics once GVFS stability is confirmed.
- Add Panels/OPDS instructions to docs after Komga library is indexed: Panels URL `http://<host>:8081/opds/v1.2`.
- Add NZBGeek/Prowlarr keys to `.env` (gitignored) before starting the Arr services.
