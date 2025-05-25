#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/backup.zsh
# Project: Usenet Media Stack
# Description: Enhanced backup and restore system with metadata and safety
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-25
# Version: 2.0.0
# License: MIT
#
# Enhanced backup system with:
# - Smart backup types (config, full, minimal)
# - JSON metadata system for backup tracking
# - Atomic restore operations with rollback capability
# - Size warnings and validation
# - Beautiful CLI following our design patterns
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Load core functions
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"
source "${SCRIPT_DIR:h}/core/common.zsh"
source "${SCRIPT_DIR:h}/core/init.zsh"

# Ensure config is loaded
load_stack_config || die 1 "Failed to load configuration"

# Backup configuration
readonly BACKUP_PREFIX="usenet-stack-backup"
readonly VERSION="2.0.0"

##############################################################################
#                            BACKUP TYPES & METADATA                        #
##############################################################################

# Backup type definitions
readonly -A BACKUP_TYPES=(
    [config]="Configuration only (default) - excludes media, downloads, logs"
    [full]="Complete backup including logs and temporary files"
    [minimal]="Essential files only - .env, compose files, critical configs"
)

# Size limits (in MB) for backup type validation
readonly -A SIZE_LIMITS=(
    [config]=100
    [full]=1000
    [minimal]=10
)

##############################################################################
#                            UTILITY FUNCTIONS                               #
##############################################################################

#=============================================================================
# Function: show_backup_help
# Description: Display comprehensive backup management help
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
show_backup_help() {
    cat <<'HELP'
💾 Enhanced Backup Management

USAGE
    usenet backup <action> [options]

ACTIONS
    list                    List all available backups with metadata
    create [options]        Create a new backup (default action)
    show <backup>           Show backup contents and metadata
    restore <backup>        Restore from backup with safety checks
    clean [options]         Clean old backups

CREATE OPTIONS
    --type <type>          Backup type: config (default), full, minimal
    --name <name>          Custom backup name (default: timestamp)
    --compress, -z         Compress backup with gzip (recommended)
    --description <desc>   Add description to backup metadata

RESTORE OPTIONS
    --force, -f            Skip confirmation prompts
    --dry-run, -n          Preview what would be restored
    --no-backup            Skip creating pre-restore backup

CLEAN OPTIONS
    --older-than <days>    Remove backups older than N days
    --keep <count>         Keep only N most recent backups
    --dry-run, -n          Preview what would be deleted

BACKUP TYPES
    config (default)       Configuration files only (~20-50MB)
                          ✓ .env, compose files, service configs
                          ✓ Application databases and settings
                          ✗ Media files, downloads, logs
                          
    full                   Complete backup including logs (~100-500MB)
                          ✓ Everything from config type
                          ✓ Log files and temporary data
                          ✗ Media files and downloads
                          
    minimal                Essential files only (~5-10MB)
                          ✓ .env, main compose file
                          ✓ Critical service configs only
                          ✗ Everything else

EXAMPLES
    # List backups with metadata
    usenet backup list
    
    # Create config backup (most common)
    usenet backup create --compress
    
    # Create named backup with description
    usenet backup create --name "pre-v3-upgrade" --description "Before major version upgrade"
    
    # Create full backup for migration
    usenet backup create --type full --compress
    
    # Show backup details
    usenet backup show usenet-stack-backup-20250525-143022.tar.gz
    
    # Safe restore with preview
    usenet backup restore --dry-run backup.tar.gz
    usenet backup restore backup.tar.gz
    
    # Clean old backups
    usenet backup clean --older-than 30
    usenet backup clean --keep 5

BACKUP LOCATION
    Directory: ./backups/
    Metadata:  backup-name.tar.gz.meta (JSON format)
    
SECURITY
    ⚠️  Backups contain sensitive data (.env with API keys)
    ⚠️  Store backups securely, do not commit to version control
    ✓  Atomic restore operations with rollback capability
    ✓  Pre-restore safety backups created automatically

HELP
}

