# Storage Architecture & Remote Access

> **Last Updated**: 2025-12-29
> **Status**: Production configuration, boot-persistent

This document covers the complete storage setup and remote access configuration for the media stack.

---

## Storage Overview

| Storage Tier | Mount Point | Size | Purpose |
|--------------|-------------|------|---------|
| **Primary NVMe** | `/var/mnt/fast8tb` | 8TB | Config, OneDrive sync, high-speed access |
| **MergerFS Pool** | `/var/mnt/pool` | 41TB | Media library (movies, TV, anime) |
| **Individual NVMe** | `/var/mnt/Fast_*` | 4-8TB each | Pool members (8 drives) |

---

## MergerFS Configuration

### What is MergerFS?

MergerFS creates a **union filesystem** that presents multiple drives as a single mount point. Files are distributed across drives based on policies, but appear as one unified directory.

```
/var/mnt/pool/           <-- Single unified view (41TB)
    ├── movies/
    ├── tv/
    └── anime-tv/
         │
         ├── Actually on /var/mnt/Fast_4TB_1
         ├── Actually on /var/mnt/Fast_8TB_2
         └── Actually on /var/mnt/Fast_4TB_3
```

### Pool Members (8 Drives)

| Drive | Size | Mount Point |
|-------|------|-------------|
| Fast_4TB_1 | 4TB | `/var/mnt/Fast_4TB_1` |
| Fast_4TB_2 | 4TB | `/var/mnt/Fast_4TB_2` |
| Fast_4TB_3 | 4TB | `/var/mnt/Fast_4TB_3` |
| Fast_4TB_4 | 4TB | `/var/mnt/Fast_4TB_4` |
| Fast_4TB_5 | 4TB | `/var/mnt/Fast_4TB_5` |
| Fast_8TB_1 | 8TB | `/var/mnt/Fast_8TB_1` |
| Fast_8TB_2 | 8TB | `/var/mnt/Fast_8TB_2` |
| Fast_8TB_3 | 8TB | `/var/mnt/Fast_8TB_3` |

### Mount Command

```bash
mergerfs -o defaults,allow_other,use_ino,cache.files=auto-full,dropcacheonclose=false,category.create=mfs,moveonenospc=true,minfreespace=50G,fsname=mergerfs-pool \
  /var/mnt/Fast_4TB_1:/var/mnt/Fast_4TB_2:/var/mnt/Fast_4TB_3:/var/mnt/Fast_4TB_4:/var/mnt/Fast_4TB_5:/var/mnt/Fast_8TB_1:/var/mnt/Fast_8TB_2:/var/mnt/Fast_8TB_3 \
  /var/mnt/pool
```

### Mount Options Explained

| Option | Value | Why It Matters |
|--------|-------|----------------|
| `cache.files` | `auto-full` | **CRITICAL**: Uses Linux page cache for file data. Without this, every read hits disk, causing massive CPU overhead. |
| `dropcacheonclose` | `false` | **CRITICAL**: Keeps cached data after file close. Set to `true` caused 286% CPU usage! |
| `category.create` | `mfs` | Most-free-space policy for new files. Spreads writes across drives with most room. |
| `moveonenospc` | `true` | Auto-migrate files if destination drive is full during write. |
| `minfreespace` | `50G` | Reserve 50GB per drive before considering it "full". |
| `allow_other` | - | Docker containers (running as different users) can access the mount. |
| `use_ino` | - | Preserve inode numbers for hardlink support. |
| `fsname` | `mergerfs-pool` | Friendly name in `df` and `mount` output. |

### Performance Impact of Caching

| Setting | CPU Usage | I/O Latency | Notes |
|---------|-----------|-------------|-------|
| `cache.files=off` | **286%** | High | Every operation hits disk |
| `cache.files=auto-full` | **0-5%** | Low | Linux page cache handles reads |

On a 96GB RAM system, the page cache can hold 40-60GB of frequently accessed file data, eliminating most disk reads.

### Boot Persistence (Systemd Service)

The pool auto-mounts on boot via systemd:

```bash
# Service file location
/etc/systemd/system/mergerfs-pool.service

# Check status
systemctl status mergerfs-pool.service

# Manual control
sudo systemctl start mergerfs-pool.service
sudo systemctl stop mergerfs-pool.service
```

