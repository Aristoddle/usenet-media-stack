# Docker Swarm Deployment Guide

**Complete Media Server Across Multiple Devices**

This guide covers deploying your media automation stack across multiple devices using Docker Swarm for high availability, load distribution, and scalable infrastructure.

## 🏗️ **Swarm Architecture Overview**

### **Why Docker Swarm for Media Servers?**

- **High Availability**: Services restart automatically on node failure
- **Load Distribution**: Spread CPU-intensive tasks across multiple devices
- **Centralized Management**: Single point of control for entire infrastructure
- **Resource Optimization**: Place services on most suitable hardware
- **Zero-Downtime Updates**: Rolling updates without service interruption

### **Ideal Hardware Configuration**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Storage Node   │    │  Compute Node   │    │  Monitor Node   │
│   (Manager)     │    │   (Worker)      │    │   (Worker)      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • 8x SATA HDDs  │    │ • Powerful CPU  │    │ • Low Power     │
│ • 16GB RAM      │    │ • 32GB RAM      │    │ • 4GB RAM       │
│ • Moderate CPU  │    │ • Fast SSD      │    │ • ARM/x86       │
│ • Gigabit LAN   │    │ • Gigabit LAN   │    │ • WiFi OK       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ Services:       │    │ Services:       │    │ Services:       │
│ • Sonarr        │    │ • SABnzbd       │    │ • Netdata       │
│ • Radarr        │    │ • Transmission  │    │ • Portainer     │
│ • Bazarr        │    │ • Prowlarr      │    │ • Logging       │
│ • Samba/NFS     │    │ • Transcoding   │    │ • Alerting      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 **Initial Setup: Manager Node**

### **1. Prepare the Storage Node (Manager)**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Reboot to apply group changes
sudo reboot
```

### **2. Initialize Docker Swarm**

```bash
# Clone the media server repository
cd /home/joe
git clone https://github.com/Aristoddle/home-media-server.git usenet
cd usenet

# Initialize swarm (automatically detects primary IP)
./manage.sh init-swarm
```

**Expected Output:**
```
================================
INITIALIZING DOCKER SWARM
================================
[INFO] Initializing Docker Swarm...
[SUCCESS] Docker Swarm initialized successfully
[INFO] Manager node IP: 192.168.1.100

[INFO] To add worker nodes, run the following on other machines:
docker swarm join --token SWMTKN-1-xxxxx 192.168.1.100:2377

[INFO] To add additional manager nodes, run:
docker swarm join --token SWMTKN-1-yyyyy 192.168.1.100:2377
```

### **3. Label the Manager Node**

```bash
# Label for storage and high performance
docker node update --label-add storage=true $(hostname)
docker node update --label-add performance=high $(hostname)
docker node update --label-add node-type=storage-manager $(hostname)
```

### **4. Verify Swarm Status**

```bash
# Check node status
docker node ls

# Should show:
# ID           HOSTNAME    STATUS  AVAILABILITY  MANAGER STATUS
# abc123*      storage01   Ready   Active        Leader
```

## 🖥️ **Adding Worker Nodes**

### **Compute Node Setup (High-Performance Worker)**

```bash
# On the compute node machine
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
sudo reboot

# Join the swarm (use token from manager)
docker swarm join --token SWMTKN-1-xxxxx 192.168.1.100:2377
```

### **Monitor Node Setup (Low-Power Worker)**

```bash
# On Raspberry Pi or low-power device
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
sudo reboot

# Join the swarm
docker swarm join --token SWMTKN-1-xxxxx 192.168.1.100:2377
```

### **Label Worker Nodes**

From the manager node:

```bash
# Label the compute node
docker node update --label-add performance=high compute01
docker node update --label-add node-type=compute-worker compute01

# Label the monitor node  
docker node update --label-add performance=low monitor01
docker node update --label-add node-type=monitor-worker monitor01

