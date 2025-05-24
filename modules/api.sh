#!/bin/bash
###############################################################################
#  modules/api.sh - API interaction functions for Usenet services
###############################################################################

# SABnzbd API functions
sabnzbd_api() {
  local endpoint="$1"
  local method="${2:-GET}"
  local data="${3:-}"
  local url="${SERVICE_URLS[sabnzbd]}/sabnzbd/api"
  
  local curl_args=(
    -s
    -X "$method"
    -H "Content-Type: application/x-www-form-urlencoded"
  )
  
  # Add data for POST requests
  if [[ "$method" == "POST" && -n "$data" ]]; then
    curl_args+=(-d "$data")
  fi
  
  # Always include API key and output format
  if [[ "$url" == *"?"* ]]; then
    url="${url}&apikey=${SABNZBD_API_KEY}&output=json"
  else
    url="${url}?apikey=${SABNZBD_API_KEY}&output=json"
  fi
  
  curl "${curl_args[@]}" "$url"
}

# Add SABnzbd server
sabnzbd_add_server() {
  local name="$1"
  local host="$2"
  local port="$3"
  local username="$4"
  local password="$5"
  local connections="$6"
  local priority="${7:-0}"
  
  verbose "Adding SABnzbd server: $name"
  
  local data="mode=set_config&section=servers&keyword=${name}&\
host=${host}&\
port=${port}&\
username=${username}&\
password=${password}&\
connections=${connections}&\
ssl=1&\
priority=${priority}&\
enable=1"
  
  local response=$(sabnzbd_api "" "POST" "$data")
  
  if echo "$response" | grep -q "true\|ok"; then
    success "Added server: $name"
    return 0
  else
    error "Failed to add server: $name"
    verbose "Response: $response"
    return 1
  fi
}

# Configure SABnzbd categories
sabnzbd_add_category() {
  local name="$1"
  local folder="$2"
  local priority="${3:-0}"
  
  verbose "Adding SABnzbd category: $name"
  
  local data="mode=set_config&section=categories&keyword=${name}&\
pp=3&\
script=None&\
dir=${folder}&\
priority=${priority}"
  
  local response=$(sabnzbd_api "" "POST" "$data")
  
  if echo "$response" | grep -q "true\|ok"; then
    success "Added category: $name"
    return 0
  else
    error "Failed to add category: $name"
    return 1
  fi
}

# Prowlarr API functions
prowlarr_api() {
  local endpoint="$1"
  local method="${2:-GET}"
  local data="${3:-}"
  local api_key="${4:-$(get_service_api_key prowlarr)}"
  
  if [[ -z "$api_key" ]]; then
    error "Prowlarr API key not found"
    return 1
  fi
  
  local url="${SERVICE_URLS[prowlarr]}/api/v1/${endpoint}"
  
  local curl_args=(
    -s
    -X "$method"
    -H "X-Api-Key: $api_key"
    -H "Content-Type: application/json"
  )
  
  if [[ "$method" != "GET" && -n "$data" ]]; then
    curl_args+=(-d "$data")
  fi
  
  curl "${curl_args[@]}" "$url"
}

# Add Prowlarr indexer
prowlarr_add_indexer() {
  local name="$1"
  local api_key="$2"
  local base_url="$3"
  local prowlarr_key="${4:-$(get_service_api_key prowlarr)}"
  
  verbose "Adding Prowlarr indexer: $name"
  
  # Determine base URL from indexer name
  case "$name" in
    "NZBgeek") base_url="https://api.nzbgeek.info" ;;
    "NZB Finder") base_url="https://nzbfinder.ws" ;;
    "NZB.su") base_url="https://api.nzb.su" ;;
    "NZBPlanet") base_url="https://api.nzbplanet.net" ;;
  esac
  
  local data=$(cat <<EOF
{
  "name": "$name",
  "fields": [
    {"name": "baseUrl", "value": "$base_url"},
    {"name": "apiKey", "value": "$api_key"},
    {"name": "categories", "value": [2000,2010,2020,2030,2035,2040,2045,2050,2060,3000,3010,3020,3030,3040,5000,5030,5040,5045,5070,6000,6010,6020,6030,6040,6050,6060,6070,6090,7000,7010,7020,7030,8010]}
  ],
  "configContract": "NewznabSettings",
  "implementation": "Newznab",
  "implementationName": "Newznab",
  "enable": true,
  "protocol": "usenet",
  "priority": 25,
  "appProfileId": 1
}
EOF
)
  
  local response=$(prowlarr_api "indexer" "POST" "$data" "$prowlarr_key")
  
  if echo "$response" | grep -q '"id"'; then
    success "Added indexer: $name"
    return 0
  else
    error "Failed to add indexer: $name"
    verbose "Response: $response"
    return 1
  fi
}

