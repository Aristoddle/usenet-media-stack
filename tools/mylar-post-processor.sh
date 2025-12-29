#!/usr/bin/env bash
# mylar-post-processor.sh
# SABnzbd post-processing script for Mylar comic downloads
#
# This script is called by SABnzbd after extracting a comic download.
# It normalizes filenames, moves to the Comics library, and triggers Komga scan.
#
# SABnzbd Post-Processing Script Setup:
#   1. Go to SABnzbd -> Config -> Folders -> Scripts Folder
#   2. Point to this script's directory
#   3. In Mylar, set SABnzbd post-processing script to "mylar-post-processor.sh"
#
# SABnzbd passes these positional arguments:
#   $1 = Final directory (full path)
#   $2 = Original NZB name
#   $3 = Clean job name
#   $4 = Indexer report number
#   $5 = User-defined category
#   $6 = Group NZB was posted to
#   $7 = Post-processing status (0=OK, 1=failed verification, 2=failed unpack, 3=failed verification+unpack)
#
# USAGE (manual):
#   ./tools/mylar-post-processor.sh "/path/to/download" "Original.NZB.Name" "Clean Job Name"

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration (override via environment or .env)
COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
KOMGA_URL="${KOMGA_URL:-http://localhost:8081}"
KOMGA_USER="${KOMGA_USERNAME:-}"
KOMGA_PASS="${KOMGA_PASSWORD:-}"
LOG_FILE="${LOG_FILE:-/var/log/mylar-post-processor.log}"

# SABnzbd arguments
DOWNLOAD_DIR="${1:-}"
NZB_NAME="${2:-}"
JOB_NAME="${3:-}"
INDEXER="${4:-}"
CATEGORY="${5:-}"
GROUP="${6:-}"
STATUS="${7:-0}"

log() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
    echo -e "${GREEN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

warn() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1"
    echo -e "${YELLOW}$msg${NC}"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1"
    echo -e "${RED}$msg${NC}" >&2
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Validate inputs
validate_inputs() {
    if [[ -z "$DOWNLOAD_DIR" ]]; then
        error "No download directory provided"
        exit 1
    fi

    if [[ ! -d "$DOWNLOAD_DIR" ]]; then
        error "Download directory does not exist: $DOWNLOAD_DIR"
        exit 1
    fi

    if [[ "$STATUS" != "0" ]]; then
        error "SABnzbd reported failed status: $STATUS"
        exit 1
    fi

    log "Processing: $JOB_NAME"
    log "  Source: $DOWNLOAD_DIR"
    log "  Category: $CATEGORY"
}

# Find CBZ/CBR files in download directory
find_comic_files() {
    find "$DOWNLOAD_DIR" -type f \( -iname "*.cbz" -o -iname "*.cbr" -o -iname "*.pdf" \) 2>/dev/null
}

# Extract series and volume from filename
# Handles common patterns:
#   "Series Name v01 (2020).cbz"
#   "Series Name v01 (Digital).cbz"
#   "Series Name Vol. 01.cbz"
#   "Series.Name.v01.cbz"
parse_comic_filename() {
    local filename="$1"
    local basename="${filename##*/}"
    basename="${basename%.*}"  # Remove extension

    # Try to extract series name and volume number
    local series=""
    local volume=""

    # Pattern: "Series v01", "Series Vol. 01", "Series Vol 01"
    if [[ "$basename" =~ ^(.+)[[:space:]]+(v|Vol\.?)[[:space:]]*([0-9]+) ]]; then
        series="${BASH_REMATCH[1]}"
        volume="${BASH_REMATCH[3]}"
    # Pattern: "Series.v01", dots as separators
    elif [[ "$basename" =~ ^(.+)\.(v|Vol\.?)([0-9]+) ]]; then
        series="${BASH_REMATCH[1]}"
        series="${series//./ }"  # Convert dots to spaces
        volume="${BASH_REMATCH[3]}"
    else
        # Fallback: use full basename as series name
        series="$basename"
        volume=""
    fi

    # Clean up series name
    series=$(echo "$series" | sed 's/\s\+/ /g' | sed 's/^ \+//;s/ \+$//')

    echo "$series|$volume"
}

