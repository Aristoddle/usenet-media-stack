# 🗺️ Development Roadmap

**Project**: Usenet Media Stack  
**Current Version**: v2.0  
**Last Updated**: 2025-05-25  
**Status**: Production-ready CLI with professional-grade UX

---

## 🎯 **Current Status & Architecture**

### **✅ Completed Phases (2025-05-25)**

**Phase 1: Core Parser Architecture** ✅  
- Pure subcommand routing system implemented  
- Global flag parsing with temp file system  
- Backward compatibility with legacy syntax  
- Professional help system foundation  

**Phase 2A: Pure Subcommand Architecture Refactor** ✅  
- Main parser completely rewritten following pyenv patterns  
- Three-tier help system (main → component → action)  
- Legacy support with deprecation warnings  
- Critical bug fixes (empty args, temp file deadlock)  

**Phase 2B: Action Verb Consistency Implementation** ✅  
- `storage.zsh`: `list` preferred over `discover` (with deprecation)  
- `hardware.zsh`: `list` preferred over `detect` (with deprecation)  
- Help text updated to show new preferred verbs  
- Consistent patterns across all components  

**Phase 2C: Enhanced Backup System** ✅  
- Smart backup types: config (5MB), full (100MB), minimal (1MB)  
- JSON metadata system with Git integration  
- Size validation preventing backup explosions  
- Beautiful CLI output with color coding  
- Professional help documentation  

**Testing & Stability Phase** ✅  
- Comprehensive CLI testing across all features  
- Architecture validation confirms production readiness  
- Performance analysis and optimization opportunities identified  
- TEST_REPORT.md with detailed findings  

---

## 🏗️ **Technical Architecture Insights**

### **CLI Design Patterns That Work**
Based on extensive testing and user feedback:

1. **Pure Subcommands Beat Flag-Based Commands**
   - `usenet storage list` feels more natural than `usenet --storage discover`
   - Users can discover functionality through tab completion
   - Matches mental model of Docker, Git, Terraform

2. **Three-Tier Help System Success**
   - `usenet help` → Overview and command listing
   - `usenet help storage` → Component-specific guidance  
   - `usenet storage --help` → Action-specific details
   - Users can self-serve at appropriate depth level

3. **Smart Defaults Prevent Footguns**
   - Config-only backups (5MB) vs previous 58MB+ explosions
   - Interactive prompts for destructive operations
   - Deprecation warnings instead of breaking changes
   - Dry-run modes for preview operations

4. **Error Messages Must Be Actionable**
   - "Unknown command: badcommand" + "Available commands: ..." + "Run 'usenet help'"
   - "Drive path required" + "Usage: usenet storage add <path>"
   - Permission issues → Clear guidance on fixing permissions

### **Performance Characteristics**
Real-world testing reveals:

- **Command response times**: Help (instant), Storage discovery (2-3s for 29 drives), Hardware detection (1-2s)
- **Memory footprint**: ~10MB peak during storage operations
- **Scalability**: Current architecture handles 100+ drives efficiently
- **Bottlenecks**: Storage discovery with cloud mounts (network I/O bound)

### **File Structure That Scales**
```
lib/commands/storage.zsh    # 459 lines - Hot-swappable JBOD management
lib/commands/hardware.zsh   # 855+ lines - GPU optimization & drivers  
lib/commands/backup.zsh     # 842 lines - Enhanced backup with metadata
lib/commands/deploy.zsh     # 264 lines - Primary deployment orchestration
```

**Key Insights**:
- Single-responsibility files scale better than monoliths
- 800+ lines is manageable for complex components (hardware.zsh)
- Common functionality belongs in lib/core/ not duplicated
- Function contracts essential for files >400 lines

---

## 🎯 **Immediate Next Session (75 minutes)**

### **1. Minor Fixes (30 minutes)**

