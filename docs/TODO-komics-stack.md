# Komics Stack TODO (Komga + OneDrive + optional Kometa)

## Current state
- Komga running via rootless Podman on `http://localhost:8081` (maps to internal 25600).
- OneDrive Comics mounted via GVFS at `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`.
- rsync user transient unit `rsync-comics.service` is actively syncing to `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics/`.
- Docker Engine is staged but inactive until reboot; only Podman available right now.

## Immediate tasks (no reboot required)
- Let `rsync-comics` finish; monitor with `journalctl --user -u rsync-comics -f`.
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
- Note: Kometa is designed for Plex (and Jellyfin beta); it cannot manage Komga directly. Use only if Plex/Jellyfin is in the stack.
- Restore/keep healthchecks and storage constraints in compose (Bazarr/Overseerr/Jellyfin/Tdarr) when bringing the stack up.

## Nice-to-haves
- Create a systemd user timer for nightly rsync from OneDrive → Comics once GVFS stability is confirmed.
- Add Panels/OPDS instructions to docs after Komga library is indexed: Panels URL `http://<host>:8081/opds/v1.2`.
- Add NZBGeek/Prowlarr keys to `.env.local` (gitignored) before starting the Arr services.
