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
5) Compose implementation: standardize on **podman compose** (v4+) with the Docker Compose V2 provider installed (`docker compose` in PATH) and **docker compose v2** on Docker hosts. Avoid the legacy `podman-compose` shim and avoid compose features known to differ (e.g., experimental `secrets` drivers); stick to v3.9 services/volumes/env/binds which both runtimes support. [Red Hat compose guidance](https://www.redhat.com/en/blog/podman-compose-docker-compose) · [podman-compose provider note](https://docs.podman.io/en/v5.6.2/markdown/podman-compose.1.html)

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
- Note: `docker stack deploy` uses the legacy Compose v3 subset; avoid Compose-spec-only features or maintain a swarm-specific override file. [Docker stack deploy](https://docs.docker.com/engine/swarm/stack-deploy/)

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
- Stop service: `systemctl --user stop container-komga.service` (or `podman stop komga`).
- Discover volume name: `podman volume ls` and note the Komga config volume; inspect if needed: `podman volume inspect <VOL>`.
- Backup old volume (create backup dir first): `mkdir -p /srv/komga/backup` (or a user-writable path) then `podman run --rm -v <VOL>:/from -v /srv/komga/backup:/backup alpine sh -c "cd /from && tar cf /backup/komga-config.tar ."`
- Ensure bind paths writable in rootless mode: either use a user-owned path (e.g., `$HOME/.local/share/komga/config` and `/tmp/komga`) or `sudo mkdir -p /srv/komga/{config,tmp,backup} && sudo chown -R $(id -u):$(id -g) /srv/komga`.
- Migrate to bind mounts: `podman run --rm -v <VOL>:/from -v /srv/komga/config:/to alpine sh -c "cd /from && tar cf - . | (cd /to && tar xf -)"` (repeat for `/tmp` if needed). On SELinux hosts keep `:Z` in compose; on non-SELinux hosts it is ignored.
- Update `docker-compose.komga.yml` + `.env` to use bind mounts (`COMICS_ROOT`, `KOMGA_CONFIG=/srv/komga/config`, `KOMGA_TMP=/srv/komga/tmp` or `$HOME/.local/share/...`); recreate with compose (Podman or Docker).
- Verify: login with existing user; libraries present; Komf reaches Komga; scan succeeds; thumbnails intact; check logs for errors.
- Rollback (if needed): stop service, recreate container pointing back to the saved Podman volume or untar the backup into a fresh bind; keep the original volume until stable for several days.

## Mount gating and boot determinism
- Use a compose-based systemd (or Quadlet) user unit with **literal absolute paths** in `RequiresMountsFor=/path/to/mount` (no shell expansion in units) plus an `ExecStartPre` loop that waits for the mount (e.g., 30x5s). If the mount is missing, the unit should fail fast and systemd will retry; once the mount appears, `systemctl --user restart container-komga` succeeds without data loss. If templating is needed, generate the unit from `.env`.
- For Swarm/K8s, ensure shared storage or placement constraints prevent scheduling on nodes without the bind path.

## SELinux portability
- Default to `:Z` on bind mounts; on non-SELinux hosts it is ignored by Docker/Podman. If a host enforces SELinux and the path is shared, use `:z` only when multiple containers share the same content; otherwise keep `:Z`. Avoid applying :Z/:z to broad/shared host paths to prevent unwanted relabeling. Document overrides in `.env.example` or a compose override for SELinux vs non-SELinux hosts.

## Runtime note for k3s
- In k3s the container runtime is containerd; Docker/Podman are for build/push and single-host runs. Build multi-arch images with `docker buildx` and push to GHCR; k3s pulls the right arch automatically.

## Compose portability (Podman vs Docker)
- Tested path: `podman compose` (v4+) and `docker compose v2`.
- Avoid: legacy `podman-compose` python tool; compose features outside v3.9 core (e.g., experimental secrets drivers, swarm-only networking assumptions) when running on Podman.

## Definition of Done (post-reboot)
- Fresh clone + `.env` → `docker compose -f docker-compose.komga.yml up -d` (or `podman compose ...`) succeeds.
- Komga/Komf survive reboot with mounts present; if mounts absent, services do not corrupt state and recover automatically once mounts return.
- Migration validated: existing user login works, libraries present, scan succeeds, Komf enrichment works, thumbnails intact.
- Backup/restore tested once (using the tar backup) on a throwaway path.
