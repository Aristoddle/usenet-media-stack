---
layout: page
title: "BeppeSarr Stack — current state (Dec 16, 2025)"
---

# BeppeSarr Stack

> Truthful status page for the local homelab stack. Docker Engine + Compose v2 only; Podman/Swarm are experimental. Target machine: Bazzite seed node with /var/mnt/fast8tb storage.

## What works right now
- Core automation: Prowlarr → Sonarr/Radarr/Whisparr/Lidarr; SABnzbd (NZB) + Transmission behind Mullvad/gluetun (torrent).
- Comics/books: Komga + Komf (RW) + Mylar (ComicVine key set); library pointing at `/mnt/fast8tb/Cloud/OneDrive/Comics` until the Books/Comics mirror finishes.
- Ops/visibility: Overseerr, Bazarr, Portainer, Netdata. Local endpoints list: [Local endpoints](/local-endpoints/).
- Docs deploy: GitHub Actions → Cloudflare Pages is healthy (deploy.yml fixed).

## Known issues / in-flight work
- rclone copy `onedrive_personal:Books/Comics → /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` is running. **Do not move files or restart the whole stack until it finishes.**
- Paths still inconsistent; canonical targets will be `/var/mnt/fast8tb/{config,Local/downloads,Local/media,Cloud/OneDrive/Books/Comics}` once the copy is done.
- Traefik/ingress not wired; services are loopback-only today.
- nfs-server service disabled (missing kernel module). usenet-docs container unused (nginx 403) — pending removal/fix.
- Secrets: Cloudflare token rotated but history scrub + gitleaks still to do. Keys live in 1Password; keep .env out of git.

## How to run locally (today)
```bash
# prerequisites: Docker Engine + Compose v2; .env copied from .env.example and filled
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# bring up the core without restarting everything else
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  up -d prowlarr sonarr radarr whisparr lidarr sabnzbd komga komf mylar

# add VPN + Transmission when ready (needs MULLVAD_ACCOUNT in .env)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.vpn-mullvad.yml \
  up -d gluetun transmission
```

## After the rclone copy completes
- Point comics path to `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` in Komga/Komf/Mylar and remove `/Comics` + `/Comics_mirror` dupes.
- Apply Traefik labels/DOMAIN and wire HTTPS routes.
- Run secret scrub (git filter-repo), add gitleaks/pre-commit, rotate any tokens left in history.
- Normalize binds in compose/.env to the canonical roots and add mount-gating.

## Quick links
- [Local endpoints](/local-endpoints/) — clickable localhost URLs for every service
- [Services status](/SERVICES/) — single source of truth (currently 7/23 validated)
- [Getting started](/getting-started/) — minimal bootstrap notes
- [Ops runbook](/ops-runbook/) — day-2 operations

*This page is intentionally sober and current; marketing fluff removed so we can see the real state of the stack.*