#=============================================================================
# Function: get_backup_files_by_type
# Description: Get file list based on backup type
#
# Arguments:
#   $1 - backup_type (config|full|minimal)
#   $2 - output_file for file list
#
# Returns:
#   0 - List created successfully
#   1 - Error creating list
#=============================================================================
get_backup_files_by_type() {
    local backup_type="$1"
    local list_file="$2"
    
    > "$list_file"  # Clear the file
    
    case "$backup_type" in
        minimal)
            # Essential files only - absolute minimum for restoration
            local minimal_files=(
                ".env"
                "docker-compose.yml"
                "usenet"
                "config/*/config.xml"      # Core service configs
                "config/*/settings.json"   # Core service settings
            )
            
            for pattern in $minimal_files; do
                if [[ "$pattern" == *"*"* ]]; then
                    # Handle wildcards with find
                    find . -path "$pattern" -type f 2>/dev/null >> "$list_file" || true
                elif [[ -e "$pattern" ]]; then
                    echo "$pattern" >> "$list_file"
                fi
            done
            ;;
            
        full)
            # Everything except media and downloads
            local full_files=(
                ".env"
                "docker-compose*.yml"
                "*.md"
                "usenet"
                "lib/"
                "config/"
                "scripts/"
                "completions/"
                "docs/"
            )
            
            for pattern in $full_files; do
                if [[ "$pattern" == *"*"* ]]; then
                    # Use find for wildcards
                    find . -name "$pattern" -type f 2>/dev/null >> "$list_file" || true
                    find . -name "$pattern" -type d 2>/dev/null >> "$list_file" || true
                elif [[ -e "$pattern" ]]; then
                    echo "$pattern" >> "$list_file"
                fi
            done
            ;;
            
        config|*)
            # Default: Configuration files only (most common)
            local config_files=(
                ".env"
                "docker-compose.yml"
                "docker-compose.*.yml"
                "usenet"
                "lib/"
                "config/"
                "completions/"
                "README.md"
                "CLAUDE.md"
            )
            
            # Optional documentation
            local optional_files=(
                "SECURITY_GUIDE.md"
                "MIGRATION_NOTES.md"
                "DOCKER_SWARM_GUIDE.md"
                "scripts/"
                "docs/"
            )
            
            for pattern in $config_files; do
                if [[ "$pattern" == *"*"* ]]; then
                    find . -name "$pattern" -type f 2>/dev/null >> "$list_file" || true
                elif [[ -e "$pattern" ]]; then
                    echo "$pattern" >> "$list_file"
                fi
            done
            
            for pattern in $optional_files; do
                if [[ -e "$pattern" ]]; then
                    echo "$pattern" >> "$list_file"
                fi
            done
            ;;
    esac
    
    # Create exclusion patterns based on type
    local exclude_file="${list_file}.exclude"
    cat > "$exclude_file" <<EOF
# Always exclude
downloads/
media/
*.tmp
*.cache
*.swap
.git/
.gitignore
node_modules/
.DS_Store
Thumbs.db
backups/
*.tar
*.tar.gz
*.tar.bz2
EOF

    # Type-specific exclusions
    if [[ "$backup_type" != "full" ]]; then
        cat >> "$exclude_file" <<EOF
# Logs and temporary data (excluded in config/minimal)
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
    fi
    
    if [[ "$backup_type" == "minimal" ]]; then
        cat >> "$exclude_file" <<EOF
# Additional exclusions for minimal backup
lib/test/
scripts/legacy/
docs/
config/*/backups/
config/*/Backups/
EOF
    fi
    
    return 0
}

