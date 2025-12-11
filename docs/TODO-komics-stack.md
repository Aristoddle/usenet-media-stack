# Komics Stack TODO (Komga + OneDrive + optional Kometa)

## Current state
- Komga running via rootless Podman on `http://localhost:8081` (maps to internal 25600).
- OneDrive Comics mounted via GVFS at `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`.
- rsync user transient unit `rsync-comics.service` is actively syncing to `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics/`.
- Docker Engine is staged but inactive until reboot; only Podman available right now.

## Immediate tasks (no reboot required)
- Let `rsync-comics` finish; monitor with `journalctl --user -u rsync-comics -f`. Hold all reboots until this and other active transfers in other terminals are done.
- After sync completes, in Komga create a library pointing to `/comics` (container mount) and let it index.
- Review `config.yml` skeleton for Kometa at `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/KometaConfig/config.yml` and fill Plex token/URL if you plan to run Kometa.

## Post-reboot tasks (Docker needed)
- Enable Docker: `sudo systemctl enable --now docker && sudo usermod -aG docker $USER && newgrp docker`.
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
      - /run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics:/media:ro
      - /run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/KometaConfig:/config
    restart: unless-stopped
  ```
- Note: Kometa is designed for Plex (and Jellyfin beta); it cannot manage Komga directly. We are not planning Jellyfin; Kometa is optional for Plex-only use.
- Restore/keep healthchecks and storage constraints in compose (Bazarr/Overseerr/Tdarr) when bringing the stack up.

### Additional services to add after reboot
- Calibre (core DB/metadata/conversion) and Calibre-Web (light web UI) for ebooks; mount to the data disk.
- Audiobookshelf for audiobooks/podcasts; point it at `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Audiobooks` (create after initial sync). No Jellyfin/Kavita planned per current preferences.

See `docker-compose.reading.yml` for ready-to-launch definitions (Calibre, Calibre-Web, Audiobookshelf) with ports shifted to avoid Komga collisions.

### Documentation improvements (queued)
- Add nav links for Reading Stack and Komics TODO in `docs/.vitepress/config.js`.
- Add OPDS/reading-stack cards to `docs/free-media.md`.
- Add runtime matrix + OneDrive comics callouts in `docs/getting-started/installation.md` and `docs/getting-started/first-deployment.md`.
- Add GVFS/rsync note to `docs/advanced/hot-swap.md`.
- Add Storage/Paths table in `docs/architecture/storage.md` (or new section) for comics/ebooks/audiobooks/configs.
- Add Operations Runbook (`docs/ops-runbook.md`) covering healthchecks, rsync, reboot checklist.
- Add Secrets/env page for `.env.local` (indexer/API keys).

## Nice-to-haves
- Create a systemd user timer for nightly rsync from OneDrive → Comics once GVFS stability is confirmed.
- Add Panels/OPDS instructions to docs after Komga library is indexed: Panels URL `http://<host>:8081/opds/v1.2`.
- Add NZBGeek/Prowlarr keys to `.env.local` (gitignored) before starting the Arr services.