# Verify labels
docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}\t{{.Labels}}"
```

## 📋 **Service Placement Strategy**

### **Storage-Dependent Services** (Manager Node)
- Sonarr, Radarr, Bazarr (need access to media files)
- Samba, NFS (file sharing services)
- Configuration backup services

### **CPU-Intensive Services** (Compute Node)
- SABnzbd (extraction and processing)
- Transmission (seeding and downloading)
- Prowlarr (indexer management)
- Any transcoding services

### **Monitoring Services** (Monitor Node)
- Netdata (system monitoring)
- Portainer Agent (container monitoring)
- Log aggregation
- Alerting services

## 🚀 **Deploying the Stack**

### **1. Deploy to Swarm**

```bash
# From manager node
cd /home/joe/usenet
./manage.sh start
```

**Swarm Deployment Output:**
```
================================
STARTING MEDIA SERVER STACK
================================
[INFO] Docker Swarm mode detected
[INFO] Deploying stack to Docker Swarm...
Creating network media-stack_media_network
Creating network media-stack_sharing_network
Creating service media-stack_samba
Creating service media-stack_nfs-server
Creating service media-stack_sonarr
Creating service media-stack_radarr
...
[SUCCESS] Media server stack deployed to Swarm!
```

### **2. Monitor Deployment**

```bash
# Check service status
docker service ls

# Check service placement
docker service ps media-stack_sonarr
docker service ps media-stack_sabnzbd

# View detailed service info
docker service inspect media-stack_sonarr --pretty
```

### **3. Verify Service Placement**

```bash
# Should show services distributed across nodes
docker node ps $(docker node ls -q)

# Example output:
# storage01:  samba, sonarr, radarr, bazarr
# compute01:  sabnzbd, transmission, prowlarr  
# monitor01:  netdata, portainer
```

## 🔧 **Swarm Management Operations**

### **Daily Monitoring**

```bash
# Complete health check
./manage.sh system-health

# Swarm-specific status
docker node ls
docker service ls
docker stack ps media-stack

# Check resource usage across nodes
docker node ps --format "table {{.Node}}\t{{.Name}}\t{{.CurrentState}}"
```

### **Service Management**

```bash
# Scale a service (if needed)
docker service scale media-stack_prowlarr=2

# Update a service
docker service update --image linuxserver/sonarr:latest media-stack_sonarr

# Force service restart
./manage.sh restart-service sonarr

# Check service logs
./manage.sh logs sonarr
```

### **Node Management**

```bash
# Gracefully drain a node for maintenance
docker node update --availability drain compute01

# Return node to active state
docker node update --availability active compute01

# Remove a node (from the node itself)
docker swarm leave

# Remove node from manager (after it leaves)
docker node rm compute01
```

## 🔄 **Rolling Updates**

### **Update Individual Services**

```bash
# Update with zero downtime
docker service update \
  --image linuxserver/sonarr:latest \
  --update-parallelism 1 \
  --update-delay 30s \
  media-stack_sonarr
```

### **Update Entire Stack**

```bash
# Pull latest images and redeploy
./manage.sh update

# Monitor update progress
watch docker service ls
```

## 🛡️ **High Availability Features**

### **Automatic Service Recovery**

When a node fails:
- Services automatically restart on healthy nodes
- Data persists via shared storage/volumes
- Load balancing adjusts automatically

### **Health Checks**

Services include health checks for automatic recovery:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8989"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### **Backup Strategy for Swarm**

```bash
# Backup swarm configuration
docker swarm ca > swarm-ca.pem

# Backup node certificates (from manager)
sudo tar czf swarm-certs.tar.gz /var/lib/docker/swarm/

# Backup application configs
./manage.sh backup-configs
```

## 🚨 **Troubleshooting Common Issues**

### **Node Communication Problems**

```bash
# Check node connectivity
docker node ls

# If node shows as "Down":
# 1. Check network connectivity
ping node-ip

