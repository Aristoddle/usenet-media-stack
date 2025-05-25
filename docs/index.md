---
layout: home

hero:
  name: "Usenet Media Stack"
  text: "Professional Hot-Swap JBOD Media Automation"
  tagline: "Deploy once, add devices as needed. Hot-swap storage for portability. GPU acceleration where available."
  image:
    src: /hero-logo.svg
    alt: Usenet Media Stack
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: View on GitHub
      link: https://github.com/Aristoddle/usenet-media-stack

features:
  - icon: 🔥
    title: Hot-Swappable JBOD
    details: Real-time drive detection with dynamic Docker Compose generation. Plug/unplug drives without service restart. Works with exFAT, ZFS, cloud mounts.
    
  - icon: ⚡
    title: Hardware Optimization
    details: Universal GPU detection (NVIDIA RTX, AMD VAAPI, Intel QuickSync, Pi VideoCore). 4K HEVC transcoding 2-5 FPS → 60+ FPS. Auto-driver installation.
    
  - icon: 🛡️
    title: Professional CLI
    details: Pure subcommand system following pyenv/git patterns. Consistent action verbs across components. Three-tier help system. Smart error handling.
    
  - icon: 💾
    title: Smart Backup System
    details: Enhanced backup with JSON metadata. Config-only defaults prevent size explosions. Atomic restore with rollback. Disaster recovery ready.
    
  - icon: 🎬
    title: 19 Production Services
    details: Complete media automation stack. Jellyfin, Sonarr, Radarr, Prowlarr, SABnzbd, Transmission, Overseerr, Tdarr, and more. TRaSH Guide integration.
    
  - icon: 🏗️
    title: Bell Labs Standards
    details: Code quality following Stan Eisenstat principles. 80-character lines, function contracts, comprehensive documentation. Production-ready architecture.
---

## One-Command Deployment

```bash
# Clone and deploy complete stack
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto
```

**Result**: 19-service media automation stack with hardware optimization and dynamic storage management.

## What You Get Immediately

::: code-group

```bash [Media Services]
jellyfin     (8096) # → Media streaming with GPU transcoding
overseerr    (5055) # → Beautiful request management interface  
yacreader    (8082) # → Comic/manga server and reader
tdarr        (8265) # → Automated transcoding with GPU acceleration
```

```bash [Automation Stack]
sonarr       (8989) # → TV automation with TRaSH Guide optimization
radarr       (7878) # → Movie automation with custom quality profiles
readarr      (8787) # → Book/audiobook automation
bazarr       (6767) # → Subtitle automation (40+ languages)
prowlarr     (9696) # → Universal indexer management
recyclarr           # → TRaSH Guide auto-optimization
```

```bash [Download & Management]
sabnzbd      (8080) # → High-speed Usenet downloading
transmission (9092) # → BitTorrent client with VPN protection
portainer    (9000) # → Docker container management
netdata     (19999) # → Real-time system monitoring
```

:::

## Professional CLI Experience

```bash
# Primary workflows
./usenet deploy                      # Interactive guided setup
./usenet deploy --auto               # Fully automated deployment
./usenet validate                    # Comprehensive system checks

# Hot-swappable storage management
./usenet storage list                # Discover all available drives
./usenet storage add /media/drive    # Add drive to media pool
./usenet storage remove /media/drive # Remove from pool

# Hardware optimization
./usenet hardware list               # Show capabilities and recommendations
./usenet hardware optimize --auto    # Generate optimized configurations
./usenet hardware install-drivers    # Auto-install GPU drivers

# Smart backup system
./usenet backup list                 # Show all backups with metadata
./usenet backup create --compress    # Config-only backup (~5MB)
./usenet backup show backup.tar.gz   # Detailed backup information
```

## Real-World Performance

| Metric | CPU Only | GPU Accelerated | Improvement |
|--------|----------|----------------|-------------|
| **4K HEVC Transcoding** | 2-5 FPS | 60+ FPS | **12-30x faster** |
| **Power Consumption** | 200W | 50W | **75% reduction** |
| **Concurrent Streams** | 1-2 | 8+ | **4-8x capacity** |

## Architecture Highlights

- **Hot-Swappable JBOD**: Real-time drive detection with cross-platform exFAT support
- **Universal Hardware Support**: NVIDIA RTX, AMD VAAPI, Intel QuickSync, Raspberry Pi
- **Professional CLI**: Pure subcommand system with three-tier help and smart error handling
- **Production Ready**: 19 integrated services with comprehensive monitoring and backup
- **Bell Labs Quality**: Code standards honoring Stan Eisenstat's teaching principles

## Get Started

<div class="tip custom-block" style="padding-top: 8px">

Ready to deploy your media automation stack? Start with our [Quick Start Guide](/getting-started/) for a guided walkthrough, or jump straight to [Installation](/getting-started/installation) if you're ready to go.

</div>

---

<div style="text-align: center; margin-top: 2rem; padding-top: 2rem; border-top: 1px solid var(--vp-c-divider);">

**Professional media automation for the modern self-hoster**

*Built with ❤️ following Bell Labs standards. Dedicated to Stan Eisenstat.*

</div>