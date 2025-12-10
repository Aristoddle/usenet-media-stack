# 🐝 Swarm Quickstart (Single Storage Host + Future Workers)

Goal: run the media stack on your storage box today, keep the path clear to add Raspberry Pi/other nodes later.

## 0) Prereqs
- Real Docker Engine (not Podman) with `docker compose` v2.
- SELinux: ensure your media/config paths are labeled (`chcon -Rt svirt_sandbox_file_t /home/deck/usenet`), or temporarily set permissive while testing.

## 1) Configure
```bash
cp .env.example .env
# Edit .env to set TZ/DOMAIN and adjust CONFIG_ROOT/DOWNLOADS_ROOT/MEDIA_ROOT paths
```

Create the bind directories:
```bash
mkdir -p /home/deck/usenet/{config,downloads,media}
```

## 2) Init swarm & label the storage node
```bash
docker swarm init
docker node update --label-add storage=true --label-add performance=high $(hostname)
# Optional: create traefik public overlay if you use the traefik labels
docker network create --driver overlay --attachable traefik-public
```

## 3) Deploy using local bind overrides
```bash
STACK=${STACK_NAME:-usenet}
docker stack deploy -c docker-compose.swarm.yml -c docker-compose.swarm.local-bind.yml $STACK
```

The base file keeps overlay networking; the override swaps NFS volumes for host bind mounts so the stack works on a single storage node.

## 4) Add workers later
- Join: `docker swarm join --token <token> <manager-ip>`
- Label Pis as `performance=low` (they’ll be avoided for heavy services). For services that must run on Pis, add/update placement constraints.
- If you want multi-node shared storage, export your media/config as NFS and switch back to the base file only (remove the local-bind override) or provide an NFS-capable override.

## 5) Update/rollback
```bash
docker stack ls
docker stack ps $STACK
docker service logs $STACK_sabnzbd --tail 50
```

## Notes
- Traefik labels expect an external overlay `traefik-public`; create it even if you don’t run Traefik yet to avoid missing-network errors.
- PUID/PGID default to 1000; set in `.env` if your host differs.
- The override keeps all services constrained to `storage=true` where volumes are needed (prowlarr now included).
