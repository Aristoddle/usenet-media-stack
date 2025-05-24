---
layout: home
title: Usenet Media Stack
---

# 🎬 Usenet Media Stack

A modern, secure, and automated media management system that follows Bell Labs engineering principles.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/usenet-media-stack.git
cd usenet-media-stack

# Configure your credentials
cp .env.example .env
nano .env

# Deploy everything
./usenet setup
```

That's it! Your complete media automation system is now running.

## 🏗️ Architecture

This stack implements clean architecture principles:

- **Single Entry Point**: One command to rule them all (`./usenet`)
- **Environment-Based Config**: All settings in `.env`, never in code
- **Modular Design**: Each service does one thing well
- **Security First**: Zero exposed ports with Cloudflare Tunnel
- **Cross-Platform**: Runs on Linux, macOS, and Windows (WSL2)

## 📚 Documentation

<div class="grid">
  <div class="card">
    <h3>📖 <a href="guide">Installation Guide</a></h3>
    <p>Complete setup instructions from zero to streaming</p>
  </div>
  
  <div class="card">
    <h3>💾 <a href="storage">Storage Setup</a></h3>
    <p>JBOD configuration and disk management</p>
  </div>
  
  <div class="card">
    <h3>🔒 <a href="security">Security Guide</a></h3>
    <p>Cloudflare Tunnel, authentication, and best practices</p>
  </div>
  
  <div class="card">
    <h3>🔧 <a href="troubleshooting">Troubleshooting</a></h3>
    <p>Common issues and solutions</p>
  </div>
</div>

## 🎯 Features

### Core Services
- **SABnzbd** - High-performance Usenet downloader
- **Prowlarr** - Indexer management and sync
- **Sonarr** - TV show automation
- **Radarr** - Movie automation
- **Readarr** - Book/audiobook automation
- **Lidarr** - Music automation
- **Bazarr** - Subtitle management
- **Mylar3** - Comic automation

### Modern Stack (2024)
- **Cloudflare Tunnel** - Zero exposed ports
- **Authentik** - Enterprise SSO
- **Homepage** - Beautiful dashboard
- **Uptime Kuma** - Service monitoring

## 🛡️ Security

- Zero exposed ports (Cloudflare Tunnel)
- All credentials in environment variables
- Automatic SSL/TLS certificates
- DDoS protection included
- Optional SSO with 2FA

## 🔧 Commands

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
./usenet update             # Update all containers
```

## 🤝 Contributing

We follow Bell Labs coding standards:
- Clean abstractions
- Comprehensive documentation
- Rigorous testing
- No magic constants

See [CLAUDE.md](https://github.com/yourusername/usenet-media-stack/blob/main/CLAUDE.md) for coding standards.

## 📜 License

MIT License - see [LICENSE](https://github.com/yourusername/usenet-media-stack/blob/main/LICENSE) file

---

Built with ❤️ by the Usenet community

<style>
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.card {
  padding: 1.5rem;
  border: 1px solid #e1e4e8;
  border-radius: 6px;
  background: #f6f8fa;
}

.card h3 {
  margin-top: 0;
}

.card p {
  margin-bottom: 0;
  color: #586069;
}
</style>