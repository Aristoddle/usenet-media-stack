#!/usr/bin/env bash
# travel-ingest.sh - Organize completed downloads from portable mode
#
# Purpose:
#   When traveling with the portable stack (no external bays), downloads
#   go to the internal 8TB drive. This script organizes them into the
#   appropriate collection folders for reading apps.
#
# Usage:
#   ./travel-ingest.sh [--dry-run] [--watch]
#
# Modes:
#   (default)   One-shot: process pending downloads and exit
#   --dry-run   Show what would be moved without moving
#   --watch     Continuous mode: watch for new downloads
#
# Content classification:
#   - Comics/Manga: .cbz, .cbr → Comics/
#   - eBooks: .epub, .mobi, .azw3, .pdf (books) → eBooks/
#   - Audiobooks: .m4b, .mp3 (audiobooks dir) → Audiobooks/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"

# Source and destination paths (configurable via env)
DOWNLOADS_ROOT="${DOWNLOADS_ROOT_PORTABLE:-/var/mnt/fast8tb/Local/downloads}"
BOOKS_ROOT="${BOOKS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books}"

COMICS_DEST="$BOOKS_ROOT/Comics"
EBOOKS_DEST="$BOOKS_ROOT/eBooks"
AUDIOBOOKS_DEST="$BOOKS_ROOT/Audiobooks"

LOG_FILE="/tmp/media-stack/travel-ingest.log"
DRY_RUN=false
WATCH_MODE=false

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_dry()   { log "DRY-RUN" "$@"; }

# =============================================================================
# CONTENT CLASSIFICATION
# =============================================================================

# Determine content type from file extension and path
classify_file() {
    local file="$1"
    local ext="${file##*.}"
    local lower_ext="${ext,,}"  # Lowercase
    local dir="$(dirname "$file")"

    case "$lower_ext" in
        cbz|cbr|cb7)
            echo "comics"
            ;;
        epub|mobi|azw|azw3)
            echo "ebooks"
            ;;
        m4b)
            echo "audiobooks"
            ;;
        pdf)
            # PDFs could be ebooks or comics - check filename/path patterns
            if [[ "$file" =~ [Mm]anga|[Cc]omic|[Cc]hapter|[Vv]ol\.? ]]; then
                echo "comics"
            else
                echo "ebooks"
            fi
            ;;
        mp3)
            # MP3 could be audiobook or music - check path
            if [[ "$dir" =~ [Aa]udiobook|[Nn]arrat ]]; then
                echo "audiobooks"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get destination directory for content type
get_destination() {
    local content_type="$1"
    case "$content_type" in
        comics)     echo "$COMICS_DEST" ;;
        ebooks)     echo "$EBOOKS_DEST" ;;
        audiobooks) echo "$AUDIOBOOKS_DEST" ;;
        *)          echo "" ;;
    esac
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Check if file already exists at destination
check_duplicate() {
    local src_file="$1"
    local dest_dir="$2"
    local filename="$(basename "$src_file")"

    if [[ -f "$dest_dir/$filename" ]]; then
        local src_size dest_size
        src_size=$(stat -c %s "$src_file" 2>/dev/null || echo 0)
        dest_size=$(stat -c %s "$dest_dir/$filename" 2>/dev/null || echo 0)

        if [[ "$src_size" -eq "$dest_size" ]]; then
            echo "exact"  # Same size - likely duplicate
        else
            echo "different"  # Different sizes - needs resolution
        fi
    else
        echo "new"  # Doesn't exist
    fi
}

# Move file to destination
move_file() {
    local src="$1"
    local dest_dir="$2"
    local filename="$(basename "$src")"

    if $DRY_RUN; then
        log_dry "Would move: $src -> $dest_dir/"
        return 0
    fi

    # Ensure destination exists
    mkdir -p "$dest_dir"

    # Check for duplicates
    local dup_status
    dup_status=$(check_duplicate "$src" "$dest_dir")

    case "$dup_status" in
        exact)
            log_info "Duplicate (same size), removing source: $filename"
            rm -f "$src"
            ;;
        different)
            log_warn "File exists with different size, keeping both: $filename"
            local base="${filename%.*}"
            local ext="${filename##*.}"
            local new_name="${base}_$(date +%Y%m%d%H%M%S).${ext}"
            mv "$src" "$dest_dir/$new_name"
            log_info "Moved as: $new_name"
            ;;
        new)
            mv "$src" "$dest_dir/"
            log_info "Moved: $filename -> $dest_dir/"
            ;;
    esac
}

