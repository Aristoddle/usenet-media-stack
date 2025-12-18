# First Deployment (Bazzite-focused)

1) **Finish transfers first**
   - Let `rsync-comics` and any other large copies finish. Check with `journalctl --user -u rsync-comics -f`.

2) **Choose runtime**
   - Podman (no reboot): fine for Komga and light services.
   - Docker (needs reboot): after transfers finish, reboot, then
     ```bash
     sudo systemctl enable --now docker
     sudo usermod -aG docker $USER
     newgrp docker
     ```

3) **Config files**
   - Copy `.env.example` → `.env` and add Prowlarr/NZB/SAB creds + `PLEX_CLAIM` (first-time Plex setup).
   - Set `BOOKS_ROOT`, `COMICS_ROOT`, `AUDIOBOOKS_ROOT` to your actual library paths.
   - Kometa config skeleton (if used): `${KOMETA_CONFIG:-/srv/usenet/config/kometa}/config.yml`.

4) **Bring up services**
   - Reading stack (after Docker):
     ```bash
     docker compose -f docker-compose.reading.yml up -d
     ```
     - If Audiobookshelf paths don’t match your host, update the mounts first (current file still uses `/mnt/fast8tb/...`).
   - Main stack (Arr/Plex/etc.):
     ```bash
     docker compose up -d
     ```
   - Podman-only quick start: not recommended; use Docker for the full stack.

5) **Add libraries**
   - Komga: add library pointing to `/comics` (maps to `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`).
   - Audiobookshelf: set library `/audiobooks` → `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`.
   - Kavita: add libraries for `/comics` and `/downloads` (and `/books` once `/Books/Ebooks` is finalized).

6) **OPDS endpoints**
   - Komga: `http://<host>:8081/opds/v1.2`
   - Kavita: `http://<host>:5000/opds`

7) **Health & cleanup**
   - Check containers: `docker ps`.
   - Ensure healthchecks are present for Bazarr/Overseerr/Plex/Tdarr when you bring the main stack up; reapply if missing.

8) **Backup configs**
   - All configs live under OneDrive-backed paths on `/var/mnt/fast8tb/Cloud/OneDrive/*Config`. Snapshot them once services are running.
