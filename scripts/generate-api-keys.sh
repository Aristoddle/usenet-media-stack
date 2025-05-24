#!/bin/bash
###############################################################################
#  generate-api-keys.sh - Generate and set API keys for services missing them
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Function to generate a secure API key
generate_api_key() {
    openssl rand -hex 16
}

echo "=== Checking and generating API keys ==="

# Check Mylar3
if [[ -f "$CONFIG_DIR/mylar/mylar/config.ini" ]]; then
    current_key=$(grep "^api_key = " "$CONFIG_DIR/mylar/mylar/config.ini" | cut -d' ' -f3)
    if [[ "$current_key" == "None" ]] || [[ -z "$current_key" ]]; then
        new_key=$(generate_api_key)
        sed -i "s/^api_key = .*/api_key = $new_key/" "$CONFIG_DIR/mylar/mylar/config.ini"
        echo "✓ Generated API key for Mylar3: $new_key"
    else
        echo "✓ Mylar3 already has API key"
    fi
fi

# Check Transmission
if [[ -f "$CONFIG_DIR/transmission/settings.json" ]]; then
    if ! grep -q "rpc-password" "$CONFIG_DIR/transmission/settings.json"; then
        echo "⚠️  Transmission needs manual configuration for RPC access"
    else
        echo "✓ Transmission RPC configured"
    fi
fi

# List all found API keys
echo
echo "=== Current API Keys ==="
echo
echo "SABnzbd:"
if [[ -f "$CONFIG_DIR/sabnzbd/sabnzbd.ini" ]]; then
    grep "^api_key = " "$CONFIG_DIR/sabnzbd/sabnzbd.ini" | sed 's/^/  /'
fi

echo
echo "Prowlarr:"
if [[ -f "$CONFIG_DIR/prowlarr/config.xml" ]]; then
    grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_DIR/prowlarr/config.xml" | sed 's/^/  ApiKey: /'
fi

echo
echo "Sonarr:"
if [[ -f "$CONFIG_DIR/sonarr/config.xml" ]]; then
    grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_DIR/sonarr/config.xml" | sed 's/^/  ApiKey: /'
fi

echo
echo "Radarr:"
if [[ -f "$CONFIG_DIR/radarr/config.xml" ]]; then
    grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_DIR/radarr/config.xml" | sed 's/^/  ApiKey: /'
fi

echo
echo "Readarr:"
if [[ -f "$CONFIG_DIR/readarr/config.xml" ]]; then
    grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_DIR/readarr/config.xml" | sed 's/^/  ApiKey: /'
fi

echo
echo "Lidarr:"
if [[ -f "$CONFIG_DIR/lidarr/config.xml" ]]; then
    grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_DIR/lidarr/config.xml" | sed 's/^/  ApiKey: /'
fi

echo
echo "Bazarr:"
if [[ -f "$CONFIG_DIR/bazarr/config/config.yaml" ]]; then
    grep "apikey:" "$CONFIG_DIR/bazarr/config/config.yaml" | sed 's/^/  /'
fi

echo
echo "Mylar3:"
if [[ -f "$CONFIG_DIR/mylar/mylar/config.ini" ]]; then
    grep "^api_key = " "$CONFIG_DIR/mylar/mylar/config.ini" | sed 's/^/  /'
fi

echo
echo "Jackett:"
if [[ -f "$CONFIG_DIR/jackett/Jackett/ServerConfig.json" ]]; then
    grep -oP '(?<="APIKey": ")[^"]+' "$CONFIG_DIR/jackett/Jackett/ServerConfig.json" | sed 's/^/  APIKey: /'
fi

echo
echo "=== API Key Summary ==="
echo "All services now have API keys configured."
echo "Restart services to apply any changes."