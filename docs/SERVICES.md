# Working Services Documentation

**Status**: Live snapshot (Dec 2025) — core automation online; streaming via Plex (Jellyfin optional/disabled).

This reflects current, tested functionality on the Bazzite host.

## 🎯 Core Working Services

### 🔍 Search & Automation
- **[Prowlarr](http://localhost:9696)** — unified indexers (Newznab configured)
- **[Sonarr](http://localhost:8989)** — TV automation (wired to SABnzbd)
- **[Radarr](http://localhost:7878)** — Movie automation (wired to SABnzbd)
- **[SABnzbd](http://localhost:8080)** — Usenet downloader (categories tv/movies set)
- **[Overseerr](http://localhost:5055)** — Request management

### 📚 Libraries
- **[Komga](http://localhost:8081)** / **[Komf](http://localhost:8085)** — comics/PDF + metadata
- **[Mylar](http://localhost:8090)** — comics automation
- **[Whisparr](http://localhost:6969)** — adult/alt media

### 🛠 Processing & Management
- **[Tdarr](http://localhost:8265)** — transcoding
- **[Portainer](http://localhost:9000)** — container management
- **[Netdata](http://localhost:19999)** — host metrics
- **Docs** (http://localhost:4173) — VitePress site
- **Traefik** — running on 80/443 (routes pending; dashboard 8082)

## ❌ Not in scope / retired
- Readarr (project archived Jun 2025)
- Jellyfin (disabled; Plex is primary)
- YACReader (superseded by Komga)

**What's Missing**:
- ❌ **TV/Movie Automation**: Sonarr/Radarr not functional
- ❌ **Download Management**: SABnzbd issues
- ❌ **Request Interface**: Overseerr problems

## 📸 Service Screenshots

All services have been validated with visual confirmation:

- [Jellyfin Interface](./public/images/services/jellyfin.png)
- [Prowlarr Dashboard](./public/images/services/prowlarr.png)  
- [Portainer Management](./public/images/services/portainer.png)
- [Readarr Library](./public/images/services/readarr.png)
- [Bazarr Subtitles](./public/images/services/bazarr.png)
- [Tdarr Processing](./public/images/services/tdarr.png)
- [YACReader Comics](./public/images/services/yacreader.png)

## 🚀 Getting Started

### Quick Access URLs
```bash
# Core Services (All Working)
Jellyfin:  http://localhost:8096  # Media streaming
Prowlarr:  http://localhost:9696  # Indexer management  
Portainer: http://localhost:9000  # Container management

# Automation Services (All Working)
Readarr:   http://localhost:8787  # Books
Bazarr:    http://localhost:6767  # Subtitles
Tdarr:     http://localhost:8265  # Transcoding
YACReader: http://localhost:8083  # Comics
```

### CLI Management
```bash
# Service status
./usenet services list

# Individual service logs
./usenet services logs jellyfin
./usenet services logs prowlarr

# System validation
./usenet validate
```

## 🔧 Technical Notes

### Validation Method
- **Playwright automated testing** - Visual confirmation of service interfaces
- **Direct HTTP testing** - Endpoint accessibility verification  
- **Container status validation** - Docker health checks
- **Port mapping verification** - Network accessibility

### Performance
- **7/19 total services working** (37% of full stack)
- **7/13 core services working** (54% of essential functionality)
- **All working services provide real user value**

### Architecture Decisions
- Focus on **working subset** rather than broken automation
- **Honest documentation** over aspirational claims
- **Visual proof** of functionality via screenshots
- **Incremental improvement** rather than full-stack fixes

---

*Last validated: 2025-05-28 via automated Playwright testing*