#### **Storage Add Interactive Prompt Fix**
**Issue**: `./usenet storage add` hangs on interactive prompt when called without arguments  
**Root Cause**: `add_storage_drive()` function calls `confirm()` which expects terminal input  
**Solution**:
```bash
# In lib/commands/storage.zsh, add_storage_drive() function
add_storage_drive() {
    local drive_path="$1"
    
    # Add non-interactive check
    if [[ -z "$drive_path" ]]; then
        error "Drive path required"
        print "Usage: usenet storage add <path>"
        print "Example: usenet storage add /media/Movies_4TB"
        return 1
    fi
    
    # Add timeout for interactive prompts
    if [[ -n "$NON_INTERACTIVE" ]] || [[ ! -t 0 ]]; then
        # Non-interactive mode - proceed with safe defaults
        warning "Running in non-interactive mode, using safe defaults"
    fi
}
```

#### **Backup Size Display Consistency**  
**Issue**: Backup shows "1.0K" in creation but "5.6M" in listing  
**Root Cause**: Different `du` flags used (`du -h` vs `du -m`)  
**Solution**:
```bash
# Standardize on `du -h` everywhere in backup.zsh
# Line ~467: local backup_size=$(du -h "$backup_file" | cut -f1)
# Line ~515: local size=$(du -h "$backup_file" | cut -f1)
```

#### **Help Text Improvements**
**Opportunities**:
- Add more examples to component help
- Include common error solutions in help text  
- Add "See also" references between related commands

### **2. Documentation Updates (45 minutes)**

#### **README Enhancements**
- ✅ **Complete README rewrite** (already done above)
- Add performance benchmarks section
- Include real terminal output examples
- Document known issues from TEST_REPORT.md

#### **Architecture Documentation**
- Document pyenv-style patterns and why they work
- Include CLI design decisions and trade-offs
- Add troubleshooting decision trees
- Performance optimization guidelines

---

## 🚀 **Phase 3: Services Command Enhancement (2-3 hours)**

### **Implementation Plan**

#### **Create lib/commands/services.zsh (1.5 hours)**
**Replace legacy manage.zsh with professional services command**

```bash
# New service registry with metadata
declare -A SERVICE_GROUPS=(
    [media]="jellyfin overseerr tdarr yacreader"
    [automation]="sonarr radarr bazarr prowlarr recyclarr"
    [download]="sabnzbd transmission"
    [monitoring]="netdata portainer"
    [sharing]="samba nfs-server"
)

declare -A SERVICE_PORTS=(
    [jellyfin]=8096 [overseerr]=5055 [sonarr]=8989 [radarr]=7878
    [prowlarr]=9696 [sabnzbd]=8080 [transmission]=9092
    [tdarr]=8265 [netdata]=19999 [portainer]=9000
    # ... complete mapping for all 19 services
)

declare -A SERVICE_HEALTH_ENDPOINTS=(
    [jellyfin]="/health" [sonarr]="/api/v3/system/status" 
    [radarr]="/api/v3/system/status" [prowlarr]="/api/v1/system/status"
    # ... health check endpoints for API-enabled services
)
```

#### **Command Structure (30 minutes)**
```bash
usenet services list [--group media|automation|download]
usenet services start [service|--all|--group automation]  
usenet services stop [service|--all|--group automation]
usenet services restart [service|--all|--group automation]
usenet services logs <service> [--follow|--tail 100]
usenet services status [service] [--detailed]
usenet services exec <service> <command>
```

#### **Rich Status Display (1 hour)**
```bash
# Example output
$ usenet services list

📊 SERVICE STATUS OVERVIEW
════════════════════════════════════════════════════════════════

📺 Media Automation (5/5 healthy)
├── ✅ sonarr        (8989)  │ Ready │ 1.2GB RAM │ API: ✓ │ Queue: 3 items
├── ✅ radarr        (7878)  │ Ready │ 0.8GB RAM │ API: ✓ │ Queue: 1 item
├── ✅ prowlarr      (9696)  │ Ready │ 0.3GB RAM │ API: ✓ │ Indexers: 8
├── ✅ bazarr        (6767)  │ Ready │ 0.2GB RAM │ API: ✓ │ Queue: 0
└── ✅ recyclarr              │ Timer │ Last run: 2h ago

🎬 Media Services (3/3 healthy)  
├── ✅ jellyfin      (8096)  │ Ready │ 2.1GB RAM │ GPU: AMD VAAPI
├── ✅ overseerr     (5055)  │ Ready │ 0.4GB RAM │ API: ✓
└── ✅ tdarr         (8265)  │ Ready │ 1.8GB RAM │ GPU: AMD VAAPI

Total Resources: 6.8GB RAM, 2 GPU-accelerated services
```

