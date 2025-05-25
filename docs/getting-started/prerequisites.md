# Prerequisites

Before deploying your Usenet Media Stack, ensure your system meets the minimum requirements and has all necessary dependencies installed. This guide covers hardware requirements, software dependencies, and pre-installation setup.

## System Requirements

### Minimum Hardware Requirements

| Component | Minimum | Recommended | High Performance |
|-----------|---------|-------------|------------------|
| **CPU** | 4 cores | 8+ cores | 16+ cores |
| **RAM** | 8GB | 16GB | 32GB+ |
| **Storage** | 100GB free | 500GB free | 2TB+ free |
| **Network** | 100 Mbps | 1 Gbps | 10 Gbps |

### Storage Requirements

```bash
# Check available disk space
df -h

# Required space breakdown:
# - Base system: ~5GB
# - Docker images: ~15GB  
# - Configuration: ~1GB
# - Transcoding cache: 50-200GB (depends on usage)
# - Media storage: As needed (external drives supported)
```

### Supported Operating Systems

| OS | Version | Status | Notes |
|----|---------|--------|-------|
| **Ubuntu** | 20.04+ | ✅ Recommended | Best tested, automatic driver support |
| **Debian** | 11+ | ✅ Supported | Stable, good Docker support |
| **CentOS/RHEL** | 8+ | ✅ Supported | Enterprise environments |
| **Fedora** | 35+ | ✅ Supported | Latest features |
| **Arch Linux** | Current | ✅ Supported | Rolling release |
| **Raspberry Pi OS** | 64-bit | ⚠️ Limited | ARM64 only, reduced performance |

## Docker Requirements

### Docker Engine Installation

#### Ubuntu/Debian
```bash
# Install Docker via official repository
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker run hello-world
```

#### CentOS/RHEL/Fedora
```bash
# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### Arch Linux
```bash
# Install Docker
sudo pacman -S docker docker-compose

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
```

### Docker Compose Installation

#### Latest Version (Recommended)
```bash
# Install Docker Compose v2 (integrated with Docker)
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify installation
docker compose version
```

#### Manual Installation
```bash
# Download latest Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Docker Configuration

#### Optimize Docker for Media Workloads
```bash
# Create Docker daemon configuration
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json << 'EOF'
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "default-ulimits": {
        "memlock": {
            "Name": "memlock",
            "Hard": -1,
            "Soft": -1
        },
        "nofile": {
            "Name": "nofile",
            "Hard": 65536,
            "Soft": 65536
        }
    }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

## GPU Support (Optional but Recommended)

### NVIDIA GPU Setup

#### Check NVIDIA GPU
```bash
# Check for NVIDIA GPU
lspci | grep -i nvidia

# Expected output example:
# 01:00.0 VGA compatible controller: NVIDIA Corporation GeForce RTX 4090
```

#### Install NVIDIA Drivers
```bash
# Ubuntu/Debian - Add NVIDIA repository
sudo apt-get update
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update

# Install recommended driver
sudo ubuntu-drivers autoinstall

# Or install specific version
sudo apt-get install nvidia-driver-545

# Verify installation
nvidia-smi
```

#### Install NVIDIA Container Toolkit
```bash
# Add NVIDIA repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install NVIDIA container toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### AMD GPU Setup

#### Install AMD Drivers
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install mesa-va-drivers vainfo

# Verify VAAPI support
vainfo

# Expected output should show available VA profiles
```

### Intel GPU Setup

#### Install Intel Media Drivers
```bash
# Ubuntu/Debian
sudo apt-get install intel-media-va-driver vainfo

# Verify QuickSync support
vainfo

# Check for hardware acceleration
ls -la /dev/dri/
```

## Network Configuration

### Firewall Setup

#### UFW (Ubuntu/Debian)
```bash
# Install UFW if not present
sudo apt-get install ufw

# Configure basic firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (important!)
sudo ufw allow ssh

# Allow Docker networks
sudo ufw allow from 172.16.0.0/12

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

#### Firewalld (CentOS/RHEL/Fedora)
```bash
# Enable firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Allow Docker networks
sudo firewall-cmd --permanent --zone=trusted --add-source=172.16.0.0/12

# Reload configuration
sudo firewall-cmd --reload
```

### Port Requirements

| Service | Port | Protocol | Access | Required |
|---------|------|----------|--------|----------|
| SSH | 22 | TCP | Admin access | Yes |
| Cloudflare Tunnel | - | HTTPS | External access | Recommended |
| Jellyfin | 8096 | TCP | Media streaming | Yes |
| Overseerr | 5055 | TCP | Request management | Yes |
| Sonarr | 8989 | TCP | Internal only | Yes |
| Radarr | 7878 | TCP | Internal only | Yes |
| Prowlarr | 9696 | TCP | Internal only | Yes |

## Domain and DNS Setup

### Domain Requirements

For external access via Cloudflare tunnel:

1. **Domain ownership** - You need a domain name
2. **Cloudflare account** - Free tier sufficient
3. **DNS management** - Domain must use Cloudflare nameservers

### Cloudflare Setup

```bash
# Get Cloudflare API token
# 1. Go to https://dash.cloudflare.com/profile/api-tokens
# 2. Create token with "Zone:Edit" permissions for your domain
# 3. Save token securely

# Test API access
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json"
```

