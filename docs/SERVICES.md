# Working Services Documentation

**Status**: Live snapshot (Dec 27, 2025) -- 24 containers running, all healthy. Single source of truth for working services.

## Core Working Services

### Search & Automation
- **Prowlarr** -- http://localhost:9696 (indexer management)
- **Sonarr** -- http://localhost:8989 (TV shows)
- **Radarr** -- http://localhost:7878 (movies)
- **Lidarr** -- http://localhost:8686 (music)
- **SABnzbd** -- http://localhost:8080 (usenet downloads)
- **Transmission** -- http://localhost:9091 (torrents)
- **Aria2** -- http://localhost:6800/jsonrpc (RPC downloads)
- **Overseerr** -- http://localhost:5055 (requests)
- **Recyclarr** -- (no web UI, runs scheduled sync)

### Libraries
- **Komga** -- http://localhost:8081 (comics/manga reader)
- **Komf** -- http://localhost:8085 (metadata enrichment)
- **Kavita** -- http://localhost:5000 (manga/ebook reader)
- **Mylar** -- http://localhost:8090 (comics automation)
- **Whisparr** -- http://localhost:6969 (adult content)
- **Suwayomi** -- http://localhost:4567 (manga sources)
- **Audiobookshelf** -- http://localhost:13378 (audiobooks/podcasts)
- **Stash** -- http://localhost:9998 (media organizer)

### Media Servers
- **Plex** -- http://localhost:32400

### Processing & Management
- **Tdarr** -- http://localhost:8265 (transcoding with GPU acceleration)
- **Portainer** -- http://localhost:9000 (container management)
- **Netdata** -- http://localhost:19999 (system monitoring)
- **Uptime Kuma** -- http://localhost:3001 (service monitoring)

### File Services
- **Bazarr** -- http://localhost:6767 (subtitles)
- **Samba** -- ports 139/445 (network file sharing)

### Disabled / Not Running
- Traefik (routes not wired)
- Docs site (stale)

## Quick Start

### Key URLs
```bash
Plex:         http://localhost:32400   # Media streaming
Prowlarr:     http://localhost:9696    # Indexer management
Portainer:    http://localhost:9000    # Container management
Uptime Kuma:  http://localhost:3001    # Service health dashboard
Tdarr:        http://localhost:8265    # Transcoding dashboard
```

### CLI Management
```bash
# Service status (requires sudo for docker)
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Individual service logs
sudo docker logs kavita --tail 50
sudo docker logs prowlarr --tail 50

# Restart a service
sudo docker restart kavita
```

## Technical Notes

### Container Runtime
- **Docker** is the primary runtime (requires sudo)
- Do NOT use podman (creates separate instances, causes conflicts)
- Socket: `/var/run/docker.sock`
- All 24 containers managed via docker compose

### GPU Acceleration (Tdarr)
- **GPU**: AMD Radeon 780M (integrated, RDNA 3)
- **Video Engine**: VCN 4.0 (Video Core Next)
- **Acceleration**: VA-API hardware encoding/decoding
- **Device Passthrough**: `/dev/dri` mounted in container
- **Init System**: s6-supervise inside Tdarr container

### Tdarr GPU Configuration
The Tdarr container has GPU passthrough configured:
```yaml
devices:
  - /dev/dri:/dev/dri
```

VA-API is available inside the container for hardware-accelerated transcoding:
- H.264/AVC encoding and decoding
- HEVC/H.265 encoding and decoding
- VP9 decoding
- AV1 decoding (VCN 4.0)

### Validation Method (Dec 27, 2025)
- HTTP health checks on all web endpoints
- Docker container status inspection
- GPU passthrough verified via VA-API inside Tdarr container
- All services responding with 200/301/302/307 (auth redirects normal)

### Known Issues
- Mylar returns 401 (requires auth - normal)
- Overseerr/Portainer return 307 (auth redirect - normal)

---

*Last validated: 27Dec25 via automated HTTP probe and GPU verification*
