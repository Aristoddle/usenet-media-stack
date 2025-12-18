# Operations Runbook (Bazzite host)

## Daily/quick checks
- `sudo docker ps` (or ensure `newgrp docker` after adding user to docker group) to confirm containers are up.
- Komga up: `curl -I http://localhost:8081`.
- Komf up: `curl -I http://localhost:8085`.
- Comics mount: ensure `${COMICS_ROOT}` is present and writable (example: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`).

## Reboot checklist
1) Reboot to apply staged rpm-ostree layer (Docker).
2) Enable Docker daemon: `sudo systemctl enable --now docker`.
3) Add user to docker group: `sudo usermod -aG docker $USER && newgrp docker`.
4) Start stacks (preferred: systemd units):
   - Main stack: `sudo systemctl enable --now media-stack.service`
   - Reading stack: `sudo systemctl enable --now media-reading-stack.service`
   - Comics-only (optional): `docker compose -f docker-compose.komga.yml up -d`
   - Note: systemd units set `COMPOSE_PROJECT_NAME=media-main` and `media-reading` to prevent `--remove-orphans`
     from tearing down the other stack.

## Healthchecks to keep/restore
- Bazarr, Overseerr, Plex, Tdarr, Prowlarr: http healthchecks (`curl -f http://localhost:<port>` with 30s interval, 10s timeout, 3 retries) in compose.
- Service constraints: keep storage/performance labels where used (Swarm).

## Storage & paths (host)
- Media root: `${MEDIA_ROOT}` (example: `/var/mnt/fast8tb/Local/media`)
- Books root: `${BOOKS_ROOT}` (example: `/var/mnt/fast8tb/Cloud/OneDrive/Books`)
- Comics: `${COMICS_ROOT}`
- Ebooks: `${EBOOKS_ROOT}`
- Audiobooks: `${AUDIOBOOKS_ROOT}`
- Configs: `${CONFIG_ROOT}` (plus `${AUDIOBOOKSHELF_CONFIG}` and `${KOMETA_CONFIG}` if used)
- OneDrive comics source (GVFS): `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`

## Secrets & env
- `.env` (gitignored): Prowlarr/NZB/Usenet provider keys.
- `.env`: `PLEX_CLAIM` for first-time Plex setup.
- Kometa: `${KOMETA_CONFIG}/config.yml` (Plex token/URL).
- Audiobookshelf config lives under its `*Config` dir on the OneDrive-backed disk.

## Plex clients
- **Plexamp** for audio/music listening.
- **Plex HTPC** for TVs/HTPC setups; Smart TV apps for living room devices.

## SOPs
- Restart a single service (Docker): `docker compose restart <service>`.
- Tail logs (Docker): `docker compose logs -f <service>`; (Podman): `podman logs -f <container>`.
- Re-run comics sync manually: use the systemd-run command in `docs/advanced/hot-swap.md`; avoid reboots while it runs.
- Nightly comics sync: after current rsync completes, enable the `rsync-comics.timer` (see Daily/quick checks above).
- Backup configs: tar or restic/borg the `*Config` directories (they’re already on OneDrive for versioning).

## Subtitles & metadata
- Bazarr: connect to Sonarr/Radarr, set subtitle languages/providers, enable post-processing.
- Kometa (optional): only if Plex is enabled; config at `${KOMETA_CONFIG}/config.yml`.
- Indexers: prefer Prowlarr as the single indexer manager; use Jackett only if an indexer is unsupported.

## Incident shortcuts
- Port check: `ss -tlnp | grep 8081` (Komga), `5000` (Kavita), `13378` (Audiobookshelf), main stack ports as usual.
- Disk space: `df -h ${MEDIA_ROOT}` (example: `/var/mnt/fast8tb/Local/media`).
- GPU check (after Docker reboot): `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi` (if NVIDIA present).
- Prowlarr indexer warnings: DNS/IPv6 tweaks are now centralized via the compose `x-network-tweaks` anchor (applied to all services). If warnings persist, recreate the affected container.
