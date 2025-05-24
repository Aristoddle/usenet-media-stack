#!/bin/bash
###############################################################################
#  setup-media-services.sh - Setup and configure Jellyfin, Overseerr, Unpackerr
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Setting up Additional Media Services ==="
echo

# Start the services
echo "Starting services..."
cd "$ROOT_DIR"
echo "fishing123" | sudo -S docker compose -f docker-compose.yml -f docker-compose.media.yml up -d jellyfin overseerr unpackerr tautulli

# Wait for services to be ready
echo
echo "Waiting for services to start..."
sleep 30

# Test service availability
test_service() {
    local name="$1"
    local url="$2"
    local max_attempts=30
    local attempt=0
    
    printf "Testing %-15s" "$name..."
    
    while (( attempt < max_attempts )); do
        local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        
        if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
            echo -e "${GREEN}✓${NC} Accessible at $url"
            return 0
        fi
        
        ((attempt++))
        sleep 2
    done
    
    echo -e "${RED}✗${NC} Not accessible after $max_attempts attempts"
    return 1
}

echo
echo "Testing service availability..."
echo "------------------------------"
test_service "Jellyfin" "http://localhost:8096"
test_service "Overseerr" "http://localhost:5055"
test_service "Tautulli" "http://localhost:8181"

# Create initial configuration for Jellyfin
echo
echo "=== Jellyfin Configuration ==="
echo "1. Open http://localhost:8096 in your browser"
echo "2. Complete the setup wizard:"
echo "   - Skip authentication for local network access"
echo "   - Add media libraries:"
echo "     * Movies: /media/movies"
echo "     * TV Shows: /media/tv"
echo "     * Music: /media/music"
echo "     * Books: /media/books"
echo "     * Comics: /media/comics"
echo "3. Enable DLNA if you want to stream to smart TVs"

# Create Overseerr configuration helper
cat > "$ROOT_DIR/overseerr-config.json" << 'EOF'
{
  "services": {
    "sonarr": {
      "name": "Sonarr",
      "url": "http://sonarr:8989",
      "apiKey": "c0e746db6c604179ac34630df0f2c8fb",
      "qualityProfile": "Any",
      "rootFolder": "/tv"
    },
    "radarr": {
      "name": "Radarr",
      "url": "http://radarr:7878",
      "apiKey": "5685e1e402944f69ac4e0d01cf64b4a1",
      "qualityProfile": "Any",
      "rootFolder": "/movies"
    },
    "jellyfin": {
      "name": "Jellyfin",
      "url": "http://jellyfin:8096",
      "apiKey": "Will be generated during setup"
    }
  },
  "setup_instructions": [
    "1. Open http://localhost:5055",
    "2. Sign in with your Plex account or create local account",
    "3. Add Jellyfin server connection",
    "4. Add Sonarr and Radarr using the details above",
    "5. Configure request limits and approval settings"
  ]
}
EOF

echo
echo "=== Overseerr Configuration ==="
echo "Configuration saved to: overseerr-config.json"
echo "1. Open http://localhost:5055 in your browser"
echo "2. Use the configuration details in overseerr-config.json"

# Check Unpackerr status
echo
echo "=== Unpackerr Status ==="
if echo "fishing123" | sudo -S docker logs unpackerr --tail 20 2>&1 | grep -q "Connected to"; then
    echo -e "${GREEN}✓${NC} Unpackerr is running and connected to services"
else
    echo -e "${YELLOW}⚠${NC} Unpackerr is starting up, check logs with:"
    echo "  docker logs unpackerr"
fi

# Create a test script
cat > "$ROOT_DIR/test-media-services.sh" << 'EOF'
#!/bin/bash
echo "=== Media Services Health Check ==="
echo

# Check Jellyfin
echo -n "Jellyfin:  "
if curl -s http://localhost:8096/health | grep -q "Healthy"; then
    echo "✓ Healthy"
else
    echo "✗ Not responding"
fi

# Check Overseerr
echo -n "Overseerr: "
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5055)
if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
    echo "✓ Running"
else
    echo "✗ Not responding (HTTP $code)"
fi

# Check Unpackerr
echo -n "Unpackerr: "
if docker ps | grep -q unpackerr; then
    echo "✓ Container running"
    echo "  Recent activity:"
    docker logs unpackerr --tail 5 2>&1 | grep -E "(Extract|Connected)" | sed 's/^/  /'
else
    echo "✗ Container not running"
fi

# Check Tautulli
echo -n "Tautulli:  "
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181)
if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
    echo "✓ Running"
else
    echo "✗ Not responding (HTTP $code)"
fi
EOF

chmod +x "$ROOT_DIR/test-media-services.sh"

echo
echo "=== Summary ==="
echo -e "${GREEN}✓${NC} Services started successfully"
echo -e "${GREEN}✓${NC} Test script created: test-media-services.sh"
echo -e "${GREEN}✓${NC} Configuration helper: overseerr-config.json"
echo
echo "Next steps:"
echo "1. Complete Jellyfin setup at http://localhost:8096"
echo "2. Configure Overseerr at http://localhost:5055"
echo "3. Tautulli will auto-detect Jellyfin at http://localhost:8181"
echo "4. Unpackerr is running in the background"
echo
echo "Run ./test-media-services.sh to check service health"