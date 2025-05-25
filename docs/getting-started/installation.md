# Installation

## Prerequisites

- Linux system (Ubuntu 20.04+ recommended)
- Docker and Docker Compose
- 16GB+ RAM (32GB recommended)
- GPU (optional but recommended for transcoding)

## Quick Installation

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/user/usenet-media-stack/main/install.sh | bash
```

## Manual Installation

```bash
# Clone repository
git clone https://github.com/user/usenet-media-stack
cd usenet-media-stack

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Deploy stack
./usenet setup
```

## Verification

```bash
# Check all services
./usenet status

# View web interfaces
echo "Jellyfin: https://jellyfin.beppesarrstack.net"
echo "Sonarr: https://sonarr.beppesarrstack.net"
```
