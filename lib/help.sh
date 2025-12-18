#!/usr/bin/env bash
##############################################################################
# help.sh - Beautiful, consistent help system
##############################################################################

# Colors for beautiful output
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'

##
# Display main help menu
##
show_main_help() {
    cat << 'EOF'

🎬 Usenet Media Stack v2.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE
    usenet <command> [options]

CORE COMMANDS
    setup               Deploy the complete media stack
    manage <action>     Control running services  
    storage <action>    Manage drives and storage pools
    
MANAGEMENT COMMANDS    
    status              Show health of all services
    logs [service]      View logs (all or specific service)
    update              Update all containers to latest
    backup              Backup all configuration
    restore <file>      Restore from backup
    
UTILITY COMMANDS
    test                Run system tests
    validate            Pre-deployment validation  
    deps                Check/install dependencies
    uninstall           Remove everything (with confirmation)
    
OPTIONS
    --help, -h          Show this help
    --version, -v       Show version info
    --verbose           Detailed output
    --quiet             Minimal output

EXAMPLES
    Setup new system interactively:
        $ usenet setup
        
    Add a new drive to media pool:
        $ usenet storage add /mnt/disk2
        
    Check what's running:
        $ usenet status
        
    View logs for debugging:
        $ usenet logs sonarr

QUICK LINKS
    📖 Full Guide:      https://github.com/you/repo/wiki
    💾 Storage Setup:   https://github.com/you/repo/wiki/storage
    🐛 Troubleshoot:    https://github.com/you/repo/wiki/troubleshooting
    
EOF
}

##
# Display setup command help
##
show_setup_help() {
    cat << 'EOF'

SETUP COMMAND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE
    usenet setup [options]

DESCRIPTION
    Deploy and configure the complete Usenet media automation stack.
    Includes: SABnzbd, Sonarr, Radarr, Prowlarr, Plex, and more.

OPTIONS
    --test-only         Run deployment in test mode (no changes)
    --skip-deps         Skip dependency checks (advanced users)
    --with-vpn          Include VPN container (Gluetun)
    --import <file>     Import configuration from backup
    --verbose           Show detailed progress

INTERACTIVE MODE
    Running without options starts interactive setup:
    - Checks all dependencies
    - Prompts for missing requirements  
    - Configures storage locations
    - Sets up 1Password integration (optional)
    - Deploys all services
    - Runs health checks

EXAMPLES
    Basic setup:
        $ usenet setup
        
    Test mode first:
        $ usenet setup --test-only
        
    Import existing config:
        $ usenet setup --import backup-2024.tar.gz

EXIT CODES
    0   Success
    1   Dependency missing
    2   Docker not available
    3   Configuration error
    4   Deployment failed
    
EOF
}

##
# Display storage command help  
##
show_storage_help() {
    cat << 'EOF'

STORAGE MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE
    usenet storage <action> [options]

ACTIONS
    status              Show current storage configuration
    add <path>          Add drive/directory to media pool
    remove <path>       Remove drive from pool (safely)
    balance             Rebalance content across drives
    check               Verify storage health and permissions

STORAGE CONCEPTS
    The stack uses JBOD (Just a Bunch Of Disks) approach:
    - Each service can span multiple drives
    - No RAID required (but supported)
    - Easy to add/remove drives
    - Automatic path management

DIRECTORY STRUCTURE
    /media/
    ├── tv/             → Sonarr managed
    ├── movies/         → Radarr managed  
    ├── music/          → Lidarr managed
    └── downloads/      → SABnzbd workspace

EXAMPLES
    View current setup:
        $ usenet storage status
        
    Add new 8TB drive:
        $ usenet storage add /mnt/new-8tb-drive
        
    Remove failing drive:
        $ usenet storage remove /mnt/old-drive

TIPS
    • Format drives as ext4 or xfs for best performance
    • Use meaningful mount points (/mnt/8tb-movies)
    • Set up /etc/fstab for automatic mounting
    • Consider mergerfs for unified view

EOF
}

##
# Show version information
##
show_version() {
    local version="2.0.0"
    local build_date="2024-01-20"
    
    echo "Usenet Media Stack"
    echo "Version: $version"
    echo "Build Date: $build_date"
    echo "Platform: $(uname -s) $(uname -m)"
    echo ""
    echo "Components:"
    echo "  • Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 || echo 'not found')"
    echo "  • Compose: $(docker compose version 2>/dev/null | cut -d' ' -f4 || echo 'not found')"
}

# Export all functions
export -f show_main_help show_setup_help show_storage_help show_version