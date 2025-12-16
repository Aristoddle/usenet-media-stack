# Past Agent Notes (Context for New Agents)
Last updated: 2025-12-16

## Current Truth (from AGENTS.md, still valid)
- Supported full stack runtime: **rootful Docker Engine + Docker Compose v2**.
- Podman: **not supported for the full stack**; only allowable for scoped/light services if explicitly documented.
- Validated services to date: **7/23 working** → see `docs/SERVICES.md`. README/ badges claiming 22/23 are outdated.
- Swarm: legacy/experimental (compose v3 subset via `docker stack deploy`). k3s is future path, not implemented.
- Paths: many docs and `.env.example` use machine-specific paths (e.g., `/run/media/deck/...`, `/home/deck/...`). Need portable defaults (`/srv/usenet/...` or `$HOME/.local/share/...`).
- Website: published site is stale (Roadmap last updated Jan 2025) and does not match repo docs.
- Security: Cloudflare API token committed in docs/scripts → treat as compromised; must be rotated, scrubbed from history, and secret scanning added.

## Live System Snapshot (2025-12-16, rootful Docker)
- `docker compose` project: `usenet-media-stack` (sources: `docker-compose.yml` + `docker-compose.override.yml`).
- Services up (24m): jellyfin, prowlarr, portainer, sonarr, radarr, overseerr, bazarr, whisparr, sabnzbd, tdarr, transmission, komga, komf, mylar, stash, calibre, audiobookshelf, netdata (healthy), samba (healthy), recyclarr.
- Failing/unhealthy: 
  - `nfs-server` restarting: kernel module `nfs` missing on host (needs `modprobe nfs` or host support).
  - `usenet-docs` unhealthy: nginx serving empty `/usr/share/nginx/html` → 403; likely missing built docs volume or wrong working dir.
- Komga: starts cleanly on 25600 (published 8081). Komf: up on 8085. No errors seen in tails.
- Sonarr/Radarr: running but warn “No available indexers” (Prowlarr not wired/configured).
- Ports published on host (selected): Jellyfin 8096, Prowlarr 9696, Sonarr 8989, Radarr 7878, Bazarr 6767, Overseerr 5055, Tdarr 8265-8266, Komga 8081->25600, Komf 8085, Portainer 9000, Netdata 19999, Sabnzbd 8080, Transmission 9093.

## High-Priority Actions (unchanged, still top of queue)
1) **Security:** Rotate/revoke Cloudflare token; scrub from repo/history; add secret scanning (gitleaks + GH secret scanning/pre-commit); remove plaintext tokens from docs/scripts.
2) **Single source of truth:** Align README badges and copy to `docs/SERVICES.md` (7/23). Remove “22/23” and stale test badges.
3) **Runtime support policy:** Document tiering in README/COMPATIBILITY/AGENTS.
   - Tier 1: Docker Engine + Compose v2 (full stack).
   - Tier 2 (scoped): Podman only for explicitly supported subset (e.g., reading/Komga).
   - Swarm: legacy/experimental; k3s: future target.
4) **Paths/portability:** Update `.env.example` and onboarding docs to portable defaults; remove personal paths.
5) **Docs site:** Fix CI/secrets and redeploy so live site matches repo; flag stale pages.

## Additional Immediate Fixes from Live Snapshot
- Fix `nfs-server` container: load host `nfs` kernel module or disable/remove service if not needed on this host.
- Fix `usenet-docs` container: mount built docs into nginx root or point to correct dist path; rebuild docs if missing.
- Wire indexers: configure Prowlarr and hook Sonarr/Radarr to clear “No available indexers” warnings.

## Security Incidents / Secret Locations (must scrub)
- Cloudflare API token present in: `DEPLOYMENT.md`, `scripts/deploy-live.sh`, `scripts/cloudflare-deploy.sh`.
- Usenet/indexer credentials exposed in `CREDENTIALS_INVENTORY.md`.
- `docs/SECURITY.md` already flags hardcoded credentials; repo must remain private until cleaned.

## Files to Read First
- `AGENTS.md` (truth state & priorities).
- `docs/SERVICES.md` (authoritative service status 7/23).
- `docs/vnext-cluster-plan.md` (orchestration/storage plan, mount gating, SELinux notes).
- `docs/COMPATIBILITY.md` (runtime matrix).
- `.env.example` (needs portable paths).
- Compose files: `docker-compose.yml`, `docker-compose.override.yml`, `docker-compose.swarm*.yml`, `docker-compose.komga.yml`.
- Deploy docs & scripts containing tokens: `DEPLOYMENT.md`, `scripts/deploy-live.sh`, `scripts/cloudflare-deploy.sh`.

## ADRs to Add (still pending)
- ADR-0001 Runtime & Orchestration Strategy: Docker default; Podman scoped; Swarm legacy; k3s future.
- ADR-0002 Storage & Scaling Model: seed node owns storage/control; workers for Tdarr/background; “add compute” = worker capacity, not Plex cluster.
- ADR-0003 Secrets & Deploy Hygiene: no plaintext tokens; CI uses secrets; secret scanning required.

## Podman / Quadlet Guidance
- Avoid `podman generate systemd`; prefer Quadlet or a thin unit running `podman compose up -d` if Podman is retained for scoped services.
- Rootless Swarm unsupported (overlay networking absent). Keep Swarm/k3s rootful.

## Compose / Swarm Notes
- Swarm uses legacy Compose v3 subset (`docker stack deploy`); unsupported fields ignored. Maintain separate swarm-specific files or overlays.
- Keep to v3.9 core (services/volumes/env/binds) for Podman portability where needed.

## Migration / State Notes (Komga/Reading stack)
- Plan remains to migrate Komga/Komf configs from volume to bind mounts with portable paths and mount gating; keep backups/rollback path.
- Use absolute paths with SELinux labels `:Z` on dedicated dirs when needed.

## Post-Reboot Checklist (Bazzite seed)
- Ensure Docker service enabled; user in `docker` group.
- Continue security cleanup and docs alignment after reboot.
- If stopping Podman user services pre-reboot: `systemctl --user stop container-komga.service container-komf.service`.

## What Not to Promise
- No “Plex/Jellyfin cluster” scaling; extra nodes are for worker-able workloads (Tdarr, background jobs) and resilience, not multi-node Plex.
