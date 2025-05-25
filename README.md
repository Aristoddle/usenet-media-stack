# 🚀 Distributed Usenet Media Stack

> **N-Node Edge Computing Media Automation** — Deploy across any devices you have lying around: laptops, Raspberry Pis, Steam Deck, old computers with Linux. Nodes can join and leave dynamically as you need the horsepower or want to game.

[![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-Ready-blue.svg)](https://docs.docker.com/engine/swarm/)
[![Single Node](https://img.shields.io/badge/Single%20Node-Compatible-green.svg)](https://docs.docker.com/compose/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20ARM64%20%7C%20x86-orange.svg)](https://github.com/yourusername/usenet-media-stack)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-Distributed%20Edge-purple.svg)]()

## 🎯 **Deployment Options**

**🖥️ Single Node** (Traditional) | **🌐 Dynamic N-Node Cluster** (Recommended)
---|---
Perfect for: Home servers, NAS boxes | Perfect for: Whatever hardware you have lying around
Command: `docker-compose up` | Command: `docker stack deploy`
Resources: 1 machine | Resources: Laptops + RPis + Steam Deck + old computers
Flexibility: Static setup | Flexibility: Join/leave nodes as needed

---

## ⚡ **Quick Start**

### 🖥️ **Single Node Deployment**
```bash
# Clone and deploy
git clone https://github.com/yourusername/usenet-media-stack.git
cd usenet-media-stack

# One-command deployment with hardware optimization
./usenet deploy --auto
```

### 🌐 **Distributed Swarm Deployment** ⭐
```bash
# 1. Initialize Swarm on manager node
docker swarm init

# 2. Join worker nodes (run on each device)
docker swarm join --token <token> <manager-ip>:2377

# 3. Label nodes for intelligent placement
docker node update --label-add performance=high gaming-laptop
docker node update --label-add performance=medium steam-deck
docker node update --label-add performance=low raspberry-pi-4
docker node update --label-add storage=true nas-box

# 4. Deploy distributed stack
docker stack deploy -c docker-compose.swarm.yml usenet

# 5. Add/remove nodes dynamically as needed
# Want to game? Remove Steam Deck: docker node update --availability drain steam-deck
# Need more power? Add old laptop: docker swarm join <token> <manager-ip>
```

---

## 🏗️ **Architecture Highlights**

### **🔄 Hot-Swappable JBOD Storage**
- **Cross-platform media libraries**: exFAT drives work on any device
- **Camping-ready**: Unplug drives, take them anywhere, plug back in
- **Zero configuration**: Automatic discovery and integration
- **29+ drive types supported**: ZFS, cloud mounts, external USB, JBOD arrays

### **🌐 Dynamic Container Orchestration**
- **Intelligent placement**: Heavy tasks on gaming laptops, medium on Steam Deck, light on Pi's
- **Elastic scaling**: Nodes join/leave seamlessly (drain Steam Deck to play Yakuza, rejoin when done)
- **Zero-downtime updates**: Rolling deployments across available nodes
- **Encrypted networking**: TLS-secured overlay networks across your random hardware

### **⚡ Modern Networking Stack**
- **Traefik**: Automatic service discovery and HTTPS (replaces nginx)
- **VPN Integration**: Mullvad WireGuard protecting BitTorrent traffic only
- **Prometheus + Grafana**: Beautiful cluster monitoring dashboards
- **TRaSH Guide Integration**: Maximum quality automation

---

## 📊 **What You Get**

### **19 Production Services**
```bash
# Media Automation (The Core)
sonarr      # → TV shows with TRaSH Guide optimization
radarr      # → Movies with 4K remux priority  
prowlarr    # → Universal indexer management (replaces Jackett)
recyclarr   # → Automatic TRaSH Guide updates

# Download Clients
sabnzbd     # → High-speed Usenet (clearnet)
transmission # → BitTorrent (VPN-protected via Mullvad)

# Media Services
jellyfin    # → Media streaming with GPU transcoding
overseerr   # → Beautiful request management
tdarr       # → Automated transcoding pipeline

# Monitoring & Management
prometheus  # → Cluster metrics collection
grafana     # → Stunning monitoring dashboards
traefik     # → Modern reverse proxy with auto-HTTPS
```

### **Professional CLI Interface**
```bash
# Deployment
./usenet deploy                      # Interactive deployment
./usenet deploy --auto               # Zero-touch deployment

# Storage Management (Hot-swap JBOD)
./usenet storage list                # List 29+ detected drives
./usenet storage add /media/new-4tb  # Add drive to pool
./usenet storage sync                # Update all service APIs

# Hardware Optimization
./usenet hardware list               # GPU capabilities & optimization
./usenet hardware optimize --auto    # Generate optimized configs

# Cluster Operations
./usenet services list               # Health across all nodes
./usenet validate                    # Pre-flight checks
./usenet backup create              # Configuration backups
```

---

## 🧪 **Local Testing (Virtualized Swarm)**

Test the distributed deployment without real hardware:

```bash
# Start 3-node virtualized Swarm cluster
docker-compose -f test-swarm-local.yml up

# Automatically deploys the stack and simulates:
# - 1 manager node (laptop simulation)
# - 2 worker nodes (laptop + Raspberry Pi simulation)  
# - NFS shared storage
# - Service placement across "devices"
```

**Access Points**:
- Grafana: http://localhost:3000 (cluster monitoring)
- Traefik: http://localhost:8080 (service discovery)
- Prometheus: http://localhost:9090 (metrics)

---

## 🎯 **Use Cases**

### **🏠 Opportunistic Computing**
- **Use what you have**: Gaming laptop, Steam Deck, Raspberry Pis, old computers
- **Dynamic allocation**: Heavy transcoding when gaming laptop is free, pause when needed
- **Steam Deck integration**: Why let it sit idle? It's Arch Linux with decent specs

### **🏕️ Portable Media Libraries** 
- **Camping/Travel**: Take drives with you, plug into any device
- **Cross-platform**: Works on Windows, macOS, Linux
- **Offline capable**: Local processing, no internet required

### **💼 Professional Showcase**
- **Staff engineer portfolio**: Demonstrates distributed systems expertise
- **Architecture skills**: Modern container orchestration patterns
- **Product thinking**: Complex tech wrapped in simple UX

---

## 📚 **Documentation**

- **[Architecture Overview](docs/architecture.md)** — System design and networking
- **[Swarm Deployment Guide](docs/swarm-deployment.md)** — Multi-node setup
- **[Storage Management](docs/storage.md)** — Hot-swap JBOD workflows
- **[Monitoring Setup](docs/monitoring.md)** — Prometheus + Grafana cluster
- **[Troubleshooting](docs/troubleshooting.md)** — Common issues and solutions

---

## 🔧 **System Requirements**

### **Single Node**
- **CPU**: 4+ cores (transcoding performance)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 100GB+ for configs, unlimited for media
- **OS**: Linux, macOS, Windows (WSL2)

### **Dynamic N-Node Swarm**
- **Manager nodes**: 1-3 (stable devices: NAS, always-on laptop)
- **Worker nodes**: Whatever you have - Steam Deck, gaming laptop, Pi's, old computers
- **Network**: Gigabit LAN preferred, works with mixed connections
- **Storage**: NFS server or distributed storage solution

---

## 🏆 **Key Features**

### **🚀 Modern Technology Stack**
- **Traefik** instead of nginx (automatic service discovery)
- **Prometheus + Grafana** instead of Netdata (cluster monitoring)
- **Prowlarr** instead of Jackett (modern indexer management)
- **WireGuard VPN** with traffic isolation
- **TRaSH Guide integration** for maximum quality

### **🎯 Production Ready**
- **Zero-downtime deployments** with rolling updates
- **Health checks** and automatic service recovery
- **Comprehensive monitoring** with alerting
- **Backup/restore** with disaster recovery
- **Security-first design** with encrypted networking

### **🧠 Intelligent Automation**
- **Hardware detection** with automatic optimization
- **Storage discovery** across 29+ filesystem types
- **Service placement** based on node capabilities
- **Quality profiles** with TRaSH Guide standards
- **API integration** for seamless hot-swap workflows

---

## 🤝 **Contributing**

This project demonstrates both **technical depth** and **product intuition**. Contributions are welcome for:

- **New service integrations** (maintain the quality bar)
- **Hardware optimizations** (additional GPU types)
- **Documentation improvements** (especially architecture diagrams)
- **Testing enhancements** (expanded virtualized testing)

---

## 📖 **Philosophy**

**Architecture Philosophy**: *"The slow way is the fast way"* — Build it right, build it once.

*Good systems are like good radio stations: they just work, reach everywhere they need to, and people can tune in from anywhere.*

---

## 📄 **License**

MIT License — Feel free to use this in your own projects. If it helps you land a staff engineer role, consider it a win for everyone. 🚀