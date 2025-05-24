#!/usr/bin/env zsh
# File: ./lib/help.zsh
# Beautiful help system for Usenet Media Stack

# Colors (zsh style)
autoload -U colors && colors

show_help() {
    local topic="${1:-main}"
    
    case "$topic" in
        main|"")
            show_main_help
            ;;
        setup)
            show_setup_help
            ;;
        storage)
            show_storage_help
            ;;
        manage)
            show_manage_help
            ;;
        *)
            print -u2 "No help for topic: $topic"
            exit 1
            ;;
    esac
}

show_main_help() {
    cat <<'HELP'
🎬 Usenet Media Stack v2.0

USAGE
    usenet <command> [options]

QUICK START
    usenet setup                 # Deploy everything
    usenet status               # Check what's running
    usenet storage add /disk2   # Add storage

COMMANDS
    Setup & Deploy
        setup                   Deploy the complete stack
        update                  Update all containers
        
    Service Management  
        status                  Show all services
        start                   Start all services
        stop                    Stop all services
        restart                 Restart all services
        logs [service]          View logs
        
    Storage Management
        storage status          Show storage info
        storage add <path>      Add drive to pool
        storage remove <path>   Remove drive safely
        
    Maintenance
        backup                  Backup configuration
        restore <file>          Restore from backup
        test                    Run system tests
        deps                    Check dependencies

OPTIONS
    --help, -h              Show help
    --version, -v           Show version
    --verbose               Detailed output

EXAMPLES
    First time setup:
        $ usenet setup
        
    Add new hard drive:
        $ usenet storage add /mnt/new-8tb
        
    Debug issues:
        $ usenet logs sonarr

DOCS
    Full Guide: https://github.com/Aristoddle/usenet-media-stack/wiki

HELP
}

show_setup_help() {
    cat <<'HELP'
SETUP COMMAND

USAGE
    usenet setup [options]

DESCRIPTION
    Interactive deployment of the complete media stack:
    • SABnzbd (Usenet downloads)
    • Sonarr (TV management)
    • Radarr (Movie management)  
    • Prowlarr (Indexer management)
    • Jellyfin (Media streaming)
    • And more...

OPTIONS
    --test              Dry run (no changes)
    --skip-deps         Skip dependency check
    --verbose           Show all output
    --import <backup>   Restore from backup

PROCESS
    1. Check dependencies (Docker, etc)
    2. Verify system resources
    3. Configure storage paths
    4. Deploy Docker containers
    5. Configure services
    6. Run health checks

EXAMPLES
    Interactive setup:
        $ usenet setup
        
    Test first:
        $ usenet setup --test

EXIT CODES
    0 = Success
    1 = Missing dependencies
    2 = Docker error
    3 = Configuration error

HELP
}

show_storage_help() {
    cat <<'HELP'
STORAGE MANAGEMENT

USAGE
    usenet storage <action> [options]

ACTIONS
    status              Show current configuration
    add <path>          Add drive/directory
    remove <path>       Remove drive (safely)
    balance             Redistribute content

HOW IT WORKS
    The stack uses JBOD (Just a Bunch Of Disks):
    • No RAID required
    • Add/remove drives anytime
    • Services span multiple drives
    • Automatic path management

STRUCTURE
    /media/
    ├── tv/         → Sonarr
    ├── movies/     → Radarr
    ├── music/      → Lidarr
    └── downloads/  → SABnzbd

ADDING A DRIVE
    1. Mount drive (e.g., /mnt/disk2)
    2. Run: usenet storage add /mnt/disk2
    3. Services automatically use new space

TIPS
    • Use ext4 or XFS filesystem
    • Set up /etc/fstab for auto-mount
    • Label drives clearly
    • Consider mergerfs for pooling

HELP
}

show_manage_help() {
    cat <<'HELP'
SERVICE MANAGEMENT

USAGE
    usenet manage <action> [service]
    usenet <action> [service]        # shortcuts

ACTIONS
    status              Show all services
    start [service]     Start service(s)
    stop [service]      Stop service(s)
    restart [service]   Restart service(s)
    logs [service]      View logs
    
SERVICES
    Core
        sabnzbd         Download client
        prowlarr        Indexer manager
        
    Media Management
        sonarr          TV shows
        radarr          Movies
        lidarr          Music
        readarr         Books
        
    Streaming
        jellyfin        Media server
        overseerr       Request manager
        
    Support
        bazarr          Subtitles
        unpackerr       Extraction

EXAMPLES
    Check everything:
        $ usenet status
        
    Restart Sonarr:
        $ usenet restart sonarr
        
    View SABnzbd logs:
        $ usenet logs sabnzbd

HELP
}

show_version() {
    print "Usenet Media Stack"
    print "Version: ${VERSION}"
    print "Platform: $(uname -s) $(uname -m)"
    print ""
    
    # Check components
    print "Components:"
    if command -v docker &>/dev/null; then
        print "  Docker: $(docker --version | cut -d' ' -f3)"
    else
        print "  Docker: not installed"
    fi
    
    if docker compose version &>/dev/null 2>&1; then
        print "  Compose: $(docker compose version | cut -d' ' -f4)"
    else
        print "  Compose: not installed"
    fi
}