#### **Health Checking Implementation (30 minutes)**
```bash
check_service_health() {
    local service="$1"
    local detailed="${2:-false}"
    
    # Docker container health
    local container_status=$(docker inspect --format='{{.State.Status}}' "usenet-${service}-1" 2>/dev/null)
    local container_health=$(docker inspect --format='{{.State.Health.Status}}' "usenet-${service}-1" 2>/dev/null)
    
    # HTTP health check (if service has web interface)
    local http_status="unknown"
    if [[ -n "${SERVICE_PORTS[$service]}" ]]; then
        local port="${SERVICE_PORTS[$service]}"
        local health_endpoint="${SERVICE_HEALTH_ENDPOINTS[$service]:-/}"
        http_status=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 --max-time 10 \
            "http://localhost:${port}${health_endpoint}" 2>/dev/null || echo "unreachable")
    fi
    
    # Resource usage
    local memory_usage=$(docker stats --no-stream --format "{{.MemUsage}}" "usenet-${service}-1" 2>/dev/null)
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "usenet-${service}-1" 2>/dev/null)
    
    # Combine into overall health status
    determine_service_health "$container_status" "$container_health" "$http_status"
}
```

### **Critical Implementation Notes**

**Service Dependencies**: Some services must start in order
- Start download clients (sabnzbd, transmission) first
- Then automation services (sonarr, radarr, prowlarr)  
- Finally media services (jellyfin, overseerr)
- Monitoring services (netdata, portainer) can start anytime

**Error Handling**: Services may be temporarily unavailable during restarts
- Implement retry logic with exponential backoff
- Show progress indicators for operations taking >2 seconds
- Graceful degradation when some services are down

**Performance**: Service status checks shouldn't block
- Parallel health checks for multiple services
- Cache health results for 30 seconds to avoid API hammering
- Timeout protection for unresponsive services

---

## 🔧 **Phase 4: Advanced Backup Features (1-2 hours)**

### **Restore Command Implementation (1 hour)**

#### **Atomic Restore with Rollback**
```bash
restore_backup() {
    local backup_file="$1"
    local force="${2:-false}"
    
    # Pre-restore validation
    validate_backup_file "$backup_file" || return 1
    validate_system_ready_for_restore || return 1
    
    # Create pre-restore snapshot
    local pre_restore_backup="${BACKUP_DIR}/pre-restore-$(date +%s).tar.gz"
    info "Creating pre-restore backup: $(basename "$pre_restore_backup")"
    create_backup "config" "auto-pre-restore" "true" "Pre-restore safety backup" || {
        error "Failed to create pre-restore backup"
        return 1
    }
    
    # Atomic restore operation
    local temp_restore_dir=$(mktemp -d)
    local restore_success=false
    
    {
        # Extract to temporary location
        tar -xzf "$backup_file" -C "$temp_restore_dir" && \
        
        # Validate extracted contents
        validate_extracted_backup "$temp_restore_dir" && \
        
        # Stop services that depend on configuration
        stop_configuration_services && \
        
        # Atomic swap (all or nothing)
        backup_current_config && \
        restore_configuration_files "$temp_restore_dir" && \
        
        # Start services and validate
        start_configuration_services && \
        validate_post_restore_health && \
        
        restore_success=true
    } || {
        error "Restore failed, initiating rollback"
        rollback_configuration
        start_configuration_services
    }
    
    # Cleanup
    rm -rf "$temp_restore_dir"
    
    if [[ "$restore_success" == "true" ]]; then
        success "Restore completed successfully"
        info "Pre-restore backup available: $(basename "$pre_restore_backup")"
    else
        error "Restore failed and was rolled back"
        return 1
    fi
}
```