**Service Dependencies**: Requires all 8 drive mounts to be ready before starting.

---

## Docker Volume Mapping

All containers access media through the pool:

```yaml
# In docker-compose.yml
volumes:
  - /var/mnt/pool/movies:/movies
  - /var/mnt/pool/tv:/tv
  - /var/mnt/pool/anime-tv:/anime-tv
  - /var/mnt/pool/downloads:/downloads
```

**Why `/pool` not `/var/mnt/pool`?**

Container paths are simplified. The host path `/var/mnt/pool/movies` maps to `/movies` inside containers. This makes *arr app configuration cleaner.

---

## Remote Access with Tailscale

### The Problem

ISP (Live Oak Fiber) rotates external IP addresses aggressively. Port forwarding and DDNS solutions break frequently.

### The Solution

**Tailscale** provides a mesh VPN with stable IPs:

- Server gets fixed IP: `100.115.21.9`
- Works regardless of ISP IP changes
- More secure than port forwarding (no public exposure)
- WireGuard encryption end-to-end

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     Tailscale Network                       │
│                                                             │
│   ┌──────────────┐  WireGuard   ┌──────────────┐           │
│   │ Media Server │◄────────────►│ Your Phone   │           │
│   │ 100.115.21.9 │   (encrypted)│ 100.x.x.x    │           │
│   └──────────────┘              └──────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### Accessing Services

From any Tailscale-connected device:

| Service | URL |
|---------|-----|
| Plex | `http://100.115.21.9:32400` |
| Sonarr | `http://100.115.21.9:8989` |
| Radarr | `http://100.115.21.9:7878` |
| SABnzbd | `http://100.115.21.9:8080` |
| Prowlarr | `http://100.115.21.9:9696` |
| Tdarr | `http://100.115.21.9:8265` |
| Overseerr | `http://100.115.21.9:5055` |

### Plex Configuration

In Plex Settings → Network:

1. **Custom server access URLs**: `http://100.115.21.9:32400`
2. **LAN Networks**: `100.64.0.0/10` (Tailscale CGNAT range)
3. **Secure connections**: "Preferred"
4. **Remote access**: Can disable traditional port forwarding

### Security Comparison

| Aspect | Port Forwarding | Tailscale |
|--------|-----------------|-----------|
| Internet exposure | Yes (public) | No (mesh only) |
| Brute force risk | High | Very low |
| ISP dependency | Static IP/DDNS | None |
| Encryption | Per-service TLS | Always WireGuard |
| Setup complexity | Router config | Install & login |

### Adding Devices to Tailscale

```bash
# On any device
tailscale up

# Check network status
tailscale status
```

---

## Troubleshooting

### MergerFS High CPU

**Symptom**: `mergerfs` process using 200%+ CPU

**Cause**: Caching disabled (`cache.files=off` or `dropcacheonclose=true`)

**Fix**:
```bash
# Unmount and remount with correct options
sudo umount /var/mnt/pool
sudo systemctl start mergerfs-pool.service
```

### Pool Not Mounting on Boot

**Check**: Are the underlying drives mounted first?

```bash
systemctl list-units --type=mount | grep Fast
```

**Fix**: The systemd service requires all drive mounts. Ensure drives are in fstab or auto-mounted.

### Containers Can't Access Pool

**Symptom**: Permission denied or empty directories in containers

**Check**:
```bash
# Verify pool is mounted
mount | grep mergerfs

# Check permissions
ls -la /var/mnt/pool/
```

**Fix**: Ensure `allow_other` is in mount options.

### Tdarr Socket Errors After Pool Remount

**Symptom**: `ENOTCONN: socket is not connected` errors

**Fix**: Restart Tdarr containers:
```bash
docker compose restart tdarr tdarr-node
```

---

## Verification Commands

```bash
# Pool status
df -h /var/mnt/pool

# Cache settings
getfattr -n user.mergerfs.cache.files /var/mnt/pool/.mergerfs

# MergerFS process (should be ONE, low CPU)
ps aux | grep mergerfs | grep -v grep

# RAM cache usage
free -h

# Tailscale status
tailscale status
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/systemd/system/mergerfs-pool.service` | Boot persistence |
| `~/.local/bin/mount-mergerfs-pool.sh` | Manual mount script |
| `docker-compose.yml` | Container volume mappings |
| `.env` | Pool path variables |
