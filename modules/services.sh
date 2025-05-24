#!/bin/bash
###############################################################################
#  modules/services.sh - Service management functions
###############################################################################

# Check if a service is accessible
check_service_accessible() {
  local service="$1"
  local url="${SERVICE_URLS[$service]}"
  local max_attempts="${2:-5}"
  local attempt=0
  
  while (( attempt < max_attempts )); do
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302"; then
      return 0
    fi
    ((attempt++))
    sleep 2
  done
  
  return 1
}

# Wait for all services to be ready
wait_for_services() {
  log "Waiting for services to be ready..."
  
  local all_ready=false
  local max_wait=120
  local waited=0
  
  while ! $all_ready && (( waited < max_wait )); do
    all_ready=true
    
    for service in "${!SERVICE_URLS[@]}"; do
      if ! check_service_accessible "$service" 1; then
        verbose "$service not ready yet..."
        all_ready=false
      fi
    done
    
    if ! $all_ready; then
      sleep 5
      ((waited+=5))
      verbose "Waited $waited seconds..."
    fi
  done
  
  if $all_ready; then
    success "All services are ready"
    return 0
  else
    error "Timeout waiting for services"
    return 1
  fi
}

# Configure SABnzbd with all providers
configure_sabnzbd_providers() {
  log "Configuring SABnzbd providers..."
  
  # Load API functions
  source "$MODULES_DIR/api.sh"
  
  local priority=0
  for provider in "${!PROVIDERS[@]}"; do
    IFS=':' read -r server port username password connections <<< "${PROVIDERS[$provider]}"
    
    if (( ${FLAGS[dry_run]:-0} )); then
      log "Would add provider: $provider"
      log "  Server: $server:$port"
      log "  Connections: $connections"
    else
      sabnzbd_add_server "$provider" "$server" "$port" "$username" "$password" "$connections" "$priority"
    fi
    
    ((priority++))
  done
  
  # Configure categories
  log "Configuring SABnzbd categories..."
  local categories=("tv" "movies" "books" "comics")
  
  for category in "${categories[@]}"; do
    if (( ${FLAGS[dry_run]:-0} )); then
      log "Would add category: $category -> /downloads/$category"
    else
      sabnzbd_add_category "$category" "/downloads/$category"
    fi
  done
}

# Configure Prowlarr with all indexers
configure_prowlarr_indexers() {
  log "Configuring Prowlarr indexers..."
  
  # Load API functions
  source "$MODULES_DIR/api.sh"
  
  # Get Prowlarr API key
  local prowlarr_key=$(get_service_api_key "prowlarr")
  if [[ -z "$prowlarr_key" ]]; then
    # Wait for Prowlarr to generate API key
    prowlarr_key=$(wait_for_api_key "prowlarr")
    if [[ -z "$prowlarr_key" ]]; then
      error "Failed to get Prowlarr API key"
      return 1
    fi
  fi
  
  # Add each indexer
  for indexer in "${!INDEXERS[@]}"; do
    if (( ${FLAGS[dry_run]:-0} )); then
      log "Would add indexer: $indexer"
    else
      prowlarr_add_indexer "$indexer" "${INDEXERS[$indexer]}" "" "$prowlarr_key"
    fi
  done
  
  # Test all indexers
  if ! (( ${FLAGS[dry_run]:-0} )); then
    log "Testing indexers..."
    local indexers=$(prowlarr_get_indexers "$prowlarr_key")
    echo "$indexers" | jq -r '.[] | .id' | while read -r id; do
      prowlarr_test_indexer "$id" "$prowlarr_key"
    done
  fi
}

# Configure all arr applications
configure_arr_applications() {
  log "Configuring *arr applications..."
  
  # Load API functions
  source "$MODULES_DIR/api.sh"
  
  # Get Prowlarr API key
  local prowlarr_key=$(get_service_api_key "prowlarr")
  
  # Configure each app
  local -A app_configs=(
    ["sonarr"]="/tv:tv:[5000,5010,5020,5030,5040,5045,5050,5060,5070,5080]"
    ["radarr"]="/movies:movies:[2000,2010,2020,2030,2040,2045,2050,2060,2070,2080]"
    ["readarr"]="/books:books:[3030,7020]"
    ["mylar3"]="/comics:comics:[7030]"
  )
  
  for app in "${!app_configs[@]}"; do
    IFS=':' read -r root_folder category sync_cats <<< "${app_configs[$app]}"
    
    log "Configuring $app..."
    
    # Get app API key
    local app_key=$(get_service_api_key "$app")
    if [[ -z "$app_key" ]]; then
      app_key=$(wait_for_api_key "$app")
      if [[ -z "$app_key" ]]; then
        error "Failed to get $app API key"
        continue
      fi
    fi
    
    if (( ${FLAGS[dry_run]:-0} )); then
      log "Would configure $app:"
      log "  Root folder: $root_folder"
      log "  Download category: $category"
      log "  Prowlarr sync categories: $sync_cats"
    else
      # Add root folder
      arr_add_root_folder "$app" "$root_folder"
      
      # Add download client
      arr_add_download_client "$app" "SABnzbd" "sabnzbd" "8080" "$SABNZBD_API_KEY" "$category"
      
      # Add to Prowlarr
      local app_url="http://${app}:${SERVICE_URLS[$app]##*:}"
      prowlarr_add_app "$app" "$app_url" "$app_key" "$sync_cats" "$prowlarr_key"
    fi
  done
}

