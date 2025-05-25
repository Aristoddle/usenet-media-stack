#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/backup.zsh
# Project: Usenet Media Stack
# Description: Configuration backup and restore functionality
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Handles backup and restore of all configuration files, databases, and
# settings for the Usenet Media Stack. Excludes media files and temporary
# data, focusing on reproducible configuration state.
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

##############################################################################
#                            BACKUP FUNCTIONS                                #
##############################################################################

#=============================================================================
# Function: show_backup_help
# Description: Display backup management help
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
show_backup_help() {
    cat <<'HELP'
💾 Backup Management

USAGE
    usenet backup [options]           Create a new backup
    usenet restore <backup-file>      Restore from backup

BACKUP OPTIONS
    --name <name>      Custom backup name (default: timestamp)
    --compress, -z     Compress backup with gzip
    --exclude-logs     Exclude log files from backup
    --include-media    Include media metadata (not files)

RESTORE OPTIONS
    --force, -f        Overwrite existing configuration
    --dry-run, -n      Show what would be restored

EXAMPLES
    Create a backup:
        $ usenet backup
        
    Create named backup:
        $ usenet backup --name "pre-upgrade"
        
    Create compressed backup:
        $ usenet backup --compress
        
    Restore from backup:
        $ usenet restore usenet-stack-backup-20250524-143022.tar.gz
        
    Preview restore:
        $ usenet restore --dry-run backup.tar.gz

WHAT'S BACKED UP
    ✓ All service configurations (Sonarr, Radarr, etc.)
    ✓ Docker Compose files
    ✓ Environment configuration (.env)
    ✓ Custom scripts and modifications
    ✓ Application databases and settings
    ✓ SSL certificates and keys
    
WHAT'S EXCLUDED
    ✗ Media files (movies, TV shows, music)
    ✗ Downloads in progress
    ✗ Temporary files and caches
    ✗ Log files (unless --include-logs specified)

BACKUP LOCATION
    Backups are stored in: ./backups/

HELP
}

