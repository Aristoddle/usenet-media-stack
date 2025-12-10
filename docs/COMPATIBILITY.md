# Compose File Compatibility Matrix

| Scenario | File(s) | Notes |
| --- | --- | --- |
| Single host, Docker Compose | `docker-compose.yml` (+ optional overrides like `docker-compose.optimized.yml`) | Requires Docker Engine (rootful recommended). Paths driven by CONFIG_ROOT/DOWNLOADS_ROOT/MEDIA_ROOT envs. Low ports (139/445, 2049/111) and privileged containers need rootful + SELinux labels (`:z` or `chcon`). |
| Single host, Swarm (bind mounts) | `docker-compose.swarm.yml` + `docker-compose.swarm.local-bind.yml` | Uses overlay networks; create `traefik-public` overlay even if Traefik not deployed. Bind paths from .env; labels require `storage=true` on the node. |
| Multi-node Swarm (NFS) | `docker-compose.swarm.yml` | Expects NFS_SERVER/NFS_PATH exports. Set node labels for placement (`storage`, `performance`, `vpn`). |
| VPN/Tunnel variants | `docker-compose.vpn*.yml`, `docker-compose.tunnel.yml` | Still Docker-only; mounts docker.sock. Ensure paths envs are set. |
| Portable single-file reference | `docker-compose.portable.yml` | Path envs required; uses default bridge. |

General requirements
- Docker Engine + docker compose v2 (Podman not supported: swarm, docker.sock, privileged/low ports, and event consumers).
- Set `.env` (copy from `.env.example`) for CONFIG_ROOT/DOWNLOADS_ROOT/MEDIA_ROOT/PUID/PGID/TZ/DOMAIN.
- SELinux enforcing: relabel media/config/downloads (`chcon -Rt svirt_sandbox_file_t …`) or add `:z` to binds.
- Create `traefik-public` overlay for Swarm files to satisfy Traefik labels: `docker network create --driver overlay --attachable traefik-public`.