# Add application to Prowlarr
prowlarr_add_app() {
  local name="$1"
  local base_url="$2"
  local api_key="$3"
  local sync_categories="$4"
  local prowlarr_key="${5:-$(get_service_api_key prowlarr)}"
  
  verbose "Adding app to Prowlarr: $name"
  
  local data=$(cat <<EOF
{
  "name": "$name",
  "fields": [
    {"name": "prowlarrUrl", "value": "http://prowlarr:9696"},
    {"name": "baseUrl", "value": "$base_url"},
    {"name": "apiKey", "value": "$api_key"},
    {"name": "syncCategories", "value": $sync_categories}
  ],
  "configContract": "${name}Settings",
  "implementation": "$name",
  "implementationName": "$name",
  "syncLevel": "fullSync",
  "tags": []
}
EOF
)
  
  local response=$(prowlarr_api "applications" "POST" "$data" "$prowlarr_key")
  
  if echo "$response" | grep -q '"id"'; then
    success "Added app: $name"
    return 0
  else
    error "Failed to add app: $name"
    verbose "Response: $response"
    return 1
  fi
}

# Generic arr app API function
arr_api() {
  local app="$1"
  local endpoint="$2"
  local method="${3:-GET}"
  local data="${4:-}"
  local api_key="${5:-$(get_service_api_key $app)}"
  
  if [[ -z "$api_key" ]]; then
    error "$app API key not found"
    return 1
  fi
  
  local url="${SERVICE_URLS[$app]}/api/v3/${endpoint}"
  
  local curl_args=(
    -s
    -X "$method"
    -H "X-Api-Key: $api_key"
    -H "Content-Type: application/json"
  )
  
  if [[ "$method" != "GET" && -n "$data" ]]; then
    curl_args+=(-d "$data")
  fi
  
  curl "${curl_args[@]}" "$url"
}

# Add download client to arr app
arr_add_download_client() {
  local app="$1"
  local name="${2:-SABnzbd}"
  local host="${3:-sabnzbd}"
  local port="${4:-8080}"
  local api_key="${5:-$SABNZBD_API_KEY}"
  local category="$6"
  
  verbose "Adding download client to $app"
  
  local data=$(cat <<EOF
{
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "name": "$name",
  "fields": [
    {"name": "host", "value": "$host"},
    {"name": "port", "value": $port},
    {"name": "apiKey", "value": "$api_key"},
    {"name": "tvCategory", "value": "${category:-$app}"},
    {"name": "recentTvPriority", "value": -100},
    {"name": "olderTvPriority", "value": -100},
    {"name": "useSsl", "value": false}
  ],
  "implementationName": "SABnzbd",
  "implementation": "Sabnzbd",
  "configContract": "SabnzbdSettings",
  "tags": []
}
EOF
)
  
  local response=$(arr_api "$app" "downloadclient" "POST" "$data")
  
  if echo "$response" | grep -q '"id"'; then
    success "Added download client to $app"
    return 0
  else
    error "Failed to add download client to $app"
    verbose "Response: $response"
    return 1
  fi
}

# Add root folder to arr app
arr_add_root_folder() {
  local app="$1"
  local path="$2"
  
  verbose "Adding root folder to $app: $path"
  
  local data=$(cat <<EOF
{
  "path": "$path",
  "accessible": true,
  "freeSpace": 0,
  "unmappedFolders": []
}
EOF
)
  
  local response=$(arr_api "$app" "rootFolder" "POST" "$data")
  
  if echo "$response" | grep -q '"id"'; then
    success "Added root folder to $app: $path"
    return 0
  else
    error "Failed to add root folder to $app"
    verbose "Response: $response"
    return 1
  fi
}

# Test indexer in Prowlarr
prowlarr_test_indexer() {
  local indexer_id="$1"
  local api_key="${2:-$(get_service_api_key prowlarr)}"
  
  verbose "Testing indexer $indexer_id"
  
  local response=$(prowlarr_api "indexer/$indexer_id/test" "POST" "" "$api_key")
  
  if echo "$response" | grep -q "true\|success"; then
    success "Indexer test passed"
    return 0
  else
    error "Indexer test failed"
    verbose "Response: $response"
    return 1
  fi
}

# Get all indexers from Prowlarr
prowlarr_get_indexers() {
  local api_key="${1:-$(get_service_api_key prowlarr)}"
  prowlarr_api "indexer" "GET" "" "$api_key"
}

# Health check for a service
service_health_check() {
  local app="$1"
  local api_key="${2:-$(get_service_api_key $app)}"
  
  case "$app" in
    prowlarr)
      prowlarr_api "health" "GET" "" "$api_key"
      ;;
    sabnzbd)
      sabnzbd_api "?mode=queue"
      ;;
    *)
      arr_api "$app" "health" "GET" "" "$api_key"
      ;;
  esac
}