#### **Backup Retention Policies (30 minutes)**
```bash
clean_old_backups() {
    local older_than_days="${1:-30}"
    local keep_count="${2:-10}"
    local dry_run="${3:-false}"
    
    print "🧹 Backup Cleanup Policy"
    print "────────────────────────────────────────"
    print "Keep: Last $keep_count backups"
    print "Remove: Backups older than $older_than_days days"
    
    # Find backups to remove by age
    local -a old_backups=()
    while IFS= read -r -d '' backup_file; do
        if [[ $(find "$backup_file" -mtime +$older_than_days 2>/dev/null) ]]; then
            old_backups+=("$backup_file")
        fi
    done < <(find "$BACKUP_DIR" -name "${BACKUP_PREFIX}-*.tar*" -print0 2>/dev/null)
    
    # Find backups to remove by count (keep most recent)
    local -a excess_backups=()
    local backup_count=$(ls -1 "$BACKUP_DIR"/${BACKUP_PREFIX}-*.tar.gz 2>/dev/null | wc -l)
    if [[ $backup_count -gt $keep_count ]]; then
        local excess_count=$((backup_count - keep_count))
        excess_backups=($(ls -1t "$BACKUP_DIR"/${BACKUP_PREFIX}-*.tar.gz | tail -n +$((keep_count + 1))))
    fi
    
    # Combine and deduplicate
    local -a backups_to_remove=()
    for backup in "${old_backups[@]}" "${excess_backups[@]}"; do
        if [[ ! " ${backups_to_remove[@]} " =~ " ${backup} " ]]; then
            backups_to_remove+=("$backup")
        fi
    done
    
    if [[ ${#backups_to_remove[@]} -eq 0 ]]; then
        success "No backups need cleaning"
        return 0
    fi
    
    print "\n📋 Backups to remove:"
    for backup in "${backups_to_remove[@]}"; do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(date -r "$backup" '+%Y-%m-%d %H:%M')
        print "  🗑️  $(basename "$backup") ($size, $date)"
    done
    
    if [[ "$dry_run" == "true" ]]; then
        info "Dry run mode - no files will be deleted"
        return 0
    fi
    
    if ! confirm "Remove ${#backups_to_remove[@]} backup(s)?"; then
        info "Cleanup cancelled"
        return 0
    fi
    
    # Remove backups and their metadata
    for backup in "${backups_to_remove[@]}"; do
        rm -f "$backup" "${backup}.meta"
        success "Removed: $(basename "$backup")"
    done
}
```

### **Backup Type Optimization (30 minutes)**

#### **Smart Exclusion Patterns**
```bash
# Enhanced exclusion patterns based on backup type
get_backup_exclusions() {
    local backup_type="$1"
    local exclude_file="$2"
    
    # Base exclusions (always excluded)
    cat > "$exclude_file" <<'EOF'
# Always exclude
.git/
node_modules/
.DS_Store
Thumbs.db
*.tmp
*.cache
*.swap
backups/
downloads/
media/
*.tar
*.tar.gz
*.tar.bz2
*.zip
EOF

    case "$backup_type" in
        minimal)
            cat >> "$exclude_file" <<'EOF'
# Minimal backup exclusions
config/*/logs/
config/*/log/
config/*/*.log
config/*/tmp/
config/*/cache/
config/*/Cache/
config/*/Logs/
config/*/backups/
config/*/Backups/
lib/test/
scripts/legacy/
docs/
docker-compose.*.yml
EOF
            ;;
        config)
            cat >> "$exclude_file" <<'EOF'
# Config backup exclusions  
config/*/logs/
config/*/log/
config/*/*.log
*.log
logs/
log/
config/*/tmp/
config/*/cache/
config/*/Cache/
config/*/Logs/
EOF
            ;;
        full)
            # Full backup - minimal exclusions, include logs
            cat >> "$exclude_file" <<'EOF'
# Full backup exclusions (minimal)
config/*/cache/
config/*/Cache/
config/*/tmp/
EOF
            ;;
    esac
}
```

---

## 🚀 **Phase 5: Hot-Swap API Integration (4-6 hours)**

