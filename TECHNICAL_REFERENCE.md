# Technical Reference Guide

## System Requirements Deep Dive

### Hardware Requirements

#### Minimum Specifications
- **CPU**: 4 cores @ 2.0GHz (Intel i5-6500 or AMD Ryzen 5 2600)
- **RAM**: 8GB DDR4
- **Storage**: 100GB OS + Media storage
- **Network**: Gigabit Ethernet
- **GPU**: Optional (for hardware transcoding)

#### Recommended Specifications
- **CPU**: 8+ cores @ 3.0GHz (Intel i7-10700 or AMD Ryzen 7 5800X)
- **RAM**: 16-32GB DDR4
- **Storage**: 256GB NVMe for OS/Docker + Multiple HDDs for media
- **Network**: Gigabit Ethernet (10Gbit for heavy users)
- **GPU**: Intel QuickSync, NVIDIA NVENC, or AMD VCE capable

#### Resource Allocation by Service
```yaml
# Critical Services (Always need resources)
SABnzbd:      2.0 CPU, 2GB RAM    # Heavy during downloads
Jellyfin:     4.0 CPU, 4GB RAM    # Transcoding spikes

# Standard Services
Sonarr:       1.0 CPU, 512MB RAM  # Spikes during library scan
Radarr:       1.0 CPU, 512MB RAM  # Similar to Sonarr
Prowlarr:     0.5 CPU, 256MB RAM  # Light usage

# Low Priority Services
Bazarr:       0.5 CPU, 256MB RAM  # Minimal resources
Tautulli:     0.5 CPU, 512MB RAM  # Database can grow
```

### Storage Performance Considerations

#### IOPS Requirements
- **Downloads**: 500+ IOPS for parallel unpacking
- **Media Library**: 100+ IOPS for scanning
- **Database**: 1000+ IOPS for responsive UI

#### Recommended Drive Configuration
```
OS/Docker:      NVMe SSD (256GB+)
Downloads:      SSD or fast HDD (500GB+)
Media Library:  HDDs in JBOD (Size as needed)
Backups:        Separate HDD or NAS
```

### Network Bandwidth Planning

#### Usenet Download Speeds
- **60 connections**: ~500 Mbps (62.5 MB/s)
- **100 connections**: ~800 Mbps (100 MB/s)
- **150 connections**: ~1 Gbps (125 MB/s)

#### Streaming Requirements
- **1080p Direct Play**: 10-20 Mbps per stream
- **4K Direct Play**: 50-100 Mbps per stream
- **1080p Transcode**: 4-8 Mbps per stream
- **4K Transcode**: 20-40 Mbps per stream

## Docker Optimization

### Container Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### Volume Mount Optimization
```yaml
volumes:
  # Read-only where possible
  - /media/joe:/media:ro
  
  # Use tmpfs for temporary data
  - type: tmpfs
    target: /tmp
    tmpfs:
      size: 1G
      
  # Bind propagation for dynamic mounts
  - type: bind
    source: /media/joe
    target: /media
    bind:
      propagation: rslave
```

### Network Performance Tuning
```yaml
# Use host networking for performance-critical services
network_mode: host

# Or use macvlan for better isolation with performance
networks:
  macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
```

## API Integration Patterns

### Webhook Integration
```javascript
// Overseerr → Discord webhook
{
  "webhook_url": "https://discord.com/api/webhooks/...",
  "events": ["media.requested", "media.available"],
  "template": {
    "embeds": [{
      "title": "New {{media_type}} Available",
      "description": "{{title}} is now available in Jellyfin",
      "color": 3066993
    }]
  }
}
```

### Custom Scripts Integration
```python
#!/usr/bin/env python3
# Post-processing script for SABnzbd

import sys
import requests

# SABnzbd passes 8 parameters
job_dir = sys.argv[1]
nzb_name = sys.argv[2]
clean_name = sys.argv[3]
index_report = sys.argv[4]
category = sys.argv[5]
group = sys.argv[6]
status = sys.argv[7]
failure_url = sys.argv[8] if len(sys.argv) > 8 else ""

# Custom processing
if status == "0" and category == "movies":
    # Notify Radarr
    requests.post("http://localhost:7878/api/v3/command", 
                  headers={"X-Api-Key": "YOUR_API_KEY"},
                  json={"name": "DownloadedMoviesScan", "path": job_dir})
```