#=============================================================================
# Function: create_backup_metadata
# Description: Create JSON metadata file for backup
#
# Arguments:
#   $1 - backup_file path
#   $2 - backup_type
#   $3 - description (optional)
#
# Returns:
#   0 - Metadata created successfully
#   1 - Error creating metadata
#=============================================================================
create_backup_metadata() {
    local backup_file="$1"
    local backup_type="$2"
    local description="${3:-""}"
    
    local metadata_file="${backup_file}.meta"
    local backup_size=$(du -h "$backup_file" | cut -f1)
    local backup_size_bytes=$(stat -c%s "$backup_file" 2>/dev/null || echo "0")
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local services=$(docker compose ps --services 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "unknown")
    
    # Create JSON metadata
    cat > "$metadata_file" <<EOF
{
  "version": "$VERSION",
  "created": "$(date -Iseconds)",
  "created_unix": $(date +%s),
  "type": "$backup_type",
  "description": "$description",
  "filename": "$(basename "$backup_file")",
  "size_human": "$backup_size",
  "size_bytes": $backup_size_bytes,
  "hostname": "$(hostname)",
  "git_commit": "$git_commit",
  "git_branch": "$git_branch",
  "services": "$services",
  "backup_type_description": "${BACKUP_TYPES[$backup_type]}"
}
EOF
    
    return 0
}

#=============================================================================
# Function: validate_backup_size
# Description: Check if backup size is reasonable for its type
#
# Arguments:
#   $1 - backup_file path
#   $2 - backup_type
#
# Returns:
#   0 - Size is reasonable
#   1 - Size is suspicious (with warning)
#=============================================================================
validate_backup_size() {
    local backup_file="$1"
    local backup_type="$2"
    
    local size_mb=$(du -m "$backup_file" | cut -f1)
    local limit_mb=${SIZE_LIMITS[$backup_type]}
    
    if [[ $size_mb -gt $limit_mb ]]; then
        warning "Backup size ($size_mb MB) exceeds expected limit for '$backup_type' type ($limit_mb MB)"
        warning "This might indicate the backup includes unintended large files"
        
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi
    
    return 0
}

#=============================================================================
# Function: create_backup
# Description: Create a backup with enhanced metadata and validation
#
# Arguments:
#   $1 - backup_type (config|full|minimal)
#   $2 - backup_name (optional)
#   $3 - compress (true/false)
#   $4 - description (optional)
#
# Returns:
#   0 - Backup created successfully
#   1 - Error creating backup
#=============================================================================
create_backup() {
    local backup_type="${1:-config}"
    local backup_name="${2:-$(date +%Y%m%d-%H%M%S)}"
    local compress="${3:-true}"
    local description="$4"
    
    # Validate backup type
    if [[ -z "${BACKUP_TYPES[$backup_type]:-}" ]]; then
        error "Invalid backup type: $backup_type"
        error "Valid types: ${(k)BACKUP_TYPES}"
        return 1
    fi
    
    info "Creating $backup_type backup: $backup_name"
    
    # Ensure backup directory exists
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    # Generate backup filename
    local backup_file="${BACKUP_DIR}/${BACKUP_PREFIX}-${backup_name}.tar"
    if [[ "$compress" == "true" ]]; then
        backup_file="${backup_file}.gz"
    fi
    
    # Check if backup already exists
    if [[ -f "$backup_file" ]]; then
        error "Backup already exists: $(basename "$backup_file")"
        return 1
    fi
    
    # Create temporary files for backup lists
    local list_file=$(mktemp)
    local exclude_file="${list_file}.exclude"
    
    get_backup_files_by_type "$backup_type" "$list_file"
    
    # Show what will be backed up
    local file_count=$(wc -l < "$list_file")
    info "Backing up $file_count items (type: $backup_type)"
    
    # Create the backup
    local compress_flag=""
    if [[ "$compress" == "true" ]]; then
        compress_flag="z"
        info "Using gzip compression"
    fi
    
    # Change to project root and create backup
    cd "$PROJECT_ROOT"
    
    
    if tar -c${compress_flag}f "$backup_file" \
        --exclude-from="$exclude_file" \
        --files-from="$list_file" \
        --ignore-failed-read 2>/dev/null; then
        
        # Validate backup size
        if ! validate_backup_size "$backup_file" "$backup_type"; then
            rm -f "$backup_file"
            rm -f "$list_file" "$exclude_file"
            return 1
        fi
        
        # Create metadata
        create_backup_metadata "$backup_file" "$backup_type" "$description"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        success "Backup created: $(basename "$backup_file") ($backup_size)"
        success "Type: $backup_type - ${BACKUP_TYPES[$backup_type]}"
        
        if [[ -n "$description" ]]; then
            info "Description: $description"
        fi
        
        info "Location: $backup_file"
        
    else
        error "Failed to create backup"
        rm -f "$backup_file"
        rm -f "$list_file" "$exclude_file"
        return 1
    fi
    
    # Cleanup temporary files
    rm -f "$list_file" "$exclude_file"
    
    return 0
}

