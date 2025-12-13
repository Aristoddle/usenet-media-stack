# vNext Cluster Plan (PC + Laptops + 6–8 RPi5)

## TL;DR
- Keep today’s compose setup (Komga/Komf + Arr stack) running on Podman/Docker with bind-mounted configs.
- Post-reboot, enable Docker daemon for Swarm/K8s experiments.
- Long-term: prefer **k3s** (lightweight Kubernetes) with the beefy PC as control-plane, RPis as workers, laptops as tainted/ephemeral nodes. citeturn0search2

## Why k3s over Swarm (for this hardware mix)
- Multi-arch & edge-focused: ARM binaries and small footprint; tested on RPis. citeturn0search2turn0search7
- Resource efficiency on small nodes (RPi5s): k3s shows lowest CPU/RAM use among lightweight distros. citeturn0academia13
- Ecosystem depth (ingress, cert-manager, GitOps) vs. Swarm’s stagnation.
- Swarm still supported (Mirantis guarantees through 2030) but rootless Swarm is unsupported (overlay networking). citeturn0search1turn0search8

## Near-term steps (before cluster work)
1) Make Komga/Komf runtime-agnostic: bind-mount `/config` and `/tmp`; drive paths via `.env` and `docker-compose.komga.yml`.
2) Keep compose as single source of truth; run with `podman compose` today, `docker compose` after reboot.
3) Post-reboot: enable Docker service + docker group; optional: keep Podman for dev/testing.

## Medium-term (k3s bootstrap)
1) Install k3s on the PC (single control-plane).  
2) Join RPi5s as workers; label/taint `arm64` / `low-mem`; fence laptops as “burst-only”.  
3) Storage: NFS share from PC; install NFS CSI and StorageClass. (Avoid distributed storage across RPis unless HA is required.)  
4) Ingress/TLS: ingress-nginx + cert-manager.  
5) Deploy Komga/Komf via Helm/Kustomize; reuse `COMICS_ROOT`, `KOMGA_CONFIG`, `KOMGA_TMP`.  
6) CI/build: `docker buildx bake` multi-arch (amd64/arm64) → GHCR; pull by platform in k3s.

## Swarm fallback (if you choose it)
- Keep compose v3.9 files; add `deploy` blocks and placement constraints.
- Run Swarm only in rootful Docker (rootless Swarm unsupported). citeturn0search8

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
