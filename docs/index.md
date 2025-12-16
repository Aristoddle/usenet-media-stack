---
layout: home
title: "Beppe's Arr Stack"
hero:
  name: "Beppe's Arr Stack"
  text: "Honest, local-first Usenet + torrent homelab"
  tagline: "Docker Engine + Compose v2 • Bazzite seed node • /var/mnt/fast8tb storage"
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Local Endpoints
      link: /local-endpoints/
    - theme: alt
      text: Service Status (7/23)
      link: /SERVICES/
---

## Live status (Dec 16, 2025)

::: warning Active job — **do not restart / move comics**
rclone copy `onedrive_personal:Books/Comics → /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` is running (PID 131980). Let it finish before stack restarts or path changes.
:::

- Core: Prowlarr → Sonarr/Radarr/Whisparr/Lidarr; SABnzbd (NZB) + Transmission via gluetun/Mullvad (torrent).
- Comics/books: Komga + Komf (RW) + Mylar; temp path `/mnt/fast8tb/Cloud/OneDrive/Comics` until mirror completes.
- Ops: Overseerr, Bazarr, Portainer, Netdata. Clickable URLs: [Local endpoints](/local-endpoints/).
- Deploy: GitHub Actions → Cloudflare Pages healthy.
- In flight: Traefik routes (loopback only today); path normalization to `/var/mnt/fast8tb/{config,Local/downloads,Local/media,Cloud/OneDrive/Books/Comics}`; secret scrub (git history + gitleaks); remove/fix nfs-server + usenet-docs.

## Run locally (safe during copy)

```bash
# prerequisites: Docker Engine + Compose v2; .env from .env.example
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# Core services (no full stack restart)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  up -d prowlarr sonarr radarr whisparr lidarr sabnzbd komga komf mylar

# VPN + Transmission (requires MULLVAD_ACCOUNT in .env)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.vpn-mullvad.yml \
  up -d gluetun transmission
```

## After the copy finishes

1) Point comics root to `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` in Komga/Komf/Mylar; remove `/Comics` + `/Comics_mirror`; rescan Komga.
2) Normalize binds/env to canonical roots; add mount-gating; compose up.
3) Add Traefik host rules + DOMAIN; enable HTTPS (keep loopback fallback).
4) Secret hygiene: git filter-repo to purge old CF token; add gitleaks + pre-commit; keep .env in 1Password.

## Quick links

- [Local endpoints](/local-endpoints/) — clickable localhost URLs
- [Services status](/SERVICES/) — single source of truth (7/23 validated)
- [Getting started](/getting-started/) — minimal bootstrap
- [Ops runbook](/ops-runbook/) — day-2 operations

*Lean, truthful, and current so you can see the real state of the stack.*
