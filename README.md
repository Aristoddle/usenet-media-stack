# Complete Media Automation Stack (Usenet + *arr Services)

A comprehensive Docker Compose setup for automated media management using the *arr family of applications.

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/Aristoddle/home-media-server.git
cd home-media-server

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

## 📋 Services Included

| Service | Port | Purpose | Web Interface |
|---------|------|---------|---------------|
| **SABnzbd** | 8080 | Usenet downloader | http://localhost:8080 |
| **Transmission** | 9092 | BitTorrent client | http://localhost:9092 |
| **Sonarr** | 8989 | TV show management | http://localhost:8989 |
| **Radarr** | 7878 | Movie management | http://localhost:7878 |
| **Bazarr** | 6767 | Subtitle management | http://localhost:6767 |
| **Prowlarr** | 9696 | Indexer management | http://localhost:9696 |
| **Whisparr** | 6969 | Adult content management | http://localhost:6969 |
| **Readarr** | 8787 | Ebook management | http://localhost:8787 |
| **Mylar3** | 8090 | Comic book management | http://localhost:8090 |
| **YacReader** | 8082 | Comic reader & library | http://localhost:8082 |
| **Jackett** | 9117 | Indexer proxy (fallback) | http://localhost:9117 |

## 💾 Storage Architecture

This setup uses a **JBOD (Just a Bunch of Disks)** configuration with intelligent tiering:

### Fast Storage (Primary)
- `/media/joe/Fast_8TB_[1-3]` - High-performance storage for new content
- `/media/joe/Fast_4TB_[1-5]` - Additional fast storage

### Archive Storage  
- `/media/joe/Slow_4TB_[1-2]` - Archival storage for less accessed content
- `/media/joe/Slow_2TB_[1-2]` - Additional archive storage

### Directory Structure
```
~/usenet/
├── config/           # Service configurations
│   ├── sonarr/
│   ├── radarr/
│   ├── sabnzbd/
│   └── ...
├── downloads/        # Centralized download location
└── media/           # Local media (if not using external drives)
    ├── movies/
    ├── tv/
    ├── books/
    └── comics/
```

## ⚙️ Configuration

### First Time Setup

1. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

2. **Configure each service:**
   - Open each web interface and complete initial setup
   - Configure download paths to `/downloads`
   - Set up indexers in Prowlarr first, then sync to other services

3. **Storage Configuration:**
   - In Sonarr/Radarr, add multiple root folders pointing to different drives
   - Use fast drives for high-quality/4K content
   - Use slow drives for standard/archival content

### MergerFS Integration (Optional)

For a unified storage view, install MergerFS:

```bash
# Install MergerFS
sudo apt install mergerfs

# Add to /etc/fstab
/media/joe/Fast_*:/media/joe/Slow_* /mnt/media fuse.mergerfs defaults,allow_other,use_ino 0 0

# Mount
sudo mount -a
```

Then uncomment the MergerFS volume lines in `docker-compose.yml`.

## 🔧 Management Commands

```bash
# Start all services
docker-compose up -d

# Stop all services  
docker-compose down

# View logs
docker-compose logs -f [service_name]

# Update services
docker-compose pull
docker-compose up -d

# Restart a specific service
docker-compose restart sonarr

# Check service status
docker-compose ps
```

## 📊 System Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: Varies based on media collection size
- **Network**: Unlimited bandwidth recommended for Usenet

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Errors:**
   ```bash
   sudo chown -R 1000:1000 ~/usenet/config
   sudo chown -R 1000:1000 ~/usenet/downloads
   ```

2. **Service Won't Start:**
   ```bash
   docker-compose logs [service_name]
   ```

3. **Storage Issues:**
   - Check drive mounts: `df -h`
   - Verify permissions on media directories

### Health Checks

```bash
# Check all container status
docker-compose ps

# Check system resources
docker stats

# View service logs
docker-compose logs -f --tail=50
```

## 🔐 Security Notes

- All services run as user 1000:1000 for security
- Consider using a VPN for BitTorrent traffic
- Regularly update containers for security patches
- Use strong passwords for web interfaces

## 📖 Additional Resources

- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [SABnzbd Documentation](https://sabnzbd.org/wiki/)
- [Prowlarr Documentation](https://wiki.servarr.com/prowlarr)

## 📝 License

This configuration is provided as-is under the MIT License.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Note:** This setup is designed for personal use. Ensure compliance with local laws regarding content downloading and sharing. 