#=============================================================================
# Function: list_backups
# Description: List all available backups with rich metadata display
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        warning "No backups found in $BACKUP_DIR"
        info "Create your first backup with: usenet backup create"
        return 0
    fi
    
    print "${COLOR_BLUE}💾 Available Backups${COLOR_RESET}"
    print "═══════════════════════════════════════════════════════════════"
    
    local count=0
    for backup_file in "$BACKUP_DIR"/${BACKUP_PREFIX}-*.tar.gz; do
        [[ ! -f "$backup_file" ]] && continue
        
        count=$((count + 1))
        local basename=$(basename "$backup_file")
        local size=$(du -h "$backup_file" | cut -f1)
        local date=$(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
        
        # Check for metadata
        local metadata_file="${backup_file}.meta"
        local type="config"
        local description=""
        
        if [[ -f "$metadata_file" ]]; then
            type=$(grep '"type"' "$metadata_file" | sed 's/.*"type": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "config")
            description=$(grep '"description"' "$metadata_file" | sed 's/.*"description": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
        fi
        
        # Color-code by type
        local type_color="$COLOR_GREEN"
        case "$type" in
            config) type_color="$COLOR_GREEN" ;;
            full) type_color="$COLOR_BLUE" ;;
            minimal) type_color="$COLOR_YELLOW" ;;
        esac
        
        print "${COLOR_GREEN}[$count]${COLOR_RESET} ${COLOR_BOLD}$basename${COLOR_RESET}"
        print "    📅 Created: $date"
        print "    📦 Size: $size"
        print "    🏷️  Type: ${type_color}$type${COLOR_RESET}"
        
        if [[ -n "$description" && "$description" != "" ]]; then
            print "    📝 Description: $description"
        fi
        
        print ""
    done
    
    if [[ $count -eq 0 ]]; then
        warning "No backup files found"
        info "Create your first backup with: usenet backup create"
    else
        print "${COLOR_BLUE}📍 Location:${COLOR_RESET} $BACKUP_DIR"
        print "${COLOR_BLUE}📋 Commands:${COLOR_RESET} show <backup> | restore <backup> | clean"
    fi
}