### GraphQL API Usage (Jellyfin)
```graphql
query GetRecentlyAdded {
  items(
    sortBy: DATE_CREATED
    sortOrder: DESC
    limit: 10
    includeItemTypes: ["Movie", "Series"]
  ) {
    items {
      id
      name
      type
      dateCreated
      overview
      communityRating
    }
  }
}
```

## Database Management

### SQLite Optimization
```sql
-- Vacuum and analyze databases
VACUUM;
ANALYZE;

-- Enable WAL mode for better concurrency
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;

-- Optimize cache
PRAGMA cache_size=10000;
PRAGMA temp_store=MEMORY;
```

### Backup Strategies
```bash
#!/bin/bash
# Automated database backup with rotation

BACKUP_DIR="/backups/databases"
RETENTION_DAYS=30

# Backup all SQLite databases
for db in /config/*/**.db; do
    service=$(basename $(dirname "$db"))
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Create backup with compression
    sqlite3 "$db" ".backup stdout" | gzip > "$BACKUP_DIR/${service}_${timestamp}.db.gz"
done

# Cleanup old backups
find "$BACKUP_DIR" -name "*.db.gz" -mtime +$RETENTION_DAYS -delete
```

### Database Maintenance Schedule
```cron
# Crontab for database maintenance
0 3 * * 0 /scripts/vacuum-databases.sh      # Weekly vacuum
0 4 * * * /scripts/backup-databases.sh      # Daily backup
0 5 1 * * /scripts/analyze-databases.sh     # Monthly analyze
```

## Security Hardening

### Docker Security
```yaml
# Security options in docker-compose.yml
security_opt:
  - no-new-privileges:true
  - seccomp:unconfined
  
# Read-only root filesystem
read_only: true
tmpfs:
  - /tmp
  - /var/run
  
# Drop capabilities
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - SETUID
  - SETGID
```

### Network Security
```bash
# iptables rules for service isolation
iptables -N DOCKER-USER-MEDIA
iptables -A DOCKER-USER -j DOCKER-USER-MEDIA

# Allow only local network access to management ports
iptables -A DOCKER-USER-MEDIA -s 192.168.1.0/24 -p tcp --dport 8989 -j ACCEPT
iptables -A DOCKER-USER-MEDIA -p tcp --dport 8989 -j DROP
```

### SSL/TLS Configuration
```nginx
# Nginx SSL configuration for reverse proxy
server {
    listen 443 ssl http2;
    server_name media.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/media.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/media.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
}
```

## Performance Monitoring

### Prometheus Metrics Export
```yaml
# Add Prometheus exporter
prometheus-exporter:
  image: prometheus/node-exporter:latest
  ports:
    - "9100:9100"
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
```

### Custom Metrics Collection
```python
# Custom metrics for media library
from prometheus_client import Gauge, start_http_server

# Define metrics
total_movies = Gauge('media_total_movies', 'Total number of movies')
total_episodes = Gauge('media_total_episodes', 'Total number of TV episodes')
total_size_bytes = Gauge('media_total_size_bytes', 'Total size of media library')

# Update metrics
def update_metrics():
    # Query Radarr API
    movies = requests.get("http://localhost:7878/api/v3/movie",
                         headers={"X-Api-Key": RADARR_API_KEY}).json()
    total_movies.set(len(movies))
    
    # Calculate total size
    size = sum(movie.get('sizeOnDisk', 0) for movie in movies)
    total_size_bytes.set(size)
```

### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "title": "Usenet Media Stack",
    "panels": [
      {
        "title": "Download Speed",
        "targets": [{
          "expr": "rate(sabnzbd_downloaded_bytes_total[5m])"
        }]
      },
      {
        "title": "Library Growth",
        "targets": [{
          "expr": "delta(media_total_movies[24h])"
        }]
      }
    ]
  }
}
```

## Troubleshooting Deep Dive

### Debug Logging Configuration
```yaml
# Enable debug logging per service
environment:
  - LOG_LEVEL=debug
  - VERBOSITY=3
  - DEBUG=true
```

### Container Debugging
```bash
# Enter container with debugging tools
docker run -it --rm \
  --pid container:target_container \
  --net container:target_container \
  --cap-add SYS_PTRACE \
  nicolaka/netshoot

# Inside container
# Check network connectivity
nslookup prowlarr
curl -v http://prowlarr:9696/ping

