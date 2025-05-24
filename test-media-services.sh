#!/bin/bash
echo "=== Media Services Health Check ==="
echo

# Check Jellyfin
echo -n "Jellyfin:  "
if curl -s http://localhost:8096/health 2>/dev/null | grep -q "Healthy"; then
    echo "✓ Healthy"
else
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8096 2>/dev/null)
    if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
        echo "✓ Running (Setup needed)"
    else
        echo "✗ Not responding (HTTP $code)"
    fi
fi

# Check Overseerr
echo -n "Overseerr: "
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5055 2>/dev/null)
if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
    echo "✓ Running"
else
    echo "✗ Not responding (HTTP $code)"
fi

# Check Unpackerr
echo -n "Unpackerr: "
if docker ps 2>/dev/null | grep -q unpackerr; then
    echo "✓ Container running"
    echo "  Recent activity:"
    docker logs unpackerr --tail 5 2>&1 | grep -E "(Extract|Connected|Started)" | sed 's/^/  /' | head -3
else
    echo "✗ Container not running"
fi

# Check Tautulli
echo -n "Tautulli:  "
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181 2>/dev/null)
if [[ "$code" == "200" ]] || [[ "$code" == "302" ]]; then
    echo "✓ Running"
else
    echo "✗ Not responding (HTTP $code)"
fi

echo
echo "=== Service URLs ==="
echo "Jellyfin:  http://localhost:8096"
echo "Overseerr: http://localhost:5055"
echo "Tautulli:  http://localhost:8181"
echo "Unpackerr: No web UI (check logs with: docker logs unpackerr)"

echo
echo "=== Quick Setup Guide ==="
echo "1. Jellyfin: Complete initial setup wizard"
echo "2. Overseerr: Connect to Jellyfin and *arr services"
echo "3. Tautulli: Will auto-detect Jellyfin after setup"
echo "4. Unpackerr: Already monitoring downloads folder"