### **Technical Implementation Details**

#### **Multi-Service API Coordination (2 hours)**
```bash
# lib/core/api.zsh - Service API abstraction
api_call() {
    local service="$1"
    local endpoint="$2"
    local method="${3:-GET}"
    local data="$4"
    local timeout="${5:-30}"
    
    # Get service configuration
    local base_url="http://localhost:${SERVICE_PORTS[$service]}"
    local api_key="${SERVICE_API_KEYS[$service]}"
    
    if [[ -z "$api_key" ]]; then
        error "API key not configured for $service"
        return 1
    fi
    
    # Construct curl command based on service type
    local curl_cmd=(
        curl
        --silent
        --show-error
        --connect-timeout 10
        --max-time "$timeout"
        -X "$method"
        -H "X-Api-Key: $api_key"
        -H "Content-Type: application/json"
    )
    
    # Add data for POST/PUT requests
    if [[ -n "$data" ]]; then
        curl_cmd+=(-d "$data")
    fi
    
    # Execute API call with error handling
    local response
    local http_code
    if response=$(curl "${curl_cmd[@]}" -w "%{http_code}" "${base_url}/api/v3/${endpoint}" 2>/dev/null); then
        http_code="${response: -3}"
        response="${response%???}"
        
        case "$http_code" in
            200|201|204) return 0 ;;
            401) error "API authentication failed for $service"; return 1 ;;
            404) error "API endpoint not found: $endpoint"; return 1 ;;
            *) error "API call failed: HTTP $http_code"; return 1 ;;
        esac
    else
        error "Failed to connect to $service API"
        return 1
    fi
}

# Sonarr root folder management
sonarr_add_root_folder() {
    local drive_path="$1"
    local folder_name="${2:-$(basename "$drive_path")}"
    
    local data=$(cat <<EOF
{
    "path": "$drive_path",
    "accessible": true,
    "freeSpace": $(df -B1 "$drive_path" | tail -1 | awk '{print $4}'),
    "unmappedFolders": []
}
EOF
)
    
    api_call "sonarr" "rootfolder" "POST" "$data"
}

# Radarr root folder management (identical API structure)
radarr_add_root_folder() {
    local drive_path="$1"
    sonarr_add_root_folder "$drive_path" "$2"  # Same implementation
}
```

#### **Atomic Hot-Swap Operations (2 hours)**
```bash
# Storage sync with transaction-like behavior
sync_storage_with_services() {
    local drive_path="$1"
    local action="$2"  # add|remove
    local services=("${@:3}")  # Array of services to update
    
    if [[ ${#services[@]} -eq 0 ]]; then
        services=(sonarr radarr)  # Default services
    fi
    
    info "Syncing storage with ${#services[@]} service(s)"
    
    # Pre-flight checks
    for service in "${services[@]}"; do
        if ! service_is_healthy "$service"; then
            error "Service $service is not healthy, aborting sync"
            return 1
        fi
    done
    
    # Create rollback state
    local rollback_state=$(mktemp)
    capture_current_state "$rollback_state" "${services[@]}"
    
    # Track successful operations for rollback
    local -a completed_operations=()
    local operation_failed=false
    
    # Execute operations with rollback tracking
    for service in "${services[@]}"; do
        info "Updating $service..."
        
        case "$action" in
            add)
                if add_root_folder_to_service "$service" "$drive_path"; then
                    completed_operations+=("${service}:add:${drive_path}")
                    success "✓ $service updated"
                else
                    error "✗ Failed to update $service"
                    operation_failed=true
                    break
                fi
                ;;
            remove)
                if remove_root_folder_from_service "$service" "$drive_path"; then
                    completed_operations+=("${service}:remove:${drive_path}")
                    success "✓ $service updated"
                else
                    error "✗ Failed to update $service"
                    operation_failed=true
                    break
                fi
                ;;
        esac
    done
    
    # Handle rollback if any operation failed
    if [[ "$operation_failed" == "true" ]]; then
        warning "Operation failed, rolling back changes..."
        rollback_storage_operations "$rollback_state" "${completed_operations[@]}"
        return 1
    fi
    
    # Validate final state
    for service in "${services[@]}"; do
        if ! validate_service_storage_state "$service" "$drive_path" "$action"; then
            warning "Storage state validation failed for $service"
            # Note: Could trigger rollback here if desired
        fi
    done
    
    success "Storage sync completed successfully"
    rm -f "$rollback_state"
    return 0
}
```

