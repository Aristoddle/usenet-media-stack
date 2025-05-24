#!/bin/bash

echo "=== Quick System Status Check ==="
echo

# 1. Check core services
echo "Core Services:"
for service in sabnzbd prowlarr sonarr radarr jellyfin overseerr; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$(docker port $service 2>/dev/null | grep -oP '\d+$' | head -1)" 2>/dev/null || echo "000")
    if [[ "$CODE" =~ ^(200|301|302|303|307)$ ]]; then
        echo "✓ $service is accessible (HTTP $CODE)"
    else
        echo "✗ $service not accessible (HTTP $CODE)"
    fi
done

echo
echo "API Keys Found:"
# Check API keys
[[ -n "$(grep -oP '(?<=api_key = )[^\s]+' config/sabnzbd/sabnzbd.ini 2>/dev/null)" ]] && echo "✓ SABnzbd"
[[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' config/prowlarr/config.xml 2>/dev/null)" ]] && echo "✓ Prowlarr"
[[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' config/sonarr/config.xml 2>/dev/null)" ]] && echo "✓ Sonarr"
[[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' config/radarr/config.xml 2>/dev/null)" ]] && echo "✓ Radarr"

echo
echo "Storage:"
# Check drives
echo "Found $(find /media/joe -maxdepth 1 -name "*TB*" -type d 2>/dev/null | wc -l) drives under /media/joe"

echo
echo "Quick URLs to test:"
echo "- Jellyfin: http://localhost:8096"
echo "- Overseerr: http://localhost:5055"
echo "- SABnzbd: http://localhost:8080"
echo "- Prowlarr: http://localhost:9696"