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
- Media root (books): `/var/mnt/fast8tb/Cloud/OneDrive`
  - Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
  - Ebooks (planned layout): `/var/mnt/fast8tb/Cloud/OneDrive/Books/Ebooks`
  - Audiobooks: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`
  - Configs: `/var/mnt/fast8tb/Cloud/OneDrive/*Config`
- Media root (video): `/var/mnt/fast8tb/Local/media`
- OneDrive source (GVFS): `/run/user/1000/gvfs/onedrive:host=gmail.com,user=J3lanzone/Bundles_b896e2bb7ca3447691823a44c4ad6ad7/Books/Comics/`

## Clone and configure
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
cp .env.example .env   # fill in your API keys (Prowlarr/NZBs, etc.)
```

## First bring-up (after choosing runtime)
- **Reading Stack (portable):** `docker compose -f docker-compose.reading.yml up -d` - includes Komga, Kavita, Audiobookshelf, Prowlarr, and portable download clients. Works without external drive pool.
- **Full Stack (with pool):** `docker compose up -d` - adds Plex, Sonarr, Radarr, Tdarr, and pool-dependent services.
- **Smart Start (auto-detect):** `./scripts/smart-start.sh up` - detects available storage and starts appropriate stack.

## Verify
- Komga: `http://localhost:8081` (after comics sync, add library `/comics`).
- Reading stack (after Docker): Audiobookshelf `:13378`.

## Notes on OneDrive comics sync
- Active user service: `rsync-comics.service` (systemd-run). Monitor: `journalctl --user -u rsync-comics -f`.
- Do **not** reboot until that job and other transfers finish.