# =============================================================================
# DIRECTORY SCANNING
# =============================================================================

# Find and process all downloadable content
process_downloads() {
    local processed=0
    local skipped=0
    local failed=0

    log_info "Scanning downloads at: $DOWNLOADS_ROOT"

    # Find all relevant files
    while IFS= read -r -d '' file; do
        local content_type
        content_type=$(classify_file "$file")

        if [[ "$content_type" == "unknown" ]]; then
            ((skipped++)) || true
            continue
        fi

        local dest
        dest=$(get_destination "$content_type")

        if [[ -z "$dest" ]]; then
            log_warn "No destination for: $file"
            ((skipped++)) || true
            continue
        fi

        if move_file "$file" "$dest"; then
            ((processed++)) || true
        else
            ((failed++)) || true
        fi

    done < <(find "$DOWNLOADS_ROOT" -type f \
        \( -iname "*.cbz" -o -iname "*.cbr" -o -iname "*.cb7" \
           -o -iname "*.epub" -o -iname "*.mobi" -o -iname "*.azw" -o -iname "*.azw3" \
           -o -iname "*.pdf" -o -iname "*.m4b" \) \
        -print0 2>/dev/null)

    log_info "Processing complete: $processed moved, $skipped skipped, $failed failed"

    # Clean up empty directories
    if ! $DRY_RUN; then
        find "$DOWNLOADS_ROOT" -type d -empty -delete 2>/dev/null || true
    fi
}

# Process SABnzbd completed directory
process_sabnzbd() {
    local sab_complete="$DOWNLOADS_ROOT/complete"
    if [[ -d "$sab_complete" ]]; then
        log_info "Processing SABnzbd completed downloads..."
        DOWNLOADS_ROOT="$sab_complete" process_downloads
    fi
}

# Process Transmission completed directory
process_transmission() {
    local tx_complete="$DOWNLOADS_ROOT/complete"
    if [[ -d "$tx_complete" ]]; then
        log_info "Processing Transmission completed downloads..."
        DOWNLOADS_ROOT="$tx_complete" process_downloads
    fi
}

# =============================================================================
# WATCH MODE
# =============================================================================

watch_downloads() {
    log_info "Starting watch mode (Ctrl+C to stop)..."

    # Initial processing
    process_downloads
    process_sabnzbd
    process_transmission

    # Use inotifywait if available, otherwise poll
    if command -v inotifywait &>/dev/null; then
        log_info "Using inotify for efficient file watching"
        while true; do
            inotifywait -q -r -e close_write,moved_to "$DOWNLOADS_ROOT" 2>/dev/null || sleep 30
            sleep 5  # Debounce
            process_downloads
        done
    else
        log_info "inotifywait not available, using polling (60s interval)"
        while true; do
            sleep 60
            process_downloads
        done
    fi
}

# =============================================================================
# MAIN
# =============================================================================

show_usage() {
    echo "Usage: $0 [--dry-run] [--watch]"
    echo ""
    echo "Organize completed downloads from portable/travel mode into reading collections."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be moved without moving"
    echo "  --watch      Continuous mode: watch for new downloads"
    echo ""
    echo "Environment:"
    echo "  DOWNLOADS_ROOT_PORTABLE  Source directory (default: /var/mnt/fast8tb/Local/downloads)"
    echo "  BOOKS_ROOT               Destination base (default: /var/mnt/fast8tb/Cloud/OneDrive/Books)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate paths
if [[ ! -d "$DOWNLOADS_ROOT" ]]; then
    log_error "Downloads directory not found: $DOWNLOADS_ROOT"
    exit 1
fi

if [[ ! -d "$BOOKS_ROOT" ]]; then
    log_error "Books root not found: $BOOKS_ROOT"
    exit 1
fi

# Run
if $WATCH_MODE; then
    watch_downloads
else
    process_downloads
    process_sabnzbd
    process_transmission
fi