# Test all service connections
test_all_connections() {
  log "Testing all service connections..."
  
  # Load API functions
  source "$MODULES_DIR/api.sh"
  
  local all_passed=true
  
  # Test each service health
  for service in prowlarr sonarr radarr readarr sabnzbd; do
    verbose "Testing $service health..."
    
    local response=$(service_health_check "$service")
    if [[ -n "$response" ]]; then
      if echo "$response" | grep -q "error\|false\|unhealthy"; then
        error "$service health check failed"
        all_passed=false
      else
        success "$service is healthy"
      fi
    else
      error "$service health check returned no data"
      all_passed=false
    fi
  done
  
  # Test Prowlarr indexers
  log "Testing Prowlarr indexers..."
  local prowlarr_key=$(get_service_api_key "prowlarr")
  if [[ -n "$prowlarr_key" ]]; then
    local indexers=$(prowlarr_get_indexers "$prowlarr_key")
    local indexer_count=$(echo "$indexers" | jq '. | length')
    success "Found $indexer_count indexers in Prowlarr"
  else
    error "Could not test Prowlarr indexers - no API key"
    all_passed=false
  fi
  
  # Test download client from each arr app
  for app in sonarr radarr; do
    verbose "Testing $app download client..."
    local app_key=$(get_service_api_key "$app")
    if [[ -n "$app_key" ]]; then
      local clients=$(arr_api "$app" "downloadclient" "GET" "" "$app_key")
      if echo "$clients" | grep -q "SABnzbd"; then
        success "$app can communicate with SABnzbd"
      else
        error "$app cannot find SABnzbd"
        all_passed=false
      fi
    fi
  done
  
  if $all_passed; then
    success "All connection tests passed!"
    return 0
  else
    error "Some connection tests failed"
    return 1
  fi
}

# Backup all configurations
backup_configurations() {
  local backup_dir="${1:-$SCRIPT_DIR/backups}"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="$backup_dir/usenet_config_$timestamp.tar.gz"
  
  log "Backing up configurations..."
  
  mkdir -p "$backup_dir"
  
  # Create backup
  tar -czf "$backup_path" \
    -C "$CONFIG_DIR" \
    --exclude='*.log' \
    --exclude='*.db' \
    --exclude='*.db-*' \
    --exclude='MediaCover' \
    --exclude='logs' \
    .
  
  if [[ -f "$backup_path" ]]; then
    success "Backup created: $backup_path"
    
    # Keep only last 5 backups
    ls -t "$backup_dir"/usenet_config_*.tar.gz | tail -n +6 | xargs -r rm
    
    return 0
  else
    error "Backup failed"
    return 1
  fi
}

# Restore configurations from backup
restore_configurations() {
  local backup_path="$1"
  
  if [[ ! -f "$backup_path" ]]; then
    error "Backup file not found: $backup_path"
    return 1
  fi
  
  log "Restoring configurations from $backup_path..."
  
  # Stop services first
  "$SCRIPT_DIR/manage.sh" stop
  
  # Extract backup
  tar -xzf "$backup_path" -C "$CONFIG_DIR"
  
  # Start services
  "$SCRIPT_DIR/manage.sh" start
  
  success "Configurations restored"
  
  # Wait for services to be ready
  wait_for_services
}

# Show service status summary
show_service_status() {
  log "Service Status Summary"
  log "====================="
  
  for service in "${!SERVICE_URLS[@]}"; do
    printf "%-12s: " "$service"
    if check_service_accessible "$service" 1; then
      echo -e "\033[0;32m✓ Running\033[0m at ${SERVICE_URLS[$service]}"
    else
      echo -e "\033[0;31m✗ Not accessible\033[0m"
    fi
  done
  
  # Show API key status
  log ""
  log "API Key Status"
  log "=============="
  
  update_service_api_keys
  
  for service in prowlarr sonarr radarr readarr sabnzbd; do
    printf "%-12s: " "$service"
    if [[ -n "${SERVICE_API_KEYS[$service]:-}" ]]; then
      echo -e "\033[0;32m✓ Found\033[0m"
    else
      echo -e "\033[0;31m✗ Not found\033[0m"
    fi
  done
}