---
layout: home
title: "Beppe's Arr Stack"
hero:
  name: "Beppe's Arr Stack"
  text: "41TB Media Homelab"
  tagline: "MergerFS + SVT-AV1 + Tailscale + EmuDeck on Bazzite"
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Services Status
      link: /SERVICES
    - theme: alt
      text: Storage Architecture
      link: /STORAGE_AND_REMOTE_ACCESS
features:
  - icon: ⚙️
    title: 24 Containers Running
    details: Prowlarr, Sonarr, Radarr, Lidarr, Whisparr with SABnzbd + Transmission. Full *arr stack.
  - icon: 💾
    title: 41TB MergerFS Pool
    details: 8 NVMe drives unified into single pool. RAM caching enabled. 96GB memory for page cache.
  - icon: 🎬
    title: SVT-AV1 Transcoding
    details: CPU-based encoding for 60-70% compression. Tdarr with threading optimization.
  - icon: 🌐
    title: Tailscale Remote Access
    details: Fixed IP 100.115.21.9. Plex, Sonarr, Tdarr accessible from anywhere.
  - icon: 📚
    title: Books and Manga Stack
    details: Komga + Komf + Kavita + Audiobookshelf + Mylar. 718GB comics, 25GB audiobooks.
  - icon: 🎮
    title: EmuDeck Gaming
    details: 1.2TB+ ROMs across 30+ systems. Switch, Wii U, PS2, GameCube.
---

## Current Stack Status (Dec 29, 2025)

### Infrastructure
- **Storage**: 41TB MergerFS pool across 8 NVMe drives (30TB used, 73% capacity)
- **RAM**: 96GB with aggressive page caching for near-native I/O performance
- **GPU**: AMD Radeon 780M (RDNA 3) with VCN 4.0 video engine
- **Remote**: Tailscale mesh VPN at `100.115.21.9`

### Media Libraries
| Library | Size | Content |
|---------|------|---------|
| Movies | 16TB | 520 films (239 4K, 249 1080p) |
| TV | 6.1TB | 28 series, 1,994 episodes |
| Anime TV | 5.9TB | 75 series, 5,802 episodes |
| Comics/Manga | 718GB | 78 series (Viz, Yen Press, Dark Horse) |
| Audiobooks | 25GB | Complete Discworld + more |

### Recent Improvements
- MergerFS RAM caching fix (`cache.files=auto-full`, `dropcacheonclose=false`)
- SVT-AV1 encoding strategy for maximum compression
- Complete books/audiobooks serving stack
- EmuDeck 2.5.0 inventory documented
- Manga collection migrated to NAMING_STANDARD_V2

## Quick Commands

```bash
# Check running containers
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Pool status
df -h /var/mnt/pool

# Tailscale status
tailscale status

# Start services
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack
sudo docker compose up -d
```

## Key URLs (Local)

| Service | URL | Purpose |
|---------|-----|---------|
| Plex | [localhost:32400](http://localhost:32400) | Media streaming |
| Prowlarr | [localhost:9696](http://localhost:9696) | Indexer management |
| Sonarr | [localhost:8989](http://localhost:8989) | TV automation |
| Radarr | [localhost:7878](http://localhost:7878) | Movie automation |
| Tdarr | [localhost:8265](http://localhost:8265) | Transcoding |
| Komga | [localhost:8081](http://localhost:8081) | Comics/manga |
| Audiobookshelf | [localhost:13378](http://localhost:13378) | Audiobooks |
| Portainer | [localhost:9000](http://localhost:9000) | Container management |

## Key URLs (Tailscale Remote)

All services accessible via `http://100.115.21.9:<port>` from any Tailscale-connected device.

## Documentation Highlights

- [Storage and Remote Access](/STORAGE_AND_REMOTE_ACCESS) - MergerFS pool, Tailscale setup
- [Tdarr Configuration](/TDARR) - SVT-AV1 encoding, troubleshooting
- [Books and Audiobooks Guide](/BOOKS_AND_AUDIOBOOKS_GUIDE) - Complete serving stack
- [EmuDeck Inventory](/EMUDECK_INVENTORY) - ROM collections, emulators
- [Performance Tuning](/advanced/performance) - MergerFS caching, Tdarr workers

---

*Built with Bell Labs standards. Deployed via GitHub Actions to Cloudflare Pages.*
