# Usenet Media Stack

**Professional media automation that scales from one laptop to whatever hardware you have lying around.**

One command deploys 19 services with hardware optimization, hot-swappable storage, and automatic configuration. Works on single machines or distributed across Steam Decks, gaming laptops, Raspberry Pis, and old computers.


## Deployment

**Single Node** | **Multi-Node Swarm**
---|---
One machine | Multiple devices
`docker-compose up` | `docker stack deploy`
Fixed resources | Dynamic scaling
Traditional setup | Join/leave devices as needed

---

## Quick Start

**Single Node**
```bash
# Clone and deploy
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack

# One-command deployment with hardware optimization
./usenet deploy --auto
```

**Multi-Node Swarm**
```bash
# 1. Initialize Swarm on manager node
docker swarm init

# 2. Join worker nodes (run on each device)
docker swarm join --token <token> <manager-ip>:2377

# 3. Label nodes for intelligent placement
docker node update --label-add performance=high gaming-laptop
docker node update --label-add performance=medium steam-deck
docker node update --label-add performance=low raspberry-pi-4
docker node update --label-add storage=true nas-box

# 4. Deploy distributed stack
docker stack deploy -c docker-compose.swarm.yml usenet

# 5. Add/remove nodes dynamically as needed
# Want to game? Remove Steam Deck: docker node update --availability drain steam-deck
# Need more power? Add old laptop: docker swarm join <token> <manager-ip>
```

---

## Architecture

**Hot-Swappable Storage**
- exFAT drives work anywhere
- Automatic discovery of ZFS, cloud mounts, USB drives
- Unplug for camping, plug back in

**Dynamic Orchestration**  
- Heavy tasks → gaming laptops
- Medium tasks → Steam Deck
- Light tasks → Raspberry Pis
- Drain nodes to game, rejoin when done

**Modern Stack**
- Traefik for automatic HTTPS
- Mullvad VPN for BitTorrent only
- Prometheus + Grafana monitoring
- TRaSH Guide quality automation

---

## Services

**19 Production Services**
```bash
# Media Automation (The Core)
sonarr      # → TV shows with TRaSH Guide optimization
radarr      # → Movies with 4K remux priority  
prowlarr    # → Universal indexer management (replaces Jackett)
recyclarr   # → Automatic TRaSH Guide updates

# Download Clients
sabnzbd     # → High-speed Usenet (clearnet)
transmission # → BitTorrent (VPN-protected via Mullvad)

# Media Services
jellyfin    # → Media streaming with GPU transcoding
overseerr   # → Beautiful request management
tdarr       # → Automated transcoding pipeline

# Monitoring & Management
prometheus  # → Cluster metrics collection
grafana     # → Stunning monitoring dashboards
traefik     # → Modern reverse proxy with auto-HTTPS
```

**Command Interface**
```bash
./usenet deploy --auto               # Deploy with hardware optimization
./usenet storage list                # Show detected drives  
./usenet storage add /media/new-4tb  # Hot-swap storage
./usenet hardware optimize --auto    # GPU acceleration setup
./usenet services list               # Cluster health
./usenet validate                    # System checks
```

---

## Testing

**Virtualized 3-Node Swarm**
```bash
docker-compose -f test-swarm-local.yml up
```

Simulates manager + 2 workers with service placement across node types.

---

## Requirements

**Single Node**
- 4+ cores, 8GB+ RAM
- Linux, macOS, Windows (WSL2)
- 100GB+ for configs

**Multi-Node Swarm**  
- 1-3 manager nodes (stable devices)
- Any worker nodes (Steam Deck, Pi's, laptops)
- Gigabit LAN preferred

---

## License

MIT