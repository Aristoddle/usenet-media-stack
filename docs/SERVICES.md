# Working Services Documentation

**Status**: Live snapshot (Dec 18, 2025) — core automation online. Plex is pending claim; Audiobookshelf is not running. This is the single source of truth for working services.

## 🎯 Core Working Services

### 🔍 Search & Automation
- **Prowlarr** — http://localhost:9696
- **Sonarr** — http://localhost:8989
- **Radarr** — http://localhost:7878
- **SABnzbd** — http://localhost:8080
- **Transmission** — http://localhost:9091
- **Aria2** — http://localhost:6800/jsonrpc (RPC)
- **Overseerr** — http://localhost:5055

### 📚 Libraries
- **Komga** — http://localhost:8081
- **Komf** — http://localhost:8085
- **Mylar** — http://localhost:8090
- **Whisparr** — http://localhost:6969
- **Kavita** — http://localhost:5000

### 🎬 Media server
- **Plex** — http://localhost:32400 _(pending claim / not running yet)_

### 🛠 Processing & Management
- **Tdarr** — http://localhost:8265
- **Portainer** — http://localhost:9000
- **Netdata** — http://localhost:19999
- **Docs site** — http://localhost:4173 (stale)

### ❌ Disabled / not in scope
- Traefik routes (not wired)
- Audiobookshelf (reading stack not running; compose paths pending normalization)

## 📸 Service Screenshots

Selected services have screenshots for reference (not all services are currently running):
- [Prowlarr Dashboard](./public/images/services/prowlarr.png)  
- [Portainer Management](./public/images/services/portainer.png)
- [Bazarr Subtitles](./public/images/services/bazarr.png)
- [Tdarr Processing](./public/images/services/tdarr.png)

## 🚀 Getting Started

### Quick Access URLs
```bash
# Core Services (Key URLs)
Plex:      http://localhost:32400 # Media streaming (pending claim)
Prowlarr:  http://localhost:9696  # Indexer management  
Portainer: http://localhost:9000  # Container management

# Automation Services (Key URLs)
Bazarr:    http://localhost:6767  # Subtitles
Tdarr:     http://localhost:8265  # Transcoding
```

### CLI Management
```bash
# Service status
./usenet services list

# Individual service logs
./usenet services logs plex
./usenet services logs prowlarr

# System validation
./usenet validate
```

## 🔧 Technical Notes

### Validation Method (Dec 18, 2025)
- Direct HTTP/API checks for each running container
- Docker health/status inspection
- Manual RPC tests: Transmission, Aria2, SABnzbd

### Summary
- Working services: listed above (snapshot)
- Disabled/retired: Traefik routes

---

*Last validated: 18Dec25 via manual HTTP probe*
