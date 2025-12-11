# Getting Started

Welcome to the Usenet Media Stack! This guide will get you up and running in minutes.

## Interactive CLI Demo

Try our commands directly in this interactive terminal simulator:

<CLISimulator />

## Quick Start (generic Docker host)

```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
cp .env.example .env.local   # fill provider/API keys
docker compose up -d         # after Docker is installed
```

## Bazzite / Podman-first
- Use Komga on Podman (already running) while transfers finish.
- After reboot (when ready): enable Docker, then `docker compose up -d` plus optional `-f docker-compose.reading.yml` for Calibre/Audiobookshelf.

## What You Get

- 19 integrated services (Sonarr, Radarr, Jellyfin, etc.)
- Hot-swappable JBOD drive support
- Hardware-optimized transcoding
- Secure Cloudflare tunnel access

## Next Steps

- [Installation Guide](./installation)
- [First Deployment](./first-deployment)
- [Reading Stack](/reading-stack)
- [Usenet Primer](/usenet-primer)
- [Usenet Onboarding](/usenet-onboarding)
