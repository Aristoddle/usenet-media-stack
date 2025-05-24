#!/bin/bash
# Final validation test - focused on critical functionality

set -e

# Require sudo
if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
fi

echo "=== FINAL VALIDATION TEST ==="
echo "Testing critical functionality of Usenet Media Stack"
echo

# 1. Test all services are accessible
echo "1. Service Accessibility Check:"
services=(
    "SABnzbd:8080"
    "Prowlarr:9696"
    "Sonarr:8989"
    "Radarr:7878"
    "Jellyfin:8096"
    "Overseerr:5055"
    "Bazarr:6767"
    "Netdata:19999"
)

PASS=0
FAIL=0

for service_info in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null)
    if [[ "$response" =~ ^(200|301|302|303|307)$ ]]; then
        echo "✓ $name is accessible on port $port"
        ((PASS++))
    else
        echo "✗ $name not accessible (HTTP $response)"
        ((FAIL++))
    fi
done

echo
echo "2. API Key Validation:"
# SABnzbd
sab_key=$(grep -oP '(?<=api_key = )[^\s]+' config/sabnzbd/sabnzbd.ini 2>/dev/null)
if [[ -n "$sab_key" ]]; then
    if curl -s "http://localhost:8080/sabnzbd/api?mode=version&apikey=$sab_key&output=json" | grep -q "version"; then
        echo "✓ SABnzbd API key valid"
        ((PASS++))
    else
        echo "✗ SABnzbd API key invalid"
        ((FAIL++))
    fi
fi

# Prowlarr
prowlarr_key=$(grep -oP '(?<=<ApiKey>)[^<]+' config/prowlarr/config.xml 2>/dev/null)
if [[ -n "$prowlarr_key" ]]; then
    if curl -s -H "X-Api-Key: $prowlarr_key" "http://localhost:9696/api/v1/system/status" | grep -q "version"; then
        echo "✓ Prowlarr API key valid"
        ((PASS++))
    else
        echo "✗ Prowlarr API key invalid"
        ((FAIL++))
    fi
fi

echo
echo "3. Critical Configurations:"
# SABnzbd providers
if grep -q "\[\[Newshosting\]\]" config/sabnzbd/sabnzbd.ini 2>/dev/null; then
    echo "✓ SABnzbd has Usenet providers configured"
    ((PASS++))
else
    echo "✗ SABnzbd providers not configured"
    ((FAIL++))
fi

# Download directories
if [[ -d "downloads/complete" ]] && [[ -w "downloads/complete" ]]; then
    echo "✓ Download directories exist and are writable"
    ((PASS++))
else
    echo "✗ Download directory issues"
    ((FAIL++))
fi

# Media drives
drives=$(find /media/joe -maxdepth 1 -name "*TB*" -type d 2>/dev/null | wc -l)
if [[ $drives -gt 0 ]]; then
    echo "✓ Found $drives media drives"
    ((PASS++))
else
    echo "✗ No media drives found"
    ((FAIL++))
fi

echo
echo "4. Service Integration:"
# Check if containers can communicate
if docker exec prowlarr ping -c 1 sonarr &>/dev/null; then
    echo "✓ Services can communicate internally"
    ((PASS++))
else
    echo "✗ Service communication issue"
    ((FAIL++))
fi

# Check Jellyfin media access
if docker exec jellyfin ls /media/library &>/dev/null; then
    echo "✓ Jellyfin can access media library"
    ((PASS++))
else
    echo "✗ Jellyfin cannot access media"
    ((FAIL++))
fi

echo
echo "5. Automation Scripts:"
if [[ -x "one-click-setup.sh" ]] && [[ -x "setup-all.sh" ]] && [[ -x "manage.sh" ]]; then
    echo "✓ All automation scripts are executable"
    ((PASS++))
else
    echo "✗ Some automation scripts missing or not executable"
    ((FAIL++))
fi

echo
echo "════════════════════════════════════"
echo "FINAL VALIDATION SUMMARY"
echo "════════════════════════════════════"
echo "✓ Passed: $PASS"
echo "✗ Failed: $FAIL"
echo

if [[ $FAIL -eq 0 ]]; then
    echo "✅ SYSTEM IS FULLY OPERATIONAL!"
    echo
    echo "All critical tests passed. Your Usenet Media Stack is:"
    echo "• All services running and accessible"
    echo "• API keys validated and working"
    echo "• Storage properly configured"
    echo "• Services can communicate"
    echo "• Automation scripts ready"
    echo
    echo "Ready for production use!"
    exit 0
else
    echo "❌ ISSUES DETECTED"
    echo
    echo "Please fix the failed items above before proceeding."
    exit 1
fi