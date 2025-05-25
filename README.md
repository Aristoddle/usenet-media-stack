# Usenet Media Stack

Media automation that works on whatever hardware you have.

Deploy once, add devices as needed. Hot-swap storage for portability. GPU acceleration where available.


## Setup

```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto
```

For multiple devices, use Docker Swarm:

```bash
docker swarm init
docker stack deploy -c docker-compose.swarm.yml usenet
```

Add worker nodes:

```bash
docker swarm join --token <token> <manager-ip>:2377
```

---

## What's Inside

Sonarr, Radarr, Prowlarr, Jellyfin, SABnzbd, Transmission, Overseerr, and others.

Storage works with exFAT drives, ZFS, cloud mounts. GPU transcoding when available.

VPN protects BitTorrent traffic. Monitoring via Prometheus and Grafana.

## Commands

```bash
./usenet deploy --auto               # Deploy everything
./usenet storage add /media/drive    # Add storage
./usenet hardware optimize --auto    # Setup GPU acceleration
./usenet services list               # Check status
```

## Requirements

4+ cores, 8GB+ RAM. Linux, macOS, or Windows (WSL2).