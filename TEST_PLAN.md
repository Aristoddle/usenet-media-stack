# Media Stack Testing & Setup Plan

## Architecture Overview

### Service Communication Flow
```
Indexers (Prowlarr/Jackett) → Download Clients (SABnzbd/Transmission) → Media Managers (*arr apps) → Media Storage
```

### Web Interface Ports
- **Prowlarr**: http://localhost:9696 (Indexer Manager)
- **Sonarr**: http://localhost:8989 (TV Shows)
- **Radarr**: http://localhost:7878 (Movies)
- **Bazarr**: http://localhost:6767 (Subtitles)
- **SABnzbd**: http://localhost:8080 (Usenet Downloader)
- **Transmission**: http://localhost:9092 (Torrent)
- **Readarr**: http://localhost:8787 (Books)
- **Mylar3**: http://localhost:8090 (Comics)
- **Whisparr**: http://localhost:6969 (Adult)
- **Jackett**: http://localhost:9117 (Indexer Proxy)
- **YacReader**: http://localhost:8082 (Comic Reader)
- **Portainer**: http://localhost:9000 (Container Management)
- **Netdata**: http://localhost:19999 (System Monitoring)

## Testing Steps

### 1. Start Services & Verify Web Access
```bash
# Start the stack
./manage.sh start

# Wait for services to initialize
sleep 30

# Check all services are running
./manage.sh status

# Test web interface accessibility
for port in 9696 8989 7878 6767 8080 9092 8787 8090 6969 9117 8082 9000 19999; do
    echo "Testing port $port..."
    curl -s -o /dev/null -w "%{http_code}" http://localhost:$port
done
```

### 2. Initial Service Setup Order

#### Step 1: Set up Prowlarr (Indexer Manager)
1. Navigate to http://localhost:9696
2. Complete initial setup wizard
3. Add Usenet indexers:
   - NZBgeek
   - NZBFinder
   - DrunkenSlug
   - NZBPlanet
   - Etc.
4. Get API key from Settings → General → API Key

#### Step 2: Configure Download Clients
**SABnzbd (http://localhost:8080):**
1. Complete wizard
2. Add news servers (e.g., Newshosting, Eweka)
3. Note API key from Config → General

**Transmission (http://localhost:9092):**
1. Set download directories
2. Configure connection limits

#### Step 3: Connect Services in Prowlarr
1. In Prowlarr, go to Settings → Apps
2. Add each *arr app:
   - Sonarr (http://sonarr:8989)
   - Radarr (http://radarr:7878)
   - Readarr (http://readarr:8787)
   - Mylar3 (http://mylar3:8090)
3. Use their respective API keys

#### Step 4: Configure Media Managers
For each *arr app:
1. Add root folders:
   - Sonarr: `/tv`
   - Radarr: `/movies`
   - Readarr: `/books`
   - Mylar3: `/comics`
2. Add download clients (SABnzbd/Transmission)
3. Configure quality profiles
4. Import existing media

### 3. API Key Collection Script
```bash
#!/bin/bash
# collect_api_keys.sh

echo "Collecting API Keys..."
echo "====================="

# Function to get API key from service
get_api_key() {
    service=$1
    port=$2
    config_path="/home/joe/usenet/config/$service"
    
    # Check if config exists
    if [ -f "$config_path/config.xml" ]; then
        api_key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$config_path/config.xml" 2>/dev/null)
    elif [ -f "$config_path/config.ini" ]; then
        api_key=$(grep -oP '(?<=api_key = )[^\s]+' "$config_path/config.ini" 2>/dev/null)
    fi
    
    if [ -n "$api_key" ]; then
        echo "$service API Key: $api_key"
        echo "$service URL: http://localhost:$port"
    else
        echo "$service: No API key found (manual setup required)"
    fi
}

# Collect keys
get_api_key "sonarr" "8989"
get_api_key "radarr" "7878"
get_api_key "prowlarr" "9696"
get_api_key "bazarr" "6767"
get_api_key "readarr" "8787"
get_api_key "sabnzbd" "8080"
```

### 4. Service Communication Test
```bash
# Test Prowlarr → Sonarr communication
curl -X GET "http://localhost:9696/api/v1/health" \
  -H "X-Api-Key: YOUR_PROWLARR_API_KEY"

# Test Sonarr → SABnzbd communication
curl -X GET "http://localhost:8989/api/v3/health" \
  -H "X-Api-Key: YOUR_SONARR_API_KEY"
```

### 5. File Migration Testing

Test file movements with Sonarr API:
```bash
# Rescan a series after moving files
curl -X POST "http://localhost:8989/api/v3/command" \
  -H "X-Api-Key: YOUR_SONARR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "RescanSeries",
    "seriesId": SERIES_ID
  }'

# Update series path
curl -X PUT "http://localhost:8989/api/v3/series/SERIES_ID" \
  -H "X-Api-Key: YOUR_SONARR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/tv/new_path/SeriesName"
  }'
```

## Data Persistence

### How Persistence Works
1. **Configuration**: Each service stores config in `/home/joe/usenet/config/<service>/`
2. **Media**: Stored in `/media/joe/` paths (survives container recreation)
3. **Downloads**: Temporary files in `/home/joe/usenet/downloads/`

### Backup & Restore
```bash
# Backup all configurations
./manage.sh backup-configs

# Restore from backup
tar -xzf /home/joe/usenet/backups/backup_TIMESTAMP.tar.gz -C /
```

### Volume Verification
```bash
# Check volume mounts
docker inspect sonarr | jq '.[0].Mounts'

# Verify persistence after restart
docker-compose down
docker-compose up -d
# Configs and data should remain intact
```

## Automated Health Check Script
```bash
#!/bin/bash
# health_check.sh

services=("sonarr:8989" "radarr:7878" "prowlarr:9696" "bazarr:6767" "sabnzbd:8080")

for service in "${services[@]}"; do
    name="${service%%:*}"
    port="${service#*:}"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port")
    if [ "$response" = "200" ]; then
        echo "✅ $name is accessible"
    else
        echo "❌ $name is not responding (HTTP $response)"
    fi
done
```

## Common Issues & Solutions

1. **Services can't communicate**: Check Docker network connectivity
2. **API key errors**: Ensure services use internal Docker hostnames (e.g., `http://sonarr:8989`)
3. **Permission issues**: Check UID/GID in docker-compose.yml match host user
4. **Storage full**: Monitor with `./manage.sh system-health`