# Sanitize folder/file name for filesystem
sanitize_name() {
    local name="$1"
    # Remove problematic characters, preserve spaces and basic punctuation
    echo "$name" | sed 's/[<>:"/\\|?*]//g' | sed 's/\s\+/ /g' | sed 's/^ \+//;s/ \+$//'
}

# Determine target folder based on Mylar naming or series detection
get_target_folder() {
    local file="$1"
    local parsed=$(parse_comic_filename "$file")
    local series="${parsed%%|*}"

    series=$(sanitize_name "$series")

    # Check if folder already exists (Mylar may have created it)
    # Look for existing folders that match (case-insensitive partial match)
    local existing_folder=""
    if [[ -d "$COMICS_ROOT" ]]; then
        existing_folder=$(find "$COMICS_ROOT" -maxdepth 1 -type d -iname "*${series}*" | head -1)
    fi

    if [[ -n "$existing_folder" ]]; then
        echo "$existing_folder"
    else
        # Create new folder
        echo "${COMICS_ROOT}/${series}"
    fi
}

# Move comic file to target location
move_comic() {
    local source="$1"
    local target_dir="$2"
    local filename="${source##*/}"
    local target="${target_dir}/${filename}"

    # Create target directory if needed
    mkdir -p "$target_dir"

    # Check for existing file
    if [[ -f "$target" ]]; then
        warn "File already exists, skipping: $target"
        return 0
    fi

    # Move file
    mv "$source" "$target"
    log "  Moved: ${filename} -> ${target_dir##*/}/"
}

# Trigger Komga library scan
trigger_komga_scan() {
    if [[ -z "$KOMGA_USER" || -z "$KOMGA_PASS" ]]; then
        warn "KOMGA_USERNAME/KOMGA_PASSWORD not set - skipping rescan"
        return 0
    fi

    log "Triggering Komga library scan..."

    # Get library IDs and scan each
    local libraries=$(curl -s -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries" 2>/dev/null)

    if [[ -z "$libraries" ]]; then
        warn "Could not connect to Komga at $KOMGA_URL"
        return 1
    fi

    # Find the Comics library specifically, or scan all if not found
    local comics_lib_id=$(echo "$libraries" | jq -r '.[] | select(.name | test("comic|manga"; "i")) | .id' | head -1)

    if [[ -n "$comics_lib_id" ]]; then
        curl -s -X POST -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries/$comics_lib_id/scan" >/dev/null
        log "  Triggered scan for Comics library: $comics_lib_id"
    else
        # Scan all libraries as fallback
        echo "$libraries" | jq -r '.[] | .id' | while read lib_id; do
            curl -s -X POST -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries/$lib_id/scan" >/dev/null
            log "  Triggered scan for library: $lib_id"
        done
    fi
}

# Cleanup empty directories after move
cleanup_download() {
    local dir="$1"

    # Remove empty subdirectories
    find "$dir" -type d -empty -delete 2>/dev/null || true

    # Remove the download dir if empty
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; then
        rmdir "$dir" 2>/dev/null || true
        log "  Cleaned up empty download directory"
    fi
}

# Main processing
main() {
    log "=== Mylar Post-Processor ==="

    validate_inputs

    # Find all comic files
    local comic_files
    comic_files=$(find_comic_files)

    if [[ -z "$comic_files" ]]; then
        warn "No comic files found in: $DOWNLOAD_DIR"
        exit 0
    fi

    # Process each file
    local processed=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local target_dir=$(get_target_folder "$file")

        debug "File: $file"
        debug "Target: $target_dir"

        move_comic "$file" "$target_dir"
        ((processed++)) || true
    done <<< "$comic_files"

    log "Processed $processed comic file(s)"

    # Cleanup
    cleanup_download "$DOWNLOAD_DIR"

    # Trigger Komga scan
    trigger_komga_scan

    log "=== Complete ==="
    exit 0
}

main "$@"