#### **State Validation & Error Recovery (1 hour)**
```bash
# Comprehensive state validation
validate_service_storage_state() {
    local service="$1"
    local drive_path="$2"
    local expected_action="$3"  # add|remove
    
    info "Validating storage state for $service..."
    
    # Get current root folders from service API
    local response
    if ! response=$(api_call "$service" "rootfolder" "GET"); then
        error "Failed to get root folders from $service"
        return 1
    fi
    
    # Parse JSON response to check if drive is present
    local drive_present=false
    if echo "$response" | jq -r '.[].path' | grep -q "^${drive_path}$"; then
        drive_present=true
    fi
    
    # Validate against expected state
    case "$expected_action" in
        add)
            if [[ "$drive_present" == "true" ]]; then
                success "✓ Drive $drive_path correctly added to $service"
                return 0
            else
                error "✗ Drive $drive_path not found in $service after add operation"
                return 1
            fi
            ;;
        remove)
            if [[ "$drive_present" == "false" ]]; then
                success "✓ Drive $drive_path correctly removed from $service"
                return 0
            else
                error "✗ Drive $drive_path still present in $service after remove operation"
                return 1
            fi
            ;;
    esac
}

# Error recovery with exponential backoff
retry_api_operation() {
    local operation="$1"
    local max_attempts="${2:-3}"
    local base_delay="${3:-2}"
    
    local attempt=1
    local delay="$base_delay"
    
    while [[ $attempt -le $max_attempts ]]; do
        info "Attempt $attempt/$max_attempts: $operation"
        
        if eval "$operation"; then
            success "Operation succeeded on attempt $attempt"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            warning "Attempt $attempt failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi
        
        ((attempt++))
    done
    
    error "Operation failed after $max_attempts attempts"
    return 1
}
```

#### **Zero-Downtime Implementation (1 hour)**
```bash
# Hot-swap implementation that doesn't restart services
hot_swap_add_drive() {
    local drive_path="$1"
    local auto_confirm="${2:-false}"
    
    print "🔥 HOT-SWAP DRIVE ADDITION"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 1. Validate drive
    info "🔍 Validating drive: $drive_path"
    validate_drive_for_hot_swap "$drive_path" || return 1
    
    # 2. Update Docker Compose storage configuration
    info "🐳 Updating Docker Compose configuration..."
    add_drive_to_compose_storage "$drive_path" || return 1
    
    # 3. Apply storage configuration without restart
    info "📁 Applying storage configuration..."
    if docker compose up -d --no-recreate 2>/dev/null; then
        success "✓ Storage configuration applied"
    else
        error "Failed to apply storage configuration"
        return 1
    fi
    
    # 4. Wait for drive to be available in containers
    info "⏳ Waiting for drive to be available in containers..."
    wait_for_drive_in_containers "$drive_path" 30 || {
        error "Drive not accessible in containers after 30 seconds"
        return 1
    }
    
    # 5. Update service APIs
    info "🔗 Updating service APIs..."
    sync_storage_with_services "$drive_path" "add" sonarr radarr || {
        error "Failed to update service APIs"
        return 1
    }
    
    # 6. Validate everything is working
    info "✅ Validating hot-swap completion..."
    validate_hot_swap_success "$drive_path" || {
        warning "Hot-swap validation failed, but drive is added"
    }
    
    print ""
    success "🎉 Hot-swap completed successfully!"
    print "Drive $drive_path is now available to all services"
    print "No service restarts were required"
    
    # Show updated storage pool
    print "\n📊 Updated Storage Pool:"
    show_storage_pool_summary
}

wait_for_drive_in_containers() {
    local drive_path="$1"
    local timeout_seconds="$2"
    
    local elapsed=0
    local check_interval=2
    
    while [[ $elapsed -lt $timeout_seconds ]]; do
        # Check if drive is mounted in key containers
        local containers_ready=0
        local total_containers=0
        
        for service in sonarr radarr jellyfin; do
            ((total_containers++))
            if docker exec "usenet-${service}-1" test -d "$drive_path" 2>/dev/null; then
                ((containers_ready++))
            fi
        done
        
        if [[ $containers_ready -eq $total_containers ]]; then
            success "Drive available in all $total_containers containers"
            return 0
        fi
        
        print "  Containers ready: $containers_ready/$total_containers"
        sleep "$check_interval"
        elapsed=$((elapsed + check_interval))
    done
    
    error "Timeout waiting for drive to be available in containers"
    return 1
}
```

