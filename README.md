# 🎬 Usenet Media Stack

**Version 2.0** - A complete, production-ready media automation system with one-command deployment

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20|%20macOS%20|%20WSL2-green)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## 🖥️ Platform Support

This stack runs anywhere Docker runs:
- **Linux** (Ubuntu, Debian, Fedora, Arch, etc.)
- **macOS** (Intel & Apple Silicon)
- **Windows** (via WSL2)
- **Synology/QNAP** NAS systems
- **Any Docker-capable system**

## 📋 Prerequisites

- **Docker** & **Docker Compose v2**
- **4GB+ RAM** (8GB+ recommended)
- **50GB+ free disk space**
- **Internet connection** for initial setup

Don't have Docker? We'll help you install it!

## 🚀 Quick Start

```bash
# Clone and enter directory
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack

# One command does everything!
./usenet setup
```

That's it! Your complete media automation system is now running.

## 🎯 What You Get

A fully automated media management system with:

### Core Services
- **SABnzbd** - Usenet downloader
- **Prowlarr** - Indexer management
- **Sonarr** - TV show automation
- **Radarr** - Movie automation
- **Readarr** - Book/audiobook automation
- **Lidarr** - Music automation
- **Bazarr** - Subtitle management
- **Mylar3** - Comic automation

### Media Services (Optional)
- **Jellyfin** - Media streaming server
- **Overseerr** - Request management
- **Tautulli** - Media statistics

### Management Tools
- **Portainer** - Docker management UI
- **Netdata** - System monitoring

## 🛠️ Commands

```bash
# Service Management
./usenet start              # Start all services
./usenet stop               # Stop all services
./usenet restart            # Restart services
./usenet status             # Check service health
./usenet logs [service]     # View logs

# Configuration
./usenet configure          # Auto-configure services
./usenet test               # Run health checks
./usenet backup             # Backup configurations

# Updates
./usenet update             # Update all containers
```

## 🔧 Configuration

### Option 1: Automatic (Recommended)
```bash
./usenet configure --all
```

### Option 2: Manual
1. Access each service web UI
2. Complete initial setup wizards
3. Add your Usenet providers and indexers

## 🌐 Service URLs

After setup, access your services at:

| Service | URL | Purpose |
|---------|-----|---------|
| SABnzbd | http://localhost:8080 | Downloads |
| Prowlarr | http://localhost:9696 | Indexers |
| Sonarr | http://localhost:8989 | TV Shows |
| Radarr | http://localhost:7878 | Movies |
| Readarr | http://localhost:8787 | Books |
| Lidarr | http://localhost:8686 | Music |
| Bazarr | http://localhost:6767 | Subtitles |
| Jellyfin | http://localhost:8096 | Streaming |
| Portainer | http://localhost:9000 | Docker UI |

## 📁 Directory Structure

```
usenet-media-stack/
├── config/         # Service configurations
├── downloads/      # Download directory
├── media/          # Media library
│   ├── tv/
│   ├── movies/
│   ├── music/
│   ├── books/
│   └── comics/
└── lib/            # Core scripts
```

## 🚨 Troubleshooting

### Common Issues

**Services not starting?**
```bash
./usenet test               # Run diagnostics
./usenet logs [service]     # Check specific service
```

**Permission issues?**
```bash
# Fix ownership (Linux/macOS)
sudo chown -R $USER:$USER config/ downloads/ media/
```

**Port conflicts?**
Edit `docker-compose.yml` to change port mappings.

### Platform-Specific Notes

**macOS**: Ensure Docker Desktop is running

**Windows/WSL2**: 
- Use WSL2 terminal, not PowerShell
- Ensure Docker Desktop WSL2 integration is enabled

**Synology**: May need to run as root or adjust permissions

## 🔒 Security

- Services are bound to localhost by default
- Use a reverse proxy (Nginx, Traefik) for external access
- Enable authentication on all services
- Keep your system updated: `./usenet update`

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Follow our coding standards (see CLAUDE.md)
4. Submit a pull request

## 📚 Documentation

Full documentation available at: **[https://yourusername.github.io/usenet-media-stack/](https://yourusername.github.io/usenet-media-stack/)**

- [Installation Guide](https://yourusername.github.io/usenet-media-stack/guide)
- [Storage Setup](https://yourusername.github.io/usenet-media-stack/storage)
- [Security Guide](https://yourusername.github.io/usenet-media-stack/security)
- [Troubleshooting](https://yourusername.github.io/usenet-media-stack/troubleshooting)
- [API Reference](https://yourusername.github.io/usenet-media-stack/api)

## 📜 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Built with love by the Usenet community. Special thanks to all the developers of the included services.

---

**Need help?** Open an issue on [GitHub](https://github.com/Aristoddle/usenet-media-stack/issues)

**Love the project?** Give it a ⭐ on GitHub!