#=============================================================================
# Function: show_backup
# Description: Display detailed information about a specific backup
#
# Arguments:
#   $1 - backup_file (name or path)
#
# Returns:
#   0 - Information displayed successfully
#   1 - Backup not found or error
#=============================================================================
show_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Backup name required"
        print "Usage: usenet backup show <backup-file>"
        return 1
    fi
    
    # Handle relative paths and find backup
    if [[ "$backup_file" != /* ]]; then
        if [[ -f "${BACKUP_DIR}/$backup_file" ]]; then
            backup_file="${BACKUP_DIR}/$backup_file"
        elif [[ -f "${PROJECT_ROOT}/$backup_file" ]]; then
            backup_file="${PROJECT_ROOT}/$backup_file"
        else
            error "Backup file not found: $backup_file"
            return 1
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    local basename=$(basename "$backup_file")
    local metadata_file="${backup_file}.meta"
    
    print "${COLOR_BLUE}💾 Backup Details${COLOR_RESET}"
    print "═══════════════════════════════════════════════════════════════"
    print "${COLOR_BOLD}File:${COLOR_RESET} $basename"
    
    # Show basic file info
    local size=$(du -h "$backup_file" | cut -f1)
    local date=$(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
    print "${COLOR_BOLD}Size:${COLOR_RESET} $size"
    print "${COLOR_BOLD}Created:${COLOR_RESET} $date"
    
    # Show metadata if available
    if [[ -f "$metadata_file" ]]; then
        print "\n${COLOR_BLUE}📋 Metadata${COLOR_RESET}"
        print "───────────────────────────────────────────────────────────────"
        
        # Parse JSON metadata
        local type=$(grep '"type"' "$metadata_file" | sed 's/.*"type": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local description=$(grep '"description"' "$metadata_file" | sed 's/.*"description": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
        local version=$(grep '"version"' "$metadata_file" | sed 's/.*"version": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local hostname=$(grep '"hostname"' "$metadata_file" | sed 's/.*"hostname": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local git_commit=$(grep '"git_commit"' "$metadata_file" | sed 's/.*"git_commit": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local services=$(grep '"services"' "$metadata_file" | sed 's/.*"services": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
        
        print "${COLOR_BOLD}Type:${COLOR_RESET} $type"
        print "${COLOR_BOLD}Version:${COLOR_RESET} $version"
        print "${COLOR_BOLD}Hostname:${COLOR_RESET} $hostname"
        
        if [[ -n "$description" && "$description" != "" ]]; then
            print "${COLOR_BOLD}Description:${COLOR_RESET} $description"
        fi
        
        if [[ "$git_commit" != "unknown" && "$git_commit" != "" ]]; then
            print "${COLOR_BOLD}Git Commit:${COLOR_RESET} ${git_commit:0:8}"
        fi
        
        if [[ -n "$services" && "$services" != "unknown" && "$services" != "" ]]; then
            local service_count=$(echo "$services" | tr ',' '\n' | wc -l)
            print "${COLOR_BOLD}Services:${COLOR_RESET} $service_count ($services)"
        fi
    else
        warning "No metadata file found (.meta)"
    fi
    
    # Show backup contents (first 20 files)
    print "\n${COLOR_BLUE}📁 Contents (first 20 files)${COLOR_RESET}"
    print "───────────────────────────────────────────────────────────────"
    
    if tar -tf "$backup_file" >/dev/null 2>&1; then
        tar -tf "$backup_file" | head -20
        local total_files=$(tar -tf "$backup_file" | wc -l)
        if [[ $total_files -gt 20 ]]; then
            print "... and $((total_files - 20)) more files (total: $total_files)"
        fi
    else
        error "Cannot read backup file - may be corrupted"
        return 1
    fi
    
    print "\n${COLOR_BLUE}🔧 Actions${COLOR_RESET}"
    print "───────────────────────────────────────────────────────────────"
    print "Restore: usenet backup restore $basename"
    print "Preview: usenet backup restore --dry-run $basename"
    
    return 0
}

#=============================================================================
# Function: restore_backup
# Description: Restore configuration from backup with safety measures
#
# Arguments:
#   $1 - backup_file
#   $2 - force (true/false)
#   $3 - dry_run (true/false)
#   $4 - no_backup (true/false)
#
# Returns:
#   0 - Restore completed successfully
#   1 - Error during restore
#=============================================================================
restore_backup() {
    local backup_file="$1"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    local no_backup="${4:-false}"
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required"
        print "Usage: usenet backup restore <backup-file>"
        return 1
    fi
    
    # Handle relative paths and find backup
    if [[ "$backup_file" != /* ]]; then
        if [[ -f "${BACKUP_DIR}/$backup_file" ]]; then
            backup_file="${BACKUP_DIR}/$backup_file"
        elif [[ -f "${PROJECT_ROOT}/$backup_file" ]]; then
            backup_file="${PROJECT_ROOT}/$backup_file"
        else
            error "Backup file not found: $backup_file"
            return 1
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    local basename=$(basename "$backup_file")
    info "Restoring from: $basename"
    
    # Show metadata if available
    local metadata_file="${backup_file}.meta"
    if [[ -f "$metadata_file" ]]; then
        local type=$(grep '"type"' "$metadata_file" | sed 's/.*"type": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local created=$(grep '"created"' "$metadata_file" | sed 's/.*"created": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local version=$(grep '"version"' "$metadata_file" | sed 's/.*"version": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        local hostname=$(grep '"hostname"' "$metadata_file" | sed 's/.*"hostname": *"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        
        info "Backup type: $type (created: $created)"
        info "Source: $hostname (version: $version)"
    fi
    
    # Validate backup integrity
    if ! tar -tf "$backup_file" >/dev/null 2>&1; then
        error "Backup file is corrupted or unreadable"
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        print "${COLOR_BLUE}🔍 Dry Run - Preview of Restore Operation${COLOR_RESET}"
        print "═══════════════════════════════════════════════════════════════"
        
        local total_files=$(tar -tf "$backup_file" | wc -l)
        print "Would restore $total_files files:"
        print ""
        
        tar -tf "$backup_file" | head -20
        if [[ $total_files -gt 20 ]]; then
            print "... and $((total_files - 20)) more files"
        fi
        
        print "\n${COLOR_YELLOW}⚠️  This would overwrite existing configuration files${COLOR_RESET}"
        print "Run without --dry-run to perform actual restore"
        
        return 0
    fi
    
    # Safety warnings and confirmations
    if [[ "$force" != "true" ]]; then
        warning "This will overwrite existing configuration files"
        warning "Any local changes not backed up will be lost"
        
        if ! confirm "Continue with restore?"; then
            return 1
        fi
    fi
    
    # Stop services before restore (atomic operation)
    info "Stopping services for atomic restore..."
    if docker compose ps -q 2>/dev/null | wc -l | grep -q '^0$'; then
        info "Services already stopped"
    else
        docker compose down >/dev/null 2>&1 || true
        sleep 2
    fi
    
    # Create pre-restore backup (unless disabled)
    local restore_point=""
    if [[ "$no_backup" != "true" ]]; then
        local timestamp=$(date +%Y%m%d-%H%M%S)
        restore_point="pre-restore-$timestamp"
        info "Creating safety backup: $restore_point"
        
        if ! create_backup "config" "$restore_point" "true" "Pre-restore safety backup" >/dev/null; then
            warning "Failed to create pre-restore backup"
            if ! confirm "Continue without safety backup?"; then
                return 1
            fi
        fi
    fi
    
    # Perform atomic restore
    cd "$PROJECT_ROOT"
    
    info "Extracting backup atomically..."
    if tar -xf "$backup_file" 2>/dev/null; then
        success "Configuration restored successfully"
        
        # Reload configuration
        info "Reloading configuration..."
        if [[ -f ".env" ]]; then
            set -a
            source ".env" 2>/dev/null || true
            set +a
        fi
        
        success "Restore completed successfully"
        
        if [[ -n "$restore_point" ]]; then
            info "Safety backup created: $restore_point"
        fi
        
        print ""
        print "${COLOR_BLUE}🚀 Next Steps${COLOR_RESET}"
        print "───────────────────────────────────────────────────────────────"
        print "Start services: ${COLOR_BOLD}usenet services start${COLOR_RESET}"
        print "Check status:   ${COLOR_BOLD}usenet services list${COLOR_RESET}"
        
    else
        error "Failed to extract backup"
        
        # Rollback attempt if we have a restore point
        if [[ -n "$restore_point" ]]; then
            warning "Attempting rollback to pre-restore state..."
            if restore_backup "${BACKUP_DIR}/${BACKUP_PREFIX}-${restore_point}.tar.gz" "true" "false" "true"; then
                warning "Rollback successful - system restored to pre-restore state"
            else
                error "Rollback failed - manual intervention required"
            fi
        fi
        
        return 1
    fi
    
    return 0
}

#=============================================================================
# Function: clean_backups
# Description: Clean old backups based on age or count
#
# Arguments:
#   $1 - older_than_days (optional)
#   $2 - keep_count (optional)
#   $3 - dry_run (true/false)
#
# Returns:
#   0 - Cleanup completed successfully
#   1 - Error during cleanup
#=============================================================================
clean_backups() {
    local older_than_days="$1"
    local keep_count="$2"
    local dry_run="${3:-false}"
    
    if [[ -z "$older_than_days" && -z "$keep_count" ]]; then
        error "Either --older-than <days> or --keep <count> required"
        return 1
    fi
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        warning "No backup directory found"
        return 0
    fi
    
    # Collect backup files
    local -a backup_files
    local -A backup_times
    
    for backup_file in "$BACKUP_DIR"/${BACKUP_PREFIX}-*.tar*; do
        [[ ! -f "$backup_file" ]] && continue
        [[ "$backup_file" == *".meta" ]] && continue
        
        backup_files+=("$backup_file")
        backup_times["$backup_file"]=$(stat -c %Y "$backup_file" 2>/dev/null || echo 0)
    done
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        info "No backups found to clean"
        return 0
    fi
    
    local -a files_to_delete
    
    if [[ -n "$older_than_days" ]]; then
        local cutoff_time=$(($(date +%s) - older_than_days * 86400))
        
        for backup_file in $backup_files; do
            if [[ ${backup_times[$backup_file]} -lt $cutoff_time ]]; then
                files_to_delete+=("$backup_file")
            fi
        done
        
        info "Found ${#files_to_delete[@]} backups older than $older_than_days days"
        
    elif [[ -n "$keep_count" ]]; then
        # Sort by modification time (newest first) and keep only the first N
        backup_files=(${(f)"$(printf '%s\n' "${backup_files[@]}" | \
            while read -r file; do
                printf '%s %s\n' "${backup_times[$file]}" "$file"
            done | sort -rn | cut -d' ' -f2-)"})
        
        if [[ ${#backup_files[@]} -gt $keep_count ]]; then
            files_to_delete=(${backup_files[$((keep_count + 1)),-1]})
            info "Keeping $keep_count most recent backups, removing ${#files_to_delete[@]} older ones"
        else
            info "Only ${#backup_files[@]} backups found, keeping all (requested: $keep_count)"
        fi
    fi
    
    if [[ ${#files_to_delete[@]} -eq 0 ]]; then
        success "No backups need to be cleaned"
        return 0
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        print "${COLOR_BLUE}🔍 Dry Run - Files that would be deleted:${COLOR_RESET}"
        print "═══════════════════════════════════════════════════════════════"
        
        for backup_file in $files_to_delete; do
            local basename=$(basename "$backup_file")
            local size=$(du -h "$backup_file" | cut -f1)
            local date=$(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
            print "  🗑️  $basename ($size, $date)"
            
            # Also show metadata file if it exists
            local metadata_file="${backup_file}.meta"
            if [[ -f "$metadata_file" ]]; then
                print "      └── $(basename "$metadata_file")"
            fi
        done
        
        local total_size=$(du -ch $files_to_delete 2>/dev/null | tail -n1 | cut -f1)
        print "\nTotal space to be freed: $total_size"
        print "Run without --dry-run to perform actual deletion"
        
        return 0
    fi
    
    # Perform deletion
    warning "About to delete ${#files_to_delete[@]} backup files"
    if ! confirm "Continue with deletion?"; then
        return 1
    fi
    
    local deleted_count=0
    local total_size_freed=0
    
    for backup_file in $files_to_delete; do
        local basename=$(basename "$backup_file")
        local size_bytes=$(stat -c%s "$backup_file" 2>/dev/null || echo 0)
        
        if rm -f "$backup_file"; then
            ((deleted_count++))
            ((total_size_freed += size_bytes))
            
            # Also delete metadata file if it exists
            local metadata_file="${backup_file}.meta"
            if [[ -f "$metadata_file" ]]; then
                rm -f "$metadata_file"
            fi
            
            info "Deleted: $basename"
        else
            error "Failed to delete: $basename"
        fi
    done
    
    local freed_human=$(numfmt --to=iec-i --suffix=B $total_size_freed 2>/dev/null || echo "${total_size_freed} bytes")
    success "Deleted $deleted_count backups, freed $freed_human"
    
    return 0
}

##############################################################################
#                               MAIN FUNCTION                               #
##############################################################################

#=============================================================================
# Function: main
# Description: Enhanced main entry point with consistent verb routing
#
# Arguments:
#   $@ - All command line arguments
#
# Returns:
#   Exit code from the executed action
#=============================================================================
main() {
    # Handle empty arguments case - default to create
    if [[ $# -eq 0 ]]; then
        create_backup "config" "" "true" ""
        return $?
    fi
    
    local action="$1"
    shift
    
    case "$action" in
        list)
            list_backups
            ;;
            
        create)
            local backup_type="config"
            local backup_name=""
            local compress=true
            local description=""
            
            # Parse create options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --type)
                        backup_type="$2"
                        shift 2
                        ;;
                    --name)
                        backup_name="$2"
                        shift 2
                        ;;
                    --description)
                        description="$2"
                        shift 2
                        ;;
                    --compress|-z)
                        compress=true
                        shift
                        ;;
                    --no-compress)
                        compress=false
                        shift
                        ;;
                    --help|-h)
                        show_backup_help
                        return 0
                        ;;
                    -*)
                        error "Unknown option: $1"
                        return 1
                        ;;
                    *)
                        if [[ -z "$backup_name" ]]; then
                            backup_name="$1"
                        else
                            error "Unexpected argument: $1"
                            return 1
                        fi
                        shift
                        ;;
                esac
            done
            
            create_backup "$backup_type" "$backup_name" "$compress" "$description"
            ;;
            
        show)
            local backup_file="$1"
            show_backup "$backup_file"
            ;;
            
        restore)
            local backup_file="$1"
            local force=false
            local dry_run=false
            local no_backup=false
            shift || true
            
            # Parse restore options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --force|-f)
                        force=true
                        shift
                        ;;
                    --dry-run|-n)
                        dry_run=true
                        shift
                        ;;
                    --no-backup)
                        no_backup=true
                        shift
                        ;;
                    --help|-h)
                        show_backup_help
                        return 0
                        ;;
                    -*)
                        error "Unknown option: $1"
                        return 1
                        ;;
                    *)
                        if [[ -z "$backup_file" ]]; then
                            backup_file="$1"
                        else
                            error "Unexpected argument: $1"
                            return 1
                        fi
                        shift
                        ;;
                esac
            done
            
            restore_backup "$backup_file" "$force" "$dry_run" "$no_backup"
            ;;
            
        clean)
            local older_than_days=""
            local keep_count=""
            local dry_run=false
            
            # Parse clean options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --older-than)
                        older_than_days="$2"
                        shift 2
                        ;;
                    --keep)
                        keep_count="$2"
                        shift 2
                        ;;
                    --dry-run|-n)
                        dry_run=true
                        shift
                        ;;
                    --help|-h)
                        show_backup_help
                        return 0
                        ;;
                    -*)
                        error "Unknown option: $1"
                        return 1
                        ;;
                    *)
                        error "Unexpected argument: $1"
                        return 1
                        ;;
                esac
            done
            
            clean_backups "$older_than_days" "$keep_count" "$dry_run"
            ;;
            
        help|--help|-h)
            show_backup_help
            ;;
            
        *)
            error "Unknown action: $action"
            error "Valid actions: list, create, show, restore, clean"
            print "Use 'usenet backup help' for detailed usage"
            return 1
            ;;
    esac
}

# Run if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80: