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
   - Copy `.env.example` → `.env.local` and add Prowlarr/NZB/SAB creds.
   - Kometa config skeleton: `/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml` (Plex token/URL placeholders).

4) **Bring up services**
   - Reading stack (after Docker):
     ```bash
     docker compose -f docker-compose.reading.yml up -d
     ```
   - Main stack (Arr/Jellyfin/etc.):
     ```bash
     docker compose up -d
     ```
   - Podman-only quick start (Komga already running): skip until Docker is enabled if you need Swarm.

5) **Add libraries**
   - Komga: add library pointing to `/comics` (maps to `/mnt/fast8tb/Cloud/OneDrive/Comics`).
   - Audiobookshelf: set library `/audiobooks` → `/mnt/fast8tb/Cloud/OneDrive/Audiobooks`.
   - Calibre-Web: point to `/books` → `/mnt/fast8tb/Cloud/OneDrive/Books`.

6) **OPDS endpoints**
   - Komga: `http://<host>:8081/opds/v1.2`
   - Calibre-Web: `http://<host>:18083/opds`

7) **Health & cleanup**
   - Check containers: `docker ps` (or `podman ps`).
   - Ensure healthchecks are present for Bazarr/Overseerr/Jellyfin/Tdarr when you bring the main stack up; reapply if missing.

8) **Backup configs**
   - All configs live under OneDrive-backed paths on `/mnt/fast8tb/Cloud/OneDrive/*Config`. Snapshot them once services are running.
