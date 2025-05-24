#!/bin/bash
# Automated Prowlarr configuration script

echo "=== PROWLARR AUTOMATED CONFIGURATION ==="
echo "This script will configure Prowlarr with your Usenet indexers"
echo

# Configuration
PROWLARR_URL="http://localhost:9696"
PROWLARR_API_KEY=""  # Will be filled after Prowlarr is set up

# Indexer configurations
declare -A INDEXERS=(
    ["NZBgeek"]='{"name":"NZBgeek","fields":[{"name":"baseUrl","value":"https://api.nzbgeek.info"},{"name":"apiKey","value":"SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a"},{"name":"categories","value":[2000,2010,2020,2030,2035,2040,2045,2050,2060,3000,3010,3020,3030,3040,5000,5030,5040,5045,5070,6000,6010,6020,6030,6040,6050,6060,6070,6090,7000,7010,7020,7030,8010]}],"configContract":"NzbgeekSettings","implementation":"Newznab","implementationName":"Newznab","enable":true,"protocol":"usenet","priority":25,"appProfileId":1}'
    ["NZBFinder"]='{"name":"NZB Finder","fields":[{"name":"baseUrl","value":"https://nzbfinder.ws"},{"name":"apiKey","value":"14b3d53dbd98adc79fed0d336998536a"},{"name":"categories","value":[2000,2010,2020,2030,2035,2040,2045,2050,2060,3000,3010,3020,3030,3040,5000,5030,5040,5045,5070,6000,6010,6020,6030,6040,6050,6060,6070,6090,7000,7010,7020,7030,8010]}],"configContract":"NewznabSettings","implementation":"Newznab","implementationName":"Newznab","enable":true,"protocol":"usenet","priority":25,"appProfileId":1}'
    ["NZBsu"]='{"name":"NZB.su","fields":[{"name":"baseUrl","value":"https://api.nzb.su"},{"name":"apiKey","value":"25ba450623c248e2b58a3c0dc54aa019"},{"name":"categories","value":[2000,2010,2020,2030,2035,2040,2045,2050,2060,3000,3010,3020,3030,3040,5000,5030,5040,5045,5070,6000,6010,6020,6030,6040,6050,6060,6070,6090,7000,7010,7020,7030,8010]}],"configContract":"NewznabSettings","implementation":"Newznab","implementationName":"Newznab","enable":true,"protocol":"usenet","priority":25,"appProfileId":1}'
    ["NZBPlanet"]='{"name":"NZBPlanet","fields":[{"name":"baseUrl","value":"https://api.nzbplanet.net"},{"name":"apiKey","value":"046863416d824143c79b6725982e293d"},{"name":"categories","value":[2000,2010,2020,2030,2035,2040,2045,2050,2060,3000,3010,3020,3030,3040,5000,5030,5040,5045,5070,6000,6010,6020,6030,6040,6050,6060,6070,6090,7000,7010,7020,7030,8010]}],"configContract":"NewznabSettings","implementation":"Newznab","implementationName":"Newznab","enable":true,"protocol":"usenet","priority":25,"appProfileId":1}'
)

# Function to check if Prowlarr is running
check_prowlarr() {
    echo "Checking if Prowlarr is accessible..."
    if curl -s -o /dev/null -w "%{http_code}" "$PROWLARR_URL" | grep -q "200\|301\|302"; then
        echo "✅ Prowlarr is running at $PROWLARR_URL"
        return 0
    else
        echo "❌ Prowlarr is not accessible at $PROWLARR_URL"
        echo "   Please start Prowlarr first: ./manage.sh start"
        return 1
    fi
}

