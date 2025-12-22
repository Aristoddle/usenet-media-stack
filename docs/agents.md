# Agents Guide (Truthful State & Priorities)

## Current Truth (2025-12-18)
- Supported runtime (full stack): **rootful Docker Engine + Docker Compose v2**.
- Podman: **not supported for the full stack** (privileged/low ports, docker.sock consumers, Swarm assumptions). OK only for scoped/light services if explicitly noted.
- Validated services: **see `docs/SERVICES.md`** (single source of truth). Readarr and Calibre are dropped to avoid drift.
- Cloudflare: API token is present in docs/scripts → treat as compromised; must be rotated and scrubbed from history.
- Paths: many docs/examples use machine-specific paths (`/run/media/deck/...`). `.env.example` also uses non-portable defaults.
- Website: published site is stale (Roadmap last updated Jan 2025) and does not reflect current docs.
- Swarm files exist; `docker stack deploy` uses legacy Compose v3 subset. k3s is the proposed future, but not implemented.

## High-Priority Actions (do first)
1) **Security:** Rotate/revoke Cloudflare token, scrub from repo/history, add secret scanning (gitleaks + GH secret scan/pre-commit). Remove plaintext tokens from docs/scripts.
2) **Single source of truth for service status:** Make README/docs badges pull from `docs/SERVICES.md` (7/23). Stop dual claims.
3) **Runtime support policy:** Document tiering in COMPATIBILITY.md/README:
   - Tier 1: Docker Engine + Compose v2 (full stack).
   - Tier 2 (scoped): Podman only for the reading/Komga stack if explicitly supported.
   - Swarm: legacy/experimental; k3s: future target for selected workloads.
4) **Paths/portability:** Update `.env.example` and docs to use portable defaults (`/srv/usenet/...` or `$HOME/.local/share/...`); remove personal paths from onboarding docs.
5) **Docs site:** Fix CI/secrets and redeploy so the live site matches repo docs; remove/flag stale pages.

## Near-Term Engineering Tasks
- Compose structure: split or clearly scope `compose.singlehost.yml` vs `compose.swarm.yml`; note Swarm’s v3 subset. Keep Docker as canonical; Podman only for scoped subset.
- Mount gating & bind state: plan to bind-mount configs (e.g., Komga) with absolute paths and mount gating in systemd/Quadlet if used.
- Quadlet: if we keep Podman for any services, prefer Quadlet or a thin `podman compose up -d` unit (no `podman generate systemd` long term).
- ADRs to add:
  - ADR-0001 Runtime & Orchestration Strategy (Docker default, Podman scoped, Swarm legacy, k3s future).
  - ADR-0002 Storage & Scaling Model (seed node owns storage/control; workers for Tdarr/background; “add compute” means worker capacity, not “Plex cluster”).
- Secrets hygiene: pre-commit gitleaks; ensure GH Actions uses secrets, not inline tokens.

## Longer-Term (k3s path)
- Seed node = control-plane + storage; workers = RPis/extra PCs for worker-able workloads (e.g., Tdarr).
- Storage v1: NFS from seed node; avoid Ceph/Longhorn until there’s a hard HA need.
- Don’t promise “Plex cluster”; only distribute workloads that can be replicated.

## Definitions / Assumptions
- Tools, not data: repo rehydrates services; media lives outside.
- Immutable-ish host (Bazzite seed): prefer minimal host drift; Docker is layered via rpm-ostree and requires reboot to activate.
- Rootless Swarm is unsupported (overlay networking not available in rootless Docker).

## Immediate Next Steps (queue after reboot)
- Enable Docker service + docker group on Bazzite; confirm Compose works.
- Rotate CF token, purge from history, add secret scanning, update docs to use secrets only.
- Align README/service counts with `docs/SERVICES.md`.
- Fix `.env.example` paths to portable defaults.
- Redeploy docs site with current `docs/`.
