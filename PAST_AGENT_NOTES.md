# Past Agent Notes (Context for New Agents)

Last updated: 2025-12-13

## Current Truth
- Runtime (full stack): **rootful Docker Engine + Docker Compose v2** is the supported path.
- Podman: **not supported for the full stack** (privileged/low ports, docker.sock consumers, Swarm assumptions). Allow only for scoped/light services if explicitly documented.
- Validated services: **7/23 working** (see `docs/SERVICES.md`). README claims of “22/23” are outdated and must be aligned.
- Swarm: legacy/experimental cluster mode already in repo; uses legacy Compose v3 subset. k3s is the desired future, not implemented yet.
- Paths are non-portable in places (`/run/media/deck/...`, `.env.example`). Need portable defaults (`/srv/usenet/...` or `$HOME/.local/share/...`).
- Website is stale (roadmap Jan 2025); published site doesn’t match repo docs.
- **Security incident:** Cloudflare API token is committed in docs/scripts → treat as compromised and rotate/scrub from history; add secret scanning.

## High-Priority Actions
1) **Security:** Rotate/revoke Cloudflare token; remove from repo/history (git filter-repo/BFG); add secret scanning (gitleaks + GH secret scanning/pre-commit); remove plaintext secrets from docs/scripts.
2) **Single source of truth for service status:** Align README/badges to `docs/SERVICES.md` (7/23).
3) **Runtime support policy:** Document tiers in COMPATIBILITY/README/AGENTS:
   - Tier 1: Docker Engine + Compose v2 (full stack).
   - Tier 2 (scoped): Podman only for reading/Komga stack if explicitly supported.
   - Swarm = legacy/experimental; k3s = future target for selected workloads.
4) **Paths/portability:** Fix `.env.example` and onboarding docs to use portable defaults; strip personal paths.
5) **Docs site:** Fix CI/secrets and redeploy so live site matches repo; flag/remove stale pages.

## Files to Read First
- `AGENTS.md` (truthful state, priorities)
- `docs/vnext-cluster-plan.md` (orchestration/storage plan, mount gating, SELinux, migration checklist, DoD)
- `docs/SERVICES.md` (authoritative service status: 7/23)
- `docs/DEPLOYMENT.md` and deploy scripts (contain CF token → must be cleaned)
- Compose files: `docker-compose.yml`, `docker-compose.swarm.yml`, `docker-compose.komga.yml`
- `.env.example` (fix paths)
- `COMPATIBILITY.md` (align with support tiers)
- `.github/workflows` (docs deploy; add secret scanning)

## Decisions to Formalize (ADRs suggested)
- ADR-0001 Runtime & Orchestration Strategy: Docker default; Podman scoped; Swarm legacy; k3s future.
- ADR-0002 Storage & Scaling Model: seed node owns storage/control; workers for Tdarr/background jobs; “add compute” means worker capacity, not “Plex cluster.”

## Guidance on Podman/Quadlet
- `podman generate systemd` is deprecated; if keeping Podman for any services, prefer Quadlet or a thin systemd unit running `podman compose up -d`.
- Rootless Swarm is unsupported (overlay networking not available in rootless Docker); Swarm requires rootful Docker.

## Compose/Swarm Notes
- Swarm uses legacy Compose v3 subset via `docker stack deploy`; unsupported fields are ignored. Consider separate `compose.swarm.yml` or overlays.
- Keep Compose v3.9 core features (services/volumes/env/binds); avoid runtime-specific features if aiming for Podman subset.

## Migration/State Notes
- Komga/reading stack: plan to migrate config from Podman volume to bind mounts; add mount gating; keep rollback path and backups.
- Bind mounts should use absolute paths, portable defaults, and SELinux labels (`:Z`) only on dedicated dirs.

## Post-Reboot Checklist (Bazzite seed)
- Activate staged Docker/ulauncher layers by rebooting.
- Enable Docker: `sudo systemctl enable --now docker && sudo usermod -aG docker $USER && newgrp docker`.
- Then continue with security cleanup and docs alignment.

## What Not to Promise
- No “Plex/Jellyfin cluster” scaling; extra nodes are for worker-able workloads (e.g., Tdarr) and resilience, not multi-node Plex.