### **Critical Implementation Considerations**

#### **API Key Management**
- Store API keys in .env file only, never hardcode
- Auto-generate API keys during initial service setup
- Implement API key rotation functionality
- Never log API keys in debug output

#### **Service Dependency Handling**
- Services may not be immediately available after startup
- Implement health checks before API operations
- Handle service restarts gracefully (retry with backoff)
- Some services (like Recyclarr) don't have APIs - handle gracefully

#### **Transaction Safety**
- Always create rollback state before multi-service operations
- Implement atomic operations where possible
- Provide clear rollback instructions when automatic rollback fails
- Log all operations for debugging and audit trails

#### **Error Scenarios to Handle**
- Network timeouts during API calls
- Services temporarily unresponsive during updates
- Partial failures across multiple services
- Docker container communication issues
- Filesystem permission problems

---

## 🔮 **Future Vision (v3.0+)**

### **Smart Media Management**
- **Perceptual hashing** for content-aware duplicate detection
- **Fuzzy matching** handling different cuts and editions (Director's Cut vs Theatrical)
- **Quality scoring** with automatic upgrade recommendations
- **Watch history preservation** during media library changes

### **Advanced Cluster Management**
- **Multi-node orchestration** with service placement constraints
- **Load balancing** across available hardware
- **Automatic failover** when nodes go offline
- **Resource optimization** based on real-time usage

### **AI-Powered Optimization**
- **Storage prediction** based on usage patterns
- **Hardware optimization** with machine learning
- **Quality preference learning** from user behavior
- **Automated indexer management** based on success rates

---

## 📊 **Success Metrics**

### **Technical Excellence**
- **Code Quality**: Stan Eisenstat standards maintained (80-char lines, function contracts)
- **Test Coverage**: Comprehensive CLI testing with >95% command coverage
- **Performance**: Sub-5s response times for all operations
- **Reliability**: Zero data loss, atomic operations with rollback

### **User Experience**
- **Onboarding**: One-command deployment working consistently
- **Daily Operations**: Intuitive CLI with self-service help system
- **Error Recovery**: Clear guidance for all failure scenarios
- **Documentation**: Professional-grade docs matching implementation

### **Community Impact**
- **Open Source**: MIT license enabling community contributions
- **Standards**: Demonstration of Bell Labs quality in modern tooling
- **Education**: Clear examples of professional CLI architecture
- **Influence**: Inspiring better practices in media automation tooling

---

## 🎓 **Development Principles**

### **From Stan Eisenstat**
> "If you can't explain it to a freshman, you don't understand it yourself"

Every function, every decision, every abstraction must be explainable to someone learning the system for the first time.

### **From Our Experience**
1. **Test early, test often**: Comprehensive testing prevents architectural debt
2. **Users judge on first impression**: Help system and error messages must be excellent
3. **Safe defaults win**: Prevent footguns with smart configuration choices
4. **Document decisions**: Future developers (including yourself) need context

### **For Future Contributors**
- Read TEST_REPORT.md to understand current system capabilities
- Follow existing patterns for CLI design and error handling
- Test on real hardware with real data before submitting PRs
- Document not just what but why in your commit messages

---

*"Programs must be written for people to read, and only incidentally for machines to execute."* - Abelson & Sussman

This roadmap serves as both implementation guide and architectural documentation, ensuring that future development maintains the quality standards we've established.