# 2. Check Docker daemon on node
ssh user@node-ip "sudo systemctl status docker"

# 3. Check firewall rules
sudo ufw status
```

### **Service Deployment Failures**

```bash
# Check service status
docker service ps media-stack_sonarr --no-trunc

# Common issues and solutions:
# 1. Constraint violations (wrong node labels)
docker service inspect media-stack_sonarr | grep -A5 Constraints

# 2. Resource constraints
docker service inspect media-stack_sonarr | grep -A10 Resources

# 3. Volume mount issues
docker service inspect media-stack_sonarr | grep -A10 Mounts
```

### **Network Issues**

```bash
# Check overlay networks
docker network ls --filter driver=overlay

# Test network connectivity between containers
docker exec -it container_name ping another_container

# Recreate networks if needed
docker stack rm media-stack
docker network prune
./manage.sh start
```

### **Storage Access Issues**

```bash
# Check volume mounts on each node
docker exec -it samba_container ls -la /media/joe

# Verify NFS mounts (if using distributed storage)
showmount -e storage-node-ip

# Check permissions
docker exec -it container_name ls -la /config
```

## 📊 **Performance Optimization**

### **Resource Monitoring**

```bash
# Monitor resource usage across swarm
docker stats $(docker ps --format "{{.Names}}")

# Check node-specific resource usage
ssh compute01 'docker stats --no-stream'
ssh monitor01 'docker stats --no-stream'
```

### **Load Balancing**

```bash
# Check service distribution
docker service ps media-stack_prowlarr

# Rebalance services if needed
docker service update --force media-stack_prowlarr
```

### **Network Performance**

```bash
# Test network performance between nodes
iperf3 -c compute01  # from storage01
iperf3 -s            # on target node

# Monitor network I/O
docker exec -it container_name iftop
```

## 🔐 **Security Best Practices**

### **Swarm Security**

- **Certificate Rotation**: Automatic TLS certificate rotation
- **Encrypted Communication**: All inter-node traffic encrypted
- **Token Management**: Regular token rotation for security

```bash
# Rotate join tokens
docker swarm join-token --rotate worker
docker swarm join-token --rotate manager

# Update CA certificate (advanced)
docker swarm ca --rotate
```

### **Network Security**

```bash
# Firewall rules for swarm
sudo ufw allow 2377/tcp  # Swarm management
sudo ufw allow 7946/tcp  # Node communication
sudo ufw allow 7946/udp  # Node communication  
sudo ufw allow 4789/udp  # Overlay network traffic
```

### **Service Security**

- Services run with minimal privileges
- Secrets management for sensitive data
- Network segmentation via overlay networks

## 📈 **Scaling Strategies**

### **Horizontal Scaling**

```bash
# Add more worker nodes as needed
# On new node:
docker swarm join --token <worker-token> manager-ip:2377

# From manager:
./manage.sh label-nodes  # Label new node appropriately
```

### **Vertical Scaling**

```bash
# Increase resource limits for demanding services
docker service update \
  --limit-memory 4g \
  --limit-cpu 2 \
  media-stack_sabnzbd
```

### **Storage Scaling**

- Add storage nodes with shared NFS/CIFS
- Implement distributed storage (GlusterFS, Ceph)
- Use cloud storage for backups

## 🎯 **Best Practices Summary**

1. **Plan Node Roles**: Dedicated storage, compute, and monitoring nodes
2. **Use Labels**: Properly label nodes for optimal service placement
3. **Monitor Health**: Regular health checks and monitoring
4. **Backup Regularly**: Both configs and swarm state
5. **Update Gradually**: Rolling updates for zero downtime
6. **Network Security**: Proper firewall and network segmentation
7. **Resource Limits**: Set appropriate resource constraints
8. **Documentation**: Keep network topology and access info updated

---

**💡 This Swarm setup provides enterprise-grade reliability and scalability for your home media infrastructure while maintaining ease of management.** 