# vNext Cluster Plan (PC + Laptops + 6–8 RPi5)

## Assumptions / Non-goals / Invariants
- Content lives outside the stack; the repo must rehydrate “tools, not data” on any host.
- State must be explicit (bind mounts), backed up, and reversible before deletion.
- Boot must converge without babysitting: services wait for mounts, restart safely.
- Security posture may differ by runtime: rootless acceptable for single-host; rootful required for Swarm/k8s nodes.

## TL;DR
- Keep today’s compose setup (Komga/Komf + Arr stack) on Podman/Docker with bind-mounted configs.
- Post-reboot, enable Docker daemon for Swarm/K8s experiments.
- Long-term: prefer **k3s** (lightweight Kubernetes) with PC control-plane, RPis as workers, laptops tainted/ephemeral. [k3s docs](https://docs.k3s.io/)

## Why k3s over Swarm (for this hardware mix)
- Multi-arch & edge-focused: single binary, minimal deps, ARM builds. [k3s docs](https://docs.k3s.io/) · [k3s GitHub](https://github.com/k3s-io/k3s)
- Small control-plane footprint: k3s is positioned for edge/IoT; typical RAM use is markedly lower than full k8s. (Vendor positioning; measure on your hosts.)
- Ecosystem depth (ingress, cert-manager, GitOps) and active velocity vs. Swarm’s slower cadence.
- Swarm still supported (Mirantis committed through 2030) but **rootless Swarm is unsupported** because overlay networking is unavailable in rootless Docker. [Mirantis LTS](https://www.mirantis.com/blog/mirantis-guarantees-long-term-support-for-swarm/) · [Docker rootless limitations](https://docs.docker.com/engine/security/rootless/#known-limitations)

## Near-term steps (before cluster work)
1) Make Komga/Komf runtime-agnostic: bind-mount `/config` and `/tmp`; drive paths via `.env` and `docker-compose.komga.yml`.
2) Keep compose as single source of truth; run with `podman compose` today, `docker compose` after reboot.
3) Post-reboot: enable Docker service + docker group; optional: keep Podman for dev/testing.
4) Stop generating single-container systemd units; prefer Quadlet or a user service that runs `podman compose up -d`. [Podman systemd deprecation](https://docs.podman.io/en/latest/markdown/podman-generate-systemd.1.html)

## Medium-term (k3s bootstrap)
1) Install k3s on the PC (single control-plane).  
2) Join RPi5s as workers; label/taint `arm64` / `low-mem`; fence laptops as “burst-only”.  
3) Storage: NFS share from PC; install NFS CSI and StorageClass. (Avoid distributed storage across RPis unless HA is required.)  
4) Ingress/TLS: ingress-nginx + cert-manager.  
5) Deploy Komga/Komf via Helm/Kustomize; reuse `COMICS_ROOT`, `KOMGA_CONFIG`, `KOMGA_TMP`.  
6) CI/build: `docker buildx bake` multi-arch (amd64/arm64) → GHCR; pull by platform in k3s.

## Swarm fallback (if you choose it)
- Keep compose v3.9 files; add `deploy` blocks and placement constraints.
- Run Swarm only in rootful Docker (rootless Swarm unsupported). [Docker rootless limitations](https://docs.docker.com/engine/security/rootless/#known-limitations)
- If using bind mounts, paths must exist on every node where tasks may land; otherwise pin tasks with placement constraints or use shared storage. [Swarm bind-mount requirement](https://docs.docker.com/engine/swarm/services/#bind-mounts)

## Risks / Mitigations
- Path drift (new disk/NVMe): use `.env` for paths; avoid hardcoded systemd units.
- Transient laptops: taint them; no critical pods scheduled there.
- RPi thermal limits: use low resource requests/limits; keep control-plane off RPis.
- Security: if you need rootless for dev, run rootless Docker/Podman for non-Swarm workloads; keep Swarm/k3s rootful on the PC.

## Next actions to kick off after reboot
- Enable Docker; run compose using bind-mounted configs.  
- Export current Komga Podman volume → host config dir; update compose/systemd to bind mounts.  
- Add `.env.example` with COMICS_ROOT/KOMGA_CONFIG/KOMGA_TMP defaults.  
- Draft k3s install/runbook (PC control-plane, RPi workers).  

## Komga config migration (plan only; do post-reboot)
- Stop service; backup Podman config volume (export or tar).
- Copy/export volume into a host path (e.g., `/srv/komga/config`, `/srv/komga/tmp`); set SELinux labels (`:Z`).
- Update `docker-compose.komga.yml` + `.env` to use bind mounts; use compose (Podman or Docker) to recreate.
- Verify: login with existing user; libraries present; Komf can reach Komga; scan succeeds; thumbnails intact.
- Keep old volume until verified; only then remove it.