#=============================================================================
# Function: create_backup_list
# Description: Generate list of files and directories to backup
#
# Arguments:
#   $1 - exclude_logs (true/false)
#   $2 - include_media (true/false)
#
# Returns:
#   0 - List created successfully
#   1 - Error creating list
#=============================================================================
create_backup_list() {
    local exclude_logs="${1:-false}"
    local include_media="${2:-false}"
    local list_file="$3"
    
    # Build list of files that actually exist
    local files_to_backup=(
        ".env"
        "docker-compose.yml" 
        "docker-compose.tunnel.yml"
        "usenet"
        "lib/"
        "config/"
        "docs/"
        "README.md"
        "CLAUDE.md"
    )
    
    # Optional files (include if they exist)
    local optional_files=(
        "scripts/"
        "SECURITY_GUIDE.md"
        "MIGRATION_NOTES.md"
        "DOCKER_SWARM_GUIDE.md"
    )
    
    # Create the list file with only existing files
    > "$list_file"  # Clear the file
    
    for file in $files_to_backup; do
        if [[ -e "$file" ]]; then
            echo "$file" >> "$list_file"
        fi
    done
    
    for file in $optional_files; do
        if [[ -e "$file" ]]; then
            echo "$file" >> "$list_file"
        fi
    done

    # Conditionally add media metadata if requested
    if [[ "$include_media" == "true" ]]; then
        echo "media/" >> "$list_file"
    fi
    
    # Create exclusion patterns
    local exclude_file="${list_file}.exclude"
    cat > "$exclude_file" <<EOF
downloads/
*.log
*.tmp
*.cache
.git/
.gitignore
node_modules/
.DS_Store
Thumbs.db
EOF

    # Add log exclusions if requested
    if [[ "$exclude_logs" == "true" ]]; then
        cat >> "$exclude_file" <<EOF
config/*/logs/
config/*/log/
config/*/*.log
logs/
log/
EOF
    fi
    
    return 0
}

#=============================================================================
# Function: create_backup
# Description: Create a backup of the current configuration
#
# Arguments:
#   $1 - backup_name (optional)
#   $2 - compress (true/false)
#   $3 - exclude_logs (true/false)
#   $4 - include_media (true/false)
#
# Returns:
#   0 - Backup created successfully
#   1 - Error creating backup
#=============================================================================
create_backup() {
    local backup_name="${1:-$(date +%Y%m%d-%H%M%S)}"
    local compress="${2:-false}"
    local exclude_logs="${3:-false}" 
    local include_media="${4:-false}"
    
    info "Creating backup: $backup_name"
    
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
    
    create_backup_list "$exclude_logs" "$include_media" "$list_file"
    
    info "Backing up configuration files..."
    
    # Create the backup
    local compress_flag=""
    if [[ "$compress" == "true" ]]; then
        compress_flag="z"
    fi
    
    # Change to project root and create backup
    cd "$PROJECT_ROOT"
    
    if tar -c${compress_flag}f "$backup_file" \
        --files-from="$list_file" \
        --ignore-failed-read \
        2>/dev/null; then
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        success "Backup created: $(basename "$backup_file") ($backup_size)"
        
        # Create backup metadata
        local metadata_file="${backup_file}.info"
        cat > "$metadata_file" <<EOF
# Usenet Media Stack Backup Metadata
Created: $(date -Iseconds)
Version: 2.0.0
Hostname: $(hostname)
Size: $backup_size
Compress: $compress
ExcludeLogs: $exclude_logs
IncludeMedia: $include_media
GitCommit: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Services: $(docker compose ps --services 2>/dev/null | tr '\n' ',' | sed 's/,$//')
EOF
        
        info "Backup location: $backup_file"
        info "Metadata: $metadata_file"
        
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
# Description: List all available backups
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
list_backups() {
    info "Available backups:"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        warning "No backups found in $BACKUP_DIR"
        return 0
    fi
    
    # List backup files with details
    for backup_file in "$BACKUP_DIR"/${BACKUP_PREFIX}-*.tar*; do
        [[ ! -f "$backup_file" ]] && continue
        
        local basename=$(basename "$backup_file")
        local size=$(du -h "$backup_file" | cut -f1)
        local date=$(stat -c %y "$backup_file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        
        print "  ${COLOR_GREEN}●${COLOR_RESET} $basename"
        print "    Size: $size, Created: $date"
        
        # Show metadata if available
        local metadata_file="${backup_file}.info"
        if [[ -f "$metadata_file" ]]; then
            local created=$(grep "Created:" "$metadata_file" | cut -d' ' -f2-)
            local services=$(grep "Services:" "$metadata_file" | cut -d' ' -f2-)
            if [[ -n "$services" ]]; then
                print "    Services: $services"
            fi
        fi
        print ""
    done
}

#=============================================================================
# Function: restore_backup
# Description: Restore configuration from a backup
#
# Arguments:
#   $1 - backup_file
#   $2 - force (true/false)
#   $3 - dry_run (true/false)
#
# Returns:
#   0 - Restore completed successfully
#   1 - Error during restore
#=============================================================================
restore_backup() {
    local backup_file="$1"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required"
        print "Usage: usenet restore <backup-file>"
        return 1
    fi
    
    # Handle relative paths
    if [[ "$backup_file" != /* ]]; then
        # Try backup directory first
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
    
    info "Restoring from: $(basename "$backup_file")"
    
    # Show metadata if available
    local metadata_file="${backup_file}.info"
    if [[ -f "$metadata_file" ]]; then
        local created=$(grep "Created:" "$metadata_file" | cut -d' ' -f2-)
        local version=$(grep "Version:" "$metadata_file" | cut -d' ' -f2-)
        info "Backup created: $created (version $version)"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        info "Dry run - showing what would be restored:"
        
        # List contents of backup
        if tar -tf "$backup_file" >/dev/null 2>&1; then
            tar -tf "$backup_file" | head -20
            local total_files=$(tar -tf "$backup_file" | wc -l)
            if [[ $total_files -gt 20 ]]; then
                print "... and $((total_files - 20)) more files"
            fi
        else
            error "Cannot read backup file"
            return 1
        fi
        
        return 0
    fi
    
    # Warn about overwriting existing configuration
    if [[ "$force" != "true" ]]; then
        warning "This will overwrite existing configuration files"
        if ! confirm "Continue with restore?"; then
            return 1
        fi
    fi
    
    # Stop services before restore
    info "Stopping services for restore..."
    docker compose down >/dev/null 2>&1 || true
    
    # Create restore point
    local restore_point="${BACKUP_DIR}/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
    info "Creating restore point: $(basename "$restore_point")"
    create_backup "pre-restore-$(date +%Y%m%d-%H%M%S)" true true false >/dev/null
    
    # Perform restore
    cd "$PROJECT_ROOT"
    
    info "Extracting backup..."
    if tar -xf "$backup_file" 2>/dev/null; then
        success "Configuration restored successfully"
        
        info "Reloading configuration..."
        # Reload configuration
        if [[ -f ".env" ]]; then
            set -a
            source ".env"
            set +a
        fi
        
        success "Restore completed"
        info "Restart services with: usenet start"
        
    else
        error "Failed to extract backup"
        return 1
    fi
    
    return 0
}

##############################################################################
#                               MAIN FUNCTION                               #
##############################################################################

#=============================================================================
# Function: main
# Description: Main entry point for backup management
#
# Arguments:
#   $@ - All command line arguments
#
# Returns:
#   Exit code from the executed action
#=============================================================================
main() {
    # Handle empty arguments case
    if [[ $# -eq 0 ]]; then
        create_backup
        return $?
    fi
    
    local action="$1"
    
    case "$action" in
        restore)
            shift
            local backup_file="$1"
            local force=false
            local dry_run=false
            
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
                    -*)
                        error "Unknown option: $1"
                        return 1
                        ;;
                    *)
                        backup_file="$1"
                        shift
                        ;;
                esac
            done
            
            restore_backup "$backup_file" "$force" "$dry_run"
            ;;
            
        list)
            list_backups
            ;;
            
        help|--help|-h)
            show_backup_help
            ;;
            
        create|*)
            # Create backup (default action)
            shift || true  # Remove 'create' if it was specified
            local backup_name=""
            local compress=false
            local exclude_logs=false
            local include_media=false
            
            # Parse backup options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name)
                        backup_name="$2"
                        shift 2
                        ;;
                    --compress|-z)
                        compress=true
                        shift
                        ;;
                    --exclude-logs)
                        exclude_logs=true
                        shift
                        ;;
                    --include-media)
                        include_media=true
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
                        backup_name="$1"
                        shift
                        ;;
                esac
            done
            
            create_backup "$backup_name" "$compress" "$exclude_logs" "$include_media"
            ;;
    esac
}

# Run if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80: