---
layout: home
title: "Beppe's Arr Stack"
hero:
  name: "Beppe's Arr Stack"
  text: "Honest, local-first Usenet + torrent homelab"
  tagline: "Docker Engine + Compose v2 • Bazzite seed node • storage paths configurable via .env"
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Local Endpoints
      link: /local-endpoints/
    - theme: alt
      text: Services & Status
      link: /SERVICES/
features:
  - icon: ⚙️
    title: Core automation
    details: Prowlarr → Sonarr/Radarr/Whisparr/Lidarr with SABnzbd + Transmission; Aria2 available via RPC.
  - icon: 📚
    title: Comics & books
    details: Komga + Komf + Mylar + Kavita + Suwayomi; library path set by COMICS_ROOT.
  - icon: 📊
    title: Ops & visibility
    details: Overseerr, Bazarr, Portainer, Netdata, Uptime Kuma monitors preloaded for all services.
  - icon: 🚀
    title: Deploy pipeline
    details: GitHub Actions → Cloudflare Pages (deployed Dec 20, 2025 to beppesarrstack-net).
  - icon: 🌐
    title: Networking
    details: Traefik pending; services exposed on localhost/LAN. Use Samba share for quick file access.
  - icon: 🔒
    title: Secrets hygiene
    details: CF token rotated; keep .env local; add gitleaks/pre-commit for future commits.
---

## Live status (Dec 20, 2025)

- Core: Prowlarr → Sonarr/Radarr/Whisparr/Lidarr; SABnzbd + Transmission; Aria2 RPC. SAB/Prowlarr writes fixed with `:rw,z` binds.
- Comics/books: Komga + Komf + Mylar + Kavita + Suwayomi; library path `${COMICS_ROOT}`.
- Ops: Overseerr, Bazarr, Portainer, Netdata, **Uptime Kuma** (preloaded monitors). Clickable URLs: [Local endpoints](/local-endpoints/).
- Deploy: GitHub Actions → Cloudflare Pages (current site deployed Dec 20, 2025).
- In flight: Traefik host rules/TLS; Plex claim token; Prowlarr RSS/Search toggles per indexer UI; optional Mullvad VPN tests.

## Run locally (safe during copy)

```bash
# prerequisites: Docker Engine + Compose v2; .env from .env.example
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# Core services (no full stack restart)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  up -d prowlarr sonarr radarr whisparr lidarr sabnzbd komga komf kavita mylar

# Optional VPN + Transmission (requires MULLVAD_ACCOUNT in .env)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.vpn-mullvad.yml \
  up -d gluetun transmission
```

## Next steps

1) Traefik host rules + HTTPS (optional; services currently on loopback/LAN).
2) Secret hygiene: rotate/scrub Cloudflare token; add gitleaks + pre-commit; keep .env local.
3) Prowlarr ↔ Aria2: client is registered at /rpc; verify test in UI and keep Transmission/SAB as fallback.
4) Redeploy docs site to reflect current repo docs.

## Quick links

- [Local endpoints](/local-endpoints/) — clickable localhost URLs
- [Services status](/SERVICES/) — single source of truth (snapshot)
- [Getting started](/getting-started/) — minimal bootstrap
- [Ops runbook](/ops-runbook/) — day-2 operations

*Lean, truthful, and current so you can see the real state of the stack.*
