# 🎬 Usenet Media Automation Stack

**Version 2.0** - A complete, production-ready media automation system with one-command deployment

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-Private-red)]()
[![Maintenance](https://img.shields.io/badge/Maintained-Yes-green)]()

## 📋 Prerequisites

**Don't worry if you don't have these - we'll help you install them!**

- **Docker** - Runs all the services (we'll install it for you)
- **4GB+ RAM** - More is better (8GB+ recommended)
- **50GB+ free disk space** - For downloads and media
- **Linux** - Ubuntu, Debian, or similar (WSL2 works too!)

**New to Docker?** No problem! Run this and we'll set everything up:
```bash
curl -fsSL https://raw.githubusercontent.com/Aristoddle/usenet-media-stack/main/quick-install.sh | bash
```

## 🚀 One-Command Setup

**For experienced users:**
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet setup           # Does everything!
```

**First time? Use our guided setup:**
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deps            # Check what you need
./usenet setup           # Deploy with auto-fixes!
```

That's it! Your complete media automation system is now running.

**Having issues?** See our [Troubleshooting Guide](TROUBLESHOOTING.md)

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get running in 5 minutes
- **[Complete Documentation](COMPLETE_DOCUMENTATION.md)** - Everything you need to know
- **[Technical Reference](TECHNICAL_REFERENCE.md)** - Deep dive for developers
- **[Media Services Setup](MEDIA_SERVICES_SETUP.md)** - Jellyfin, Overseerr, and more
- **[Stack Recommendations](STACK_RECOMMENDATIONS.md)** - Additional tools to consider

## 🏗️ What's Included

### Core Services
- **Media Management**: Sonarr, Radarr, Lidarr, Readarr, Mylar3, Bazarr
- **Download Automation**: SABnzbd (Usenet), Transmission (Torrents)
- **Indexer Management**: Prowlarr, Jackett
- **Media Streaming**: Jellyfin, Overseerr, Tautulli
- **File Sharing**: Samba, NFS
- **Monitoring**: Netdata, Portainer
- **Post-Processing**: Unpackerr

### Key Features
- ✅ **One-click deployment** - Everything configured automatically
- ✅ **Passwordless local access** - Convenient for home networks
- ✅ **JBOD support** - Intelligent drive management for any storage setup
- ✅ **1Password integration** - Secure credential management
- ✅ **Docker Swarm ready** - Scale across multiple machines
- ✅ **Pre-configured providers** - Newshosting, UsenetExpress, Frugalusenet
- ✅ **Ready-to-use indexers** - NZBgeek, NZBFinder, NZBsu, NZBPlanet

## 🏗️ **Architecture Overview**

This stack provides a complete media ecosystem with:

### **Media Automation Suite**
- **Content Discovery & Management**: Sonarr (TV), Radarr (Movies), Readarr (Books), Mylar3 (Comics)
- **Download Automation**: SABnzbd (Usenet), Transmission (BitTorrent)
- **Subtitle Management**: Bazarr with multi-language support
- **Indexer Management**: Prowlarr (primary), Jackett (fallback)
- **Content Reading**: YacReader for comics/books
- **Adult Content**: Whisparr (optional)

### **File Sharing & Network Services**
- **SMB/CIFS Shares**: Windows, macOS, Linux client support via Samba
- **NFS Exports**: Linux/Unix native sharing
- **Multi-protocol Access**: Same content accessible via multiple protocols

### **System Monitoring & Management**
- **Real-time Monitoring**: Netdata with system metrics
- **Container Orchestration**: Portainer for Docker Swarm management
- **Resource Optimization**: Automatic service placement based on node capabilities

## 📊 **Storage Architecture: JBOD (Just a Bunch of Disks)**

### **Fast Storage Tier (Primary)**
```
/media/joe/Fast_8TB_[1-3]    # High-performance drives for new/active content
/media/joe/Fast_4TB_[1-5]    # Additional fast storage for frequently accessed media
```

### **Archive Storage Tier**
```
/media/joe/Slow_4TB_[1-2]    # Long-term archival storage
/media/joe/Slow_2TB_[1-2]    # Additional archive capacity
```

### **Storage Strategy**
- **New/Popular Content**: Fast drives for optimal streaming performance
- **Archive Content**: Slower drives for cost-effective long-term storage
- **Hot-swap Ready**: JBOD supports drive replacement without downtime
- **Flexible Expansion**: Add drives as needed without array rebuilds

## 🌐 **Network Architecture**

### **Service Networks**
- **Media Network** (`172.20.0.0/16`): Encrypted overlay for *arr services
- **Sharing Network** (`172.21.0.0/16`): Unencrypted for SMB/NFS compatibility

### **Port Configuration**
```
Media Management:
  8989  - Sonarr (TV Shows)
  7878  - Radarr (Movies)  
  6767  - Bazarr (Subtitles)
  9696  - Prowlarr (Indexers)
  9117  - Jackett (Fallback indexers)

Download Clients:
  8080  - SABnzbd (Usenet)
  9092  - Transmission (BitTorrent)

Specialized Services:
  8787  - Readarr (Books)
  8090  - Mylar3 (Comics)
  8082  - YacReader (Comic reader)
  6969  - Whisparr (Adult content)

Monitoring & Management:
  19999 - Netdata (System monitoring)
  9000  - Portainer (Container management)

File Sharing:
  139   - SMB (NetBIOS)
  445   - SMB (Direct)
  2049  - NFS
  111   - NFS Portmapper
```

## 🚀 **Quick Start Guide**

### **Automated One-Click Setup**
```bash
cd /home/joe/usenet
./one-click-setup.sh
```

This will:
1. Start all Docker services
2. Wait for services to be ready
3. Configure all providers and indexers automatically
4. Connect all services together

### **Manual Single Node Deployment**

1. **Clone and Setup**
   ```bash
   cd /home/joe/usenet
   ./manage.sh start
   ```

2. **Access Services**
   All services are configured for passwordless access from localhost/local network by default.
   
   **Service URLs and Default Access:**
   - SABnzbd: http://localhost:8080 (No auth on local network)
   - Prowlarr: http://localhost:9696 (No auth on local network)
   - Sonarr: http://localhost:8989 (No auth on local network)
   - Radarr: http://localhost:7878 (No auth on local network)
   - Readarr: http://localhost:8787 (No auth on local network)
   - Bazarr: http://localhost:6767 (No auth on local network)
   - Mylar3: http://localhost:8090 (No auth on local network)
   - Transmission: http://localhost:9092 (No auth on local network)
   - Portainer: http://localhost:9000 (Admin account required on first access)
   - Netdata: http://localhost:19999 (No auth required)

   **Note**: Services are configured to allow passwordless access from the local network (192.168.x.x, 172.x.x.x, 10.x.x.x) for convenience. For remote access, authentication should be enabled.

3. **File Sharing Access**
   ```bash
   # Windows/macOS
   \\your-server-ip\Media
   
   # Linux SMB mount
   mount -t cifs //your-server-ip/Media /mnt/media -o guest
   
   # Linux NFS mount  
   mount -t nfs your-server-ip:/media/joe /mnt/media
   ```

### **Multi-Device Docker Swarm Deployment**

1. **Initialize Swarm on Main Node** (storage server)
   ```bash
   ./manage.sh init-swarm
   ```

2. **Join Additional Nodes**
   ```bash
   # On other devices, use the join token provided
   ./manage.sh join-swarm <worker-token> <manager-ip>
   ```

3. **Label Nodes for Optimal Placement**
   ```bash
   ./manage.sh label-nodes
   ```

4. **Deploy Stack to Swarm**
   ```bash
   ./manage.sh start  # Automatically detects Swarm mode
   ```

## 🖥️ **Multi-Device Deployment Strategies**

### **Node Classification System**

#### **Storage Node** (Primary Server)
- **Role**: Manager node with local storage
- **Services**: All storage-dependent services, Samba, NFS
- **Requirements**: Large storage capacity, moderate CPU/RAM
- **Labels**: `storage=true`, `performance=high`

#### **Compute Node** (Powerful Desktop/Server)
- **Role**: Worker node for CPU-intensive tasks
- **Services**: Download clients, transcoding, indexer management
- **Requirements**: High CPU/RAM, minimal storage needs
- **Labels**: `performance=high`

#### **IoT/Edge Node** (Raspberry Pi, Mini PC)
- **Role**: Worker node for lightweight services
- **Services**: Monitoring, simple web interfaces
- **Requirements**: Low power, minimal resources
- **Labels**: `performance=low`

### **Example Multi-Device Setup**

```yaml
# Node 1: Main Server (Storage + High Performance)
- Role: Manager
- Storage: 8x HDDs in JBOD configuration
- Services: Samba, NFS, Sonarr, Radarr, Bazarr
- Resources: 16GB RAM, 8-core CPU

# Node 2: Download Station (High Performance)
- Role: Worker  
- Storage: Fast SSD for temporary downloads
- Services: SABnzbd, Transmission, Prowlarr
- Resources: 32GB RAM, 12-core CPU

# Node 3: Monitoring Station (Low Power)
- Role: Worker
- Storage: SD card/eMMC
- Services: Netdata, Portainer Agent
- Resources: 4GB RAM, ARM CPU (Raspberry Pi)
```

## 🛠️ **Management Operations**

### **Daily Operations**
```bash
# Check system health
./manage.sh system-health

# View service status
./manage.sh status

# Monitor specific service
./manage.sh logs sonarr

# Restart problematic service
./manage.sh restart-service radarr
```

### **Maintenance Tasks**
```bash
# Update all services
./manage.sh update

# Backup configurations
./manage.sh backup-configs

# Network diagnostics
./manage.sh network-diag

# Create new file share
./manage.sh create-share "4K-Movies" "/media/joe/Fast_8TB_1/4K"
```

### **Scaling Operations**
```bash
# Add worker node to existing swarm
./manage.sh join-swarm <token> <manager-ip>

# Label new node for specific workloads
./manage.sh label-nodes

# Monitor swarm health
docker node ls
docker service ls
```

## 📁 **File Organization & Access**

### **Directory Structure**
```
/media/joe/
├── Fast_8TB_1/           # Primary TV storage
│   ├── TV-Shows/
│   └── 4K-TV/
├── Fast_8TB_2/           # Primary Movie storage  
│   ├── Movies/
│   └── 4K-Movies/
├── Fast_4TB_[1-5]/       # Additional fast storage
├── Slow_4TB_[1-2]/       # Archive storage
└── Slow_2TB_[1-2]/       # Archive storage

/home/joe/usenet/
├── downloads/            # Active downloads
├── config/              # Service configurations
├── backups/             # Configuration backups
└── docker-compose.yml   # Stack definition
```

### **SMB/CIFS Shares**
| Share Name | Path | Purpose | Access |
|------------|------|---------|--------|
| Media | `/media/joe` | All media content | Read/Write |
| Downloads | `/downloads` | Active downloads | Read/Write |
| TV | `/tv/*` | TV shows across drives | Read/Write |
| Movies | `/movies/*` | Movies across drives | Read/Write |
| Books | `/books` | Ebook collection | Read/Write |
| Comics | `/comics` | Comic collection | Read/Write |
| Config | `/config` | Service configs | Admin only |

### **NFS Exports**
| Export Path | Client Access | Options |
|-------------|---------------|---------|
| `/media/joe` | `192.168.0.0/16` | `rw,sync,no_subtree_check` |
| `/downloads` | `192.168.0.0/16` | `rw,sync,no_subtree_check` |
| `/config` | `192.168.0.0/16` | `rw,sync,no_subtree_check` |

## 🔧 **Service Configuration Guide**

### **Initial Setup Sequence**

1. **Configure Prowlarr** (http://localhost:9696)
   - Add indexers for Usenet and BitTorrent
   - Configure API keys
   - Test indexer connectivity

2. **Setup Download Clients**
   - **SABnzbd** (http://localhost:8080): Configure Usenet provider
   - **Transmission** (http://localhost:9092): Configure VPN if needed

3. **Configure *arr Services**
   - **Sonarr**: Add TV root folders, link to download clients
   - **Radarr**: Add movie root folders, configure quality profiles
   - **Bazarr**: Connect to Sonarr/Radarr, configure subtitle providers

4. **Optional Services**
   - **Readarr**: Configure for ebook management
   - **Mylar3**: Setup comic book automation
   - **Whisparr**: Configure if adult content desired

### **Root Folder Configuration**

Configure multiple root folders in Sonarr/Radarr for optimal storage utilization:

```
TV Shows Root Folders:
  /tv/fast1     - Fast_8TB_1 (New/Popular shows)
  /tv/fast2     - Fast_8TB_2 (Ongoing series)
  /tv/fast3     - Fast_8TB_3 (4K content)
  /tv/slow1     - Slow_4TB_1 (Archive/Completed)
  /tv/slow2     - Slow_4TB_2 (Archive/Completed)

Movie Root Folders:
  /movies/fast1 - Fast_8TB_1 (New releases/4K)
  /movies/fast2 - Fast_8TB_2 (Popular movies)
  /movies/slow1 - Slow_4TB_1 (Archive movies)
  /movies/slow2 - Slow_4TB_2 (Archive movies)
```

## 🛡️ **Security & Network Configuration**

### **Firewall Setup (UFW)**
```bash
# Allow SSH
sudo ufw allow ssh

# Media services (adjust subnet for your network)
sudo ufw allow from 192.168.0.0/16 to any port 8080,8989,7878,6767,9696

# File sharing
sudo ufw allow from 192.168.0.0/16 to any port 139,445,2049,111

# Monitoring (optional - restrict as needed)
sudo ufw allow from 192.168.0.0/16 to any port 19999,9000

# Enable firewall
sudo ufw enable
```

### **Docker Swarm Security**
- **Encrypted Networks**: Media services use encrypted overlay networks
- **TLS Communication**: All inter-node communication is encrypted
- **Node Authentication**: Swarm tokens provide secure node joining
- **Service Isolation**: Each service runs in isolated containers

### **File Sharing Security**
- **Network Restriction**: SMB/NFS limited to trusted subnet
- **User Authentication**: Optional user-based access control
- **Guest Access**: Configurable guest access for ease of use

## 📈 **Performance Optimization**

### **Resource Allocation Strategy**

#### **High-Priority Services** (Performance-critical)
- **SABnzbd**: 2 CPU cores, 2GB RAM during downloads
- **Transmission**: 1.5 CPU cores, 1GB RAM for seeding
- **Prowlarr**: 0.5 CPU cores, 512MB RAM for indexing

#### **Medium-Priority Services** (Steady-state)
- **Sonarr/Radarr**: 1 CPU core, 1GB RAM each
- **Bazarr**: 0.5 CPU cores, 512MB RAM
- **Samba/NFS**: 0.5 CPU cores, 512MB RAM

#### **Low-Priority Services** (Background)
- **Readarr/Mylar3**: 0.5 CPU cores, 512MB RAM
- **YacReader**: 0.25 CPU cores, 256MB RAM
- **Jackett**: 0.25 CPU cores, 256MB RAM

### **Storage Performance Tips**

1. **Fast Tier Optimization**
   - Use for actively downloaded content
   - Configure as primary in download clients
   - Set as default for new content

2. **Archive Tier Usage**
   - Move completed/watched content
   - Use for long-term storage
   - Schedule regular cleanup

3. **JBOD Best Practices**
   - Monitor individual drive health
   - Plan for drive replacement/expansion
   - Use drive-specific mount points

## 🔍 **Monitoring & Troubleshooting**

### **Health Monitoring**

#### **System-Level Monitoring**
```bash
# Real-time system monitoring
# Access Netdata at http://localhost:19999

# Manual system checks
./manage.sh system-health
./manage.sh network-diag
```

#### **Service-Level Monitoring**
```bash
# Check all services
./manage.sh status

# Monitor specific service logs
./manage.sh logs sonarr

# Check file sharing services
./manage.sh sharing-info
```

### **Common Issues & Solutions**

#### **Download Issues**
```bash
# Check download clients
./manage.sh logs sabnzbd
./manage.sh logs transmission

# Restart download services
./manage.sh restart-service sabnzbd
```

#### **File Sharing Issues**
```bash
# Test Samba connectivity
smbclient -L localhost -N

# Test NFS exports
showmount -e localhost

# Restart sharing services
./manage.sh restart-service samba
./manage.sh restart-service nfs-server
```

#### **Storage Issues**
```bash
# Check disk usage
df -h /media/joe/*

# Check mount points
mount | grep /media/joe

# Monitor I/O
iotop
```

### **Log Locations**
- **Docker Logs**: `docker logs <container_name>`
- **System Logs**: `/var/log/syslog`
- **Service Configs**: `/home/joe/usenet/config/`
- **Backup Logs**: `/home/joe/usenet/backups/`

## 🚀 **Scaling & Expansion**

### **Adding Storage**

1. **Physical Drive Addition**
   ```bash
   # Format new drive
   sudo mkfs.ext4 /dev/sdX
   
   # Create mount point
   sudo mkdir /media/joe/New_Drive
   
   # Add to /etc/fstab
   echo "/dev/sdX /media/joe/New_Drive ext4 defaults 0 2" | sudo tee -a /etc/fstab
   
   # Mount drive
   sudo mount -a
   ```

2. **Update Docker Compose**
   ```yaml
   # Add new volume mount to relevant services
   volumes:
     - /media/joe/New_Drive:/movies/new_drive:rw
   ```

3. **Configure in *arr Services**
   - Add new root folder in Sonarr/Radarr
   - Set appropriate quality profiles
   - Configure storage preferences

### **Adding Compute Nodes**

1. **Prepare New Node**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Copy management script
   scp manage.sh user@new-node:/path/to/script/
   ```

2. **Join Swarm**
   ```bash
   # On manager node, get join token
   docker swarm join-token worker
   
   # On new node
   ./manage.sh join-swarm <token> <manager-ip>
   ```

3. **Label and Deploy**
   ```bash
   # Label node based on capabilities
   ./manage.sh label-nodes
   
   # Services automatically deploy based on constraints
   ```

### **Service Expansion**

#### **Additional Media Types**
- **Lidarr**: Music management (add to compose file)
- **LazyLibrarian**: Additional book management
- **Headphones**: Music discovery and download

#### **Enhancement Services**
- **Overseerr**: User request management
- **Tautulli**: Plex analytics (if using Plex)
- **Ombi**: Media request platform

#### **Backup Solutions**
- **Duplicati**: Automated cloud backups
- **Restic**: Efficient backup solution
- **Syncthing**: P2P file synchronization

## 🔄 **Backup & Recovery**

### **Configuration Backup**
```bash
# Automated backup
./manage.sh backup-configs

# Manual backup
tar czf backup_$(date +%Y%m%d).tar.gz /home/joe/usenet/config/
```

### **Data Backup Strategy**

1. **Configuration Data** (Critical)
   - Service configurations
   - Docker compose files
   - Database files
   - **Frequency**: Daily

2. **Media Metadata** (Important)
   - *arr databases
   - Custom artwork
   - **Frequency**: Weekly

3. **Media Files** (Replaceable)
   - Movies, TV shows, etc.
   - Can be re-downloaded
   - **Frequency**: Optional/None

### **Disaster Recovery**

1. **Service Recovery**
   ```bash
   # Stop current stack
   ./manage.sh stop
   
   # Restore configuration
   tar xzf backup_20231215.tar.gz -C /
   
   # Restart stack
   ./manage.sh start
   ```

2. **Complete System Recovery**
   ```bash
   # Reinstall Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Restore code and configs
   git clone <your-fork> /home/joe/usenet
   tar xzf config_backup.tar.gz -C /home/joe/usenet/
   
   # Start services
   cd /home/joe/usenet
   ./manage.sh start
   ```

## 📚 **Additional Resources**

### **Community & Documentation**
- **Servarr Wiki**: https://wiki.servarr.com/
- **Docker Swarm Docs**: https://docs.docker.com/engine/swarm/
- **Samba Documentation**: https://www.samba.org/samba/docs/
- **NFS Documentation**: https://nfs.sourceforge.net/

### **Recommended Reading**
- JBOD vs RAID configurations
- Docker Swarm networking
- Media organization best practices
- Usenet vs BitTorrent strategies

---

## 📝 **Quick Reference Commands**

```bash
# Daily Operations
./manage.sh start              # Start all services
./manage.sh status             # Check service health
./manage.sh system-health      # System overview

# Troubleshooting
./manage.sh logs <service>     # View service logs
./manage.sh restart-service <service>  # Restart specific service
./manage.sh network-diag       # Network diagnostics

# Maintenance
./manage.sh update             # Update all services
./manage.sh backup-configs     # Backup configurations
./manage.sh create-share <name> <path>  # Create new share

# Multi-Device
./manage.sh init-swarm         # Initialize Docker Swarm
./manage.sh join-swarm <token> <ip>  # Join existing swarm
./manage.sh label-nodes        # Label nodes for placement
```

**🎯 This stack is designed for production use with emphasis on reliability, scalability, and ease of management across multiple devices.** 