# Function to get Prowlarr API key
get_prowlarr_api_key() {
    echo
    echo "To configure Prowlarr, we need its API key."
    echo "1. Open Prowlarr at $PROWLARR_URL"
    echo "2. Go to Settings > General"
    echo "3. Copy the API Key"
    echo
    read -p "Enter Prowlarr API Key: " PROWLARR_API_KEY
    
    if [ -z "$PROWLARR_API_KEY" ]; then
        echo "❌ API Key is required"
        return 1
    fi
    
    # Test the API key
    if curl -s -H "X-Api-Key: $PROWLARR_API_KEY" "$PROWLARR_URL/api/v1/health" | grep -q "source"; then
        echo "✅ API Key is valid"
        return 0
    else
        echo "❌ Invalid API Key"
        return 1
    fi
}

# Function to add an indexer
add_indexer() {
    local name="$1"
    local config="$2"
    
    echo "Adding $name..."
    
    response=$(curl -s -X POST "$PROWLARR_URL/api/v1/indexer" \
        -H "X-Api-Key: $PROWLARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$config")
    
    if echo "$response" | grep -q "id"; then
        echo "✅ $name added successfully"
    else
        echo "❌ Failed to add $name: $response"
    fi
}

# Function to configure apps (Sonarr, Radarr, etc.)
configure_apps() {
    echo
    echo "=== CONFIGURING APPLICATIONS ==="
    echo
    
    # Sonarr configuration
    cat <<EOF
To connect Sonarr to Prowlarr:
1. In Prowlarr, go to Settings > Apps
2. Click the + button and select Sonarr
3. Use these settings:
   - Name: Sonarr
   - Prowlarr Server: http://prowlarr:9696
   - Sonarr Server: http://sonarr:8989
   - API Key: [Get from Sonarr Settings > General]
   - Sync Categories: TV/HD, TV/SD, TV/UHD
   
Repeat for:
- Radarr (http://radarr:7878) - Movies categories
- Readarr (http://readarr:8787) - Books categories
- Mylar3 (http://mylar3:8090) - Comics categories
EOF
}

# Function to configure download clients
configure_download_clients() {
    echo
    echo "=== DOWNLOAD CLIENT CONFIGURATION ==="
    echo
    
    cat <<EOF
SABnzbd Configuration:
1. Server: http://sabnzbd:8080
2. API Key: 0b544ecf089649f0ba8905d869a88f22
3. Categories:
   - tv (for Sonarr)
   - movies (for Radarr)
   - books (for Readarr)
   - comics (for Mylar3)

Usenet Providers in SABnzbd:
1. Newshosting:
   - Server: news.newshosting.com
   - SSL Port: 563
   - Username: j3lanzone@gmail.com
   - Password: @Kirsten123
   - Connections: 30

2. UsenetExpress:
   - Server: usenetexpress.com
   - SSL Port: 563
   - Username: une3226253
   - Password: kKqzQXPeN
   - Connections: 20

3. Frugalusenet:
   - Server: newswest.frugalusenet.com
   - SSL Port: 563
   - Username: aristoddle
   - Password: fishing123
   - Connections: 10
   - Backup: bonus.frugalusenet.com
EOF
}

# Main execution
main() {
    echo "Starting Prowlarr configuration..."
    echo
    
    # Check if Prowlarr is running
    if ! check_prowlarr; then
        exit 1
    fi
    
    # Get API key
    if ! get_prowlarr_api_key; then
        exit 1
    fi
    
    # Add indexers
    echo
    echo "=== ADDING INDEXERS ==="
    for indexer in "${!INDEXERS[@]}"; do
        add_indexer "$indexer" "${INDEXERS[$indexer]}"
        sleep 1
    done
    
    # Show app configuration
    configure_apps
    
    # Show download client configuration
    configure_download_clients
    
    echo
    echo "=== CONFIGURATION COMPLETE ==="
    echo "✅ Indexers have been added to Prowlarr"
    echo "📋 Follow the manual steps above to complete the setup"
    echo
    echo "Next steps:"
    echo "1. Configure apps in Prowlarr (Sonarr, Radarr, etc.)"
    echo "2. Add Usenet providers to SABnzbd"
    echo "3. Test indexer connections"
    echo "4. Start searching!"
}

# Run main function
main