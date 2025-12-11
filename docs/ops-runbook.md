# Operations Runbook (Bazzite host)

## Daily/quick checks
- `podman ps` or `docker ps` (post-reboot) to confirm containers are up.
- Komga up: `curl -I http://localhost:8081`.
- Comics sync status: `journalctl --user -u rsync-comics -f` (stop when idle).
 - Nightly sync (optional): copy `scripts/rsync-comics.service` and `.timer` to `~/.config/systemd/user/`, then `systemctl --user enable --now rsync-comics.timer` once current transfers are done.

## Reboot checklist (only after transfers finish)
1) Reboot to apply staged rpm-ostree layer (Docker).
2) Enable Docker daemon: `sudo systemctl enable --now docker`.
3) Add user to docker group: `sudo usermod -aG docker $USER && newgrp docker`.
4) Start stacks:
   - Main: `docker compose up -d`
   - Reading stack: `docker compose -f docker-compose.reading.yml up -d`

## Healthchecks to keep/restore
- Bazarr, Overseerr, Jellyfin, Tdarr, Prowlarr: http healthchecks (`curl -f http://localhost:<port>` with 30s interval, 10s timeout, 3 retries) in compose.
- Service constraints: keep storage/performance labels where used (Swarm).

## Storage & paths (host)
- Media root: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive`
- Comics: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics`
- Ebooks: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Books`
- Audiobooks: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Audiobooks`
- Configs: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/*Config`
- OneDrive comics source (GVFS): `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`

## Secrets & env
- `.env.local` (gitignored): Prowlarr/NZB/Usenet provider keys.
- Kometa: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/KometaConfig/config.yml` (Plex token/URL).
- Calibre/Audiobookshelf configs live under their respective `*Config` dirs on the OneDrive-backed disk.

## SOPs
- Restart a single service (Docker): `docker compose restart <service>`.
- Tail logs (Docker): `docker compose logs -f <service>`; (Podman): `podman logs -f <container>`.
- Re-run comics sync manually: use the systemd-run command in `docs/advanced/hot-swap.md`; avoid reboots while it runs.
- Nightly comics sync: after current rsync completes, enable the `rsync-comics.timer` (see Daily/quick checks above).
- Backup configs: tar or restic/borg the `*Config` directories (they’re already on OneDrive for versioning).

## Incident shortcuts
- Port check: `ss -tlnp | grep 8081` (Komga), `13378` (Audiobookshelf), `18083` (Calibre-Web), main stack ports as usual.
- Disk space: `df -h /run/media/deck/Fast_8TB_Ser7`.
- GPU check (after Docker reboot): `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi` (if NVIDIA present).
