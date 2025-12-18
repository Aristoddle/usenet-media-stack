# Operations Runbook (Bazzite host)

## Daily/quick checks
- `docker ps` to confirm containers are up.
- Komga up: `curl -I http://localhost:8081`.
- Komf up: `curl -I http://localhost:8085`.
- Comics mount: ensure `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` is present and writable.

## Reboot checklist
1) Reboot to apply staged rpm-ostree layer (Docker).
2) Enable Docker daemon: `sudo systemctl enable --now docker`.
3) Add user to docker group: `sudo usermod -aG docker $USER && newgrp docker`.
4) Start stacks:
   - Comics: `docker compose -f docker-compose.komga.yml up -d`
   - Reading stack: `docker compose -f docker-compose.reading.yml up -d`
   - Main: `docker compose up -d`

## Healthchecks to keep/restore
- Bazarr, Overseerr, Jellyfin, Tdarr, Prowlarr: http healthchecks (`curl -f http://localhost:<port>` with 30s interval, 10s timeout, 3 retries) in compose.
- Service constraints: keep storage/performance labels where used (Swarm).

## Storage & paths (host)
- Media root: `/var/mnt/fast8tb/Cloud/OneDrive`
- Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- Ebooks (planned layout): `/var/mnt/fast8tb/Cloud/OneDrive/Books/Ebooks`
- Audiobooks: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`
- Configs: `/var/mnt/fast8tb/Cloud/OneDrive/*Config`
- OneDrive comics source (GVFS): `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`

## Secrets & env
- `.env` (gitignored): Prowlarr/NZB/Usenet provider keys.
- Kometa: `/var/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml` (Plex token/URL).
- Audiobookshelf config lives under its `*Config` dir on the OneDrive-backed disk.

## SOPs
- Restart a single service (Docker): `docker compose restart <service>`.
- Tail logs (Docker): `docker compose logs -f <service>`; (Podman): `podman logs -f <container>`.
- Re-run comics sync manually: use the systemd-run command in `docs/advanced/hot-swap.md`; avoid reboots while it runs.
- Nightly comics sync: after current rsync completes, enable the `rsync-comics.timer` (see Daily/quick checks above).
- Backup configs: tar or restic/borg the `*Config` directories (they’re already on OneDrive for versioning).

## Subtitles & metadata
- Bazarr: connect to Sonarr/Radarr, set subtitle languages/providers, enable post-processing.
- Kometa (optional): only if Plex is enabled; config at `/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml`.
- Indexers: prefer Prowlarr as the single indexer manager; use Jackett only if an indexer is unsupported.

## Incident shortcuts
- Port check: `ss -tlnp | grep 8081` (Komga), `5000` (Kavita), `13378` (Audiobookshelf), main stack ports as usual.
- Disk space: `df -h /var/mnt/fast8tb`.
- GPU check (after Docker reboot): `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi` (if NVIDIA present).
- Prowlarr indexer warnings: if health shows DNS/IPv6 issues, set service `dns: [1.1.1.1, 1.0.0.1]` and disable IPv6 via sysctls in compose, then recreate the container.