## Storage Preparation

### Storage Planning

#### Single Server Setup
```bash
# Check available storage
lsblk
df -h

# Create media directories
sudo mkdir -p /media/storage1
sudo mkdir -p /media/downloads
sudo mkdir -p /media/cache

# Set proper permissions
sudo chown -R $USER:$USER /media/
```

#### External Drive Setup
```bash
# For exFAT drives (cross-platform compatibility)
sudo apt-get install exfat-fuse exfat-utils

# Mount external drive
sudo mkdir -p /media/external
sudo mount -t exfat /dev/sdX1 /media/external -o uid=1000,gid=1000

# Add to fstab for persistence
echo "/dev/sdX1 /media/external exfat defaults,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab
```

### Storage Types

| Type | Use Case | Performance | Compatibility |
|------|----------|-------------|---------------|
| **Local SSD** | OS, cache, transcoding | Excellent | Linux only |
| **Local HDD** | Bulk media storage | Good | Linux only |
| **External USB** | Portable media, backups | Moderate | Cross-platform |
| **Network Storage** | Shared access, large capacity | Variable | Universal |
| **Cloud Storage** | Remote access, backup | Slow | Universal |

## Software Dependencies

### Required Packages

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    bc \
    htop \
    iotop \
    tree \
    rsync
```

#### CentOS/RHEL/Fedora
```bash
sudo dnf install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    bc \
    htop \
    iotop \
    tree \
    rsync
```

### Optional but Recommended

```bash
# Performance monitoring
sudo apt-get install -y \
    iotop \
    nethogs \
    glances \
    ncdu

# Network tools
sudo apt-get install -y \
    net-tools \
    traceroute \
    tcpdump \
    nmap

# File system tools
sudo apt-get install -y \
    smartmontools \
    hdparm \
    lm-sensors
```

## User Setup

### Create Service User (Optional)

```bash
# Create dedicated user for media services
sudo adduser --system --group --home /opt/usenet usenet

# Add to necessary groups
sudo usermod -a -G docker usenet

# Set up directories
sudo mkdir -p /opt/usenet/{config,downloads,media}
sudo chown -R usenet:usenet /opt/usenet
```

### SSH Key Setup

```bash
# Generate SSH key for secure access
ssh-keygen -t ed25519 -C "usenet-media-stack"

# Add to authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh/
```

## Security Hardening

### System Security

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install security updates automatically
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

# Disable root login via SSH
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure fail2ban
sudo apt-get install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Docker Security

```bash
# Enable Docker content trust
export DOCKER_CONTENT_TRUST=1

# Set up Docker secrets directory
sudo mkdir -p /etc/docker/secrets
sudo chmod 700 /etc/docker/secrets

# Limit Docker daemon privileges
sudo usermod -a -G docker $USER
# Log out and back in for group changes to take effect
```

## Pre-Installation Checklist

Before proceeding with installation, verify:

- [ ] **System meets minimum requirements**
- [ ] **Docker and Docker Compose installed**
- [ ] **GPU drivers installed (if applicable)**
- [ ] **Firewall configured**
- [ ] **Storage prepared and accessible**
- [ ] **Domain and Cloudflare configured (for external access)**
- [ ] **User has Docker permissions**
- [ ] **System is up to date**

### Verification Commands

```bash
# Check Docker
docker --version
docker compose version
docker run hello-world

# Check system resources
free -h
df -h
nproc

# Check GPU (if applicable)
nvidia-smi          # NVIDIA
vainfo              # AMD/Intel

# Check network
ping -c 4 google.com
curl -I https://api.cloudflare.com/

# Check permissions
groups $USER | grep docker
```

## Common Issues and Solutions

### Docker Permission Denied

```bash
# Problem: Got permission denied while trying to connect to the Docker daemon
# Solution: Add user to docker group and restart session
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

### GPU Not Detected

```bash
# Problem: GPU not accessible in containers
# Solution: Install nvidia-container-toolkit (NVIDIA) or verify VA-API (AMD/Intel)

# For NVIDIA:
sudo apt-get install nvidia-container-toolkit
sudo systemctl restart docker

# For AMD/Intel:
sudo apt-get install mesa-va-drivers
# Check: vainfo
```

### Storage Permission Issues

```bash
# Problem: Permission denied on storage directories
# Solution: Set proper ownership and permissions
sudo chown -R $USER:$USER /media/storage
sudo chmod -R 755 /media/storage
```

### Firewall Blocking Connections

```bash
# Problem: Services not accessible
# Solution: Check and configure firewall
sudo ufw status
sudo ufw allow from 172.16.0.0/12  # Docker networks
```

## Next Steps

Once all prerequisites are met:

1. [Install the Usenet Media Stack](./installation)
2. [Complete your first deployment](./first-deployment)
3. [Configure hardware optimization](../hardware/)
4. [Set up storage management](../storage/)

## Getting Help

If you encounter issues during prerequisite setup:

- Check the [troubleshooting guide](../advanced/troubleshooting)
- Review Docker documentation: https://docs.docker.com/
- Ask for help in the community forums
- Open an issue on GitHub with system details