# Installation

## Runtime matrix (pick the row that matches your host)
| Host | Container runtime | Status today | What to do |
|------|-------------------|--------------|------------|
| Bazzite (immutable, SteamOS/Deck) | **Podman rootless** (default) | Already available | Use Podman now; keep host clean. |
| Bazzite (needs Swarm/Compose v2) | Docker (moby-engine) | **Staged** but inactive until reboot | After other transfers finish: reboot, `sudo systemctl enable --now docker && sudo usermod -aG docker $USER && newgrp docker`. |
| Generic Linux | Docker + Compose v2 | Install via distro packages or Docker CE | Ensure `docker compose version` works. |
| Minimal / no daemon | Podman rootless | Use `podman compose` equivalents | Some compose v2 features may differ. |

**Don’t reboot yet** if long rsync/transfers are running (e.g., comics sync). Finish those first.

## Prerequisites
- 8–16 GB RAM (more helps indexing/transcoding)
- Storage mounted and writable (see paths below)
- For Docker: working `docker compose version`
- For Podman: `podman --version` and `podman info --debug`

## Paths (used by the stack)
- Media root: `/mnt/fast8tb/Cloud/OneDrive`
  - Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
  - Ebooks: `/mnt/fast8tb/Cloud/OneDrive/Books`
  - Audiobooks: `/mnt/fast8tb/Cloud/OneDrive/Audiobooks`
  - Configs: `/mnt/fast8tb/Cloud/OneDrive/*Config`
- OneDrive source (GVFS): `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`

## Clone and configure
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
cp .env.example .env.local   # fill in your API keys (Prowlarr/NZBs, etc.)
```

## First bring-up (after choosing runtime)
- **Podman (Bazzite, now):** Comics only: `podman compose -f docker-compose.komga.yml up -d` (Komga+Komf). Other reading services: `podman compose -f docker-compose.reading.yml up -d` post-reboot if desired.
- **Docker (post-reboot):** `docker compose -f docker-compose.komga.yml up -d` (comics), plus `docker compose -f docker-compose.reading.yml up -d` (Calibre/Audiobookshelf), then `docker compose up -d` for the main stack.

## Verify
- Komga: `http://localhost:8081` (after comics sync, add library `/comics`).
- Reading stack (after Docker): Calibre `:18080/18081`, Calibre-Web `:18083`, Audiobookshelf `:13378`.

## Notes on OneDrive comics sync
- Active user service: `rsync-comics.service` (systemd-run). Monitor: `journalctl --user -u rsync-comics -f`.
- Do **not** reboot until that job and other transfers finish.