# Check process issues
ps aux
strace -p PID

# Check file permissions
ls -la /config
stat /downloads
```

### Performance Profiling
```bash
# CPU profiling
docker stats --no-stream
docker top container_name

# Memory analysis
docker exec container_name cat /proc/meminfo
docker exec container_name ps aux --sort=-%mem | head

# I/O analysis
iotop -b -n 1
iostat -x 1
```

## Advanced Automation

### Event-Driven Architecture
```python
# Event handler for media processing
import asyncio
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class MediaEventHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
            
        # New file detected
        if event.src_path.endswith(('.mkv', '.mp4')):
            asyncio.create_task(process_new_media(event.src_path))
    
    async def process_new_media(self, file_path):
        # Extract metadata
        metadata = await extract_metadata(file_path)
        
        # Generate thumbnails
        await generate_thumbnails(file_path)
        
        # Update Jellyfin library
        await trigger_library_scan()
```

### Machine Learning Integration
```python
# Auto-tagging with ML
import tensorflow as tf
from PIL import Image

model = tf.keras.models.load_model('media_classifier.h5')

def auto_tag_media(file_path):
    # Extract frame
    frame = extract_frame(file_path)
    
    # Predict content type
    prediction = model.predict(preprocess_image(frame))
    
    # Apply tags
    tags = decode_predictions(prediction)
    apply_tags_to_media(file_path, tags)
```

### Distributed Processing
```yaml
# Celery worker for background tasks
celery-worker:
  image: custom/media-processor:latest
  command: celery -A tasks worker --loglevel=info
  environment:
    - CELERY_BROKER_URL=redis://redis:6379/0
  volumes:
    - /media/joe:/media
  deploy:
    replicas: 3
```

## Migration Strategies

### From Other Platforms
```bash
# Migrate from Plex to Jellyfin
./scripts/migrate-plex-jellyfin.sh \
  --plex-db /path/to/plex/database \
  --jellyfin-config /config/jellyfin \
  --preserve-watched-status \
  --migrate-users

# Migrate from Sick* to Sonarr/Radarr
./scripts/migrate-sickbeard.sh \
  --source /path/to/sickbeard/db \
  --target-sonarr http://localhost:8989 \
  --api-key YOUR_API_KEY
```

### Backup and Restore
```bash
# Full system backup
./scripts/backup-full-system.sh \
  --include-media \
  --compress \
  --encrypt \
  --destination s3://backup-bucket/usenet-stack/

# Selective restore
./scripts/restore-system.sh \
  --source s3://backup-bucket/usenet-stack/latest \
  --components "configs,databases" \
  --skip-media
```

## Integration Examples

### Home Assistant Integration
```yaml
# configuration.yaml
media_player:
  - platform: jellyfin
    url: http://localhost:8096
    api_key: !secret jellyfin_api_key

sensor:
  - platform: rest
    name: SABnzbd Status
    resource: http://localhost:8080/sabnzbd/api
    params:
      mode: queue
      output: json
      apikey: !secret sabnzbd_api_key
    value_template: '{{ value_json.queue.sizeleft }}'
```

### Telegram Bot Integration
```python
# Telegram bot for media requests
from telegram.ext import Updater, CommandHandler
import requests

def search_movie(update, context):
    query = ' '.join(context.args)
    
    # Search via Overseerr API
    response = requests.get(
        f"http://localhost:5055/api/v1/search",
        params={"query": query},
        headers={"X-Api-Key": OVERSEERR_API_KEY}
    )
    
    results = response.json()['results'][:5]
    
    for movie in results:
        update.message.reply_text(
            f"{movie['title']} ({movie['year']})\n"
            f"⭐ {movie['rating']}/10\n"
            f"/request_{movie['id']}"
        )
```

### Mobile App Integration
```swift
// iOS app for media management
import Foundation

class MediaAPI {
    let baseURL = "http://your-server:8096"
    let apiKey = "your-jellyfin-api-key"
    
    func getRecentlyAdded(completion: @escaping ([MediaItem]) -> Void) {
        let url = URL(string: "\(baseURL)/Items/Latest")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Emby-Token")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            let items = try? JSONDecoder().decode([MediaItem].self, from: data)
            completion(items ?? [])
        }.resume()
    }
}
```

This technical reference provides deep implementation details for advanced users and developers working with the stack.