---
layout: page
title: "Beppe's Arr Stack — current state (Dec 16, 2025)"
---

# Beppe's Arr Stack

> Truthful status page for the local homelab stack. Docker Engine + Compose v2 only; Podman/Swarm are experimental. Target: Bazzite seed node with `/var/mnt/fast8tb` storage.

::: warning Active job — **do not restart / move comics**
rclone copy `onedrive_personal:Books/Comics → /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` is still running (PID 131980). Let it finish before restarting the stack or touching comics paths.
:::

## Status at a glance
- Core automation: Prowlarr → Sonarr / Radarr / Whisparr / Lidarr; SABnzbd (NZB) + Transmission via gluetun/Mullvad (torrent).
- Comics/books: Komga + Komf (RW) + Mylar; temp library path `/mnt/fast8tb/Cloud/OneDrive/Comics` until mirror completes.
- Ops/visibility: Overseerr, Bazarr, Portainer, Netdata. Clickable URLs: [Local endpoints](/local-endpoints/).
- Docs deploy: GitHub Actions → Cloudflare Pages is healthy.

## Known issues / in flight
- Paths not yet normalized; canonical targets will be `/var/mnt/fast8tb/{config,Local/downloads,Local/media,Cloud/OneDrive/Books/Comics}` after the copy.
- Traefik not wired; services are loopback-only today.
- nfs-server failing (kernel module missing). usenet-docs unused (nginx 403) — remove or fix.
- Secrets: CF token rotated; history scrub + gitleaks/pre-commit still needed. Keep .env in 1Password only.

## Run the stack (safe today)
```bash
# prerequisites: Docker Engine + Compose v2; .env from .env.example
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# Core services (no full restart)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  up -d prowlarr sonarr radarr whisparr lidarr sabnzbd komga komf mylar

# Add VPN + Transmission (needs MULLVAD_ACCOUNT in .env)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.vpn-mullvad.yml \
  up -d gluetun transmission
```

## After the rclone copy completes
- Point comics path to `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` in Komga/Komf/Mylar; remove `/Comics` and `/Comics_mirror` dupes; rescan Komga.
- Apply Traefik labels/DOMAIN and wire HTTPS routes (keep loopback fallback).
- Secret scrub (git filter-repo), add gitleaks + pre-commit, rotate any lingering tokens.
- Normalize binds in compose/.env to canonical roots and add mount-gating.

## Quick links
- [Local endpoints](/local-endpoints/) — clickable localhost URLs for every service
- [Services status](/SERVICES/) — single source of truth (currently 7/23 validated)
- [Getting started](/getting-started/) — minimal bootstrap notes
- [Ops runbook](/ops-runbook/) — day-2 operations

*This page is intentionally sober and current; marketing fluff removed so we can see the real state of the stack.*
