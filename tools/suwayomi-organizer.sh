#!/usr/bin/env bash
# suwayomi-organizer.sh
# Organizes Suwayomi chapter downloads into Comics collection for Komga
#
# Suwayomi downloads chapters as: Source/SeriesName/ChapterX/images/
# This script:
#   1. Scans for completed chapter downloads
#   2. Creates CBZ archives from image folders
#   3. Moves to Comics root with proper naming
#   4. Triggers Komga library rescan
#
# USAGE:
#   ./tools/suwayomi-organizer.sh [--watch] [--dry-run]
#
# OPTIONS:
#   --watch     Continuously monitor for new downloads (daemon mode)
#   --dry-run   Show what would be done without making changes

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SUWAYOMI_DOWNLOADS="${SUWAYOMI_DOWNLOADS:-/var/mnt/fast8tb/Local/downloads/suwayomi-chapters}"
COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
# Weekly chapters go to separate subdirectory to distinguish from tankobon
SUWAYOMI_OUTPUT_DIR="${SUWAYOMI_OUTPUT_DIR:-${COMICS_ROOT}/[Weekly Chapters]}"
KOMGA_URL="${KOMGA_URL:-http://localhost:8081}"
KOMGA_USER="${KOMGA_USERNAME:-}"
KOMGA_PASS="${KOMGA_PASSWORD:-}"
PROCESSED_LOG="${SUWAYOMI_DOWNLOADS}/.processed_chapters.log"

DRY_RUN=false
WATCH_MODE=false
WATCH_INTERVAL=60  # seconds

log() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" >&2; }
debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Parse args
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true; log "DRY RUN MODE - No changes will be made" ;;
        --watch) WATCH_MODE=true; log "WATCH MODE - Monitoring for new downloads" ;;
        --help)
            echo "Usage: $0 [--watch] [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --watch     Continuously monitor for new downloads"
            echo "  --dry-run   Show what would be done without making changes"
            exit 0
            ;;
    esac
done

# Ensure directories exist
mkdir -p "$SUWAYOMI_DOWNLOADS"
touch "$PROCESSED_LOG"

# Check if chapter already processed
is_processed() {
    local chapter_path="$1"
    grep -qxF "$chapter_path" "$PROCESSED_LOG" 2>/dev/null
}

# Mark chapter as processed
mark_processed() {
    local chapter_path="$1"
    echo "$chapter_path" >> "$PROCESSED_LOG"
}

# Sanitize filename for filesystem
sanitize_name() {
    local name="$1"
    # Remove problematic characters, preserve spaces and basic punctuation
    echo "$name" | sed 's/[<>:"/\\|?*]//g' | sed 's/\s\+/ /g' | sed 's/^ \+//;s/ \+$//'
}

# Create CBZ from image folder
create_cbz() {
    local image_dir="$1"
    local output_cbz="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would create: $output_cbz"
        return 0
    fi

    # Create temp dir for proper ordering
    local temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" RETURN

    # Copy images with numbered names to ensure proper order
    local counter=1
    find "$image_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort -V | while read img; do
        local ext="${img##*.}"
        local padded=$(printf "%04d" $counter)
        cp "$img" "$temp_dir/${padded}.${ext}"
        ((counter++))
    done

    # Create CBZ (which is just a ZIP)
    local output_dir=$(dirname "$output_cbz")
    mkdir -p "$output_dir"

    (cd "$temp_dir" && zip -q "$output_cbz" *.*)

    log "  Created: $(basename "$output_cbz")"
}

# Parse Suwayomi directory structure
# Format: downloads/Source/SeriesName/ChapterN/images
process_chapter() {
    local chapter_dir="$1"

    # Skip if already processed
    if is_processed "$chapter_dir"; then
        debug "Already processed: $chapter_dir"
        return 0
    fi

    # Count images to verify download is complete
    local image_count=$(find "$chapter_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | wc -l)

    if [[ $image_count -lt 3 ]]; then
        debug "Incomplete chapter (only $image_count images): $chapter_dir"
        return 0
    fi

    # Parse path components: Source/SeriesName/ChapterX
    local rel_path="${chapter_dir#$SUWAYOMI_DOWNLOADS/}"
    local source_name=$(echo "$rel_path" | cut -d'/' -f1)
    local series_name=$(echo "$rel_path" | cut -d'/' -f2)
    local chapter_name=$(echo "$rel_path" | cut -d'/' -f3)

    if [[ -z "$series_name" || -z "$chapter_name" ]]; then
        warn "Could not parse: $chapter_dir"
        return 1
    fi

    # Clean up names
    series_name=$(sanitize_name "$series_name")
    chapter_name=$(sanitize_name "$chapter_name")

    # Extract chapter number for proper naming
    # Suwayomi uses: "Chapter X", "Chapter X.5", "Ch. X", etc.
    local chapter_num=""
    if [[ "$chapter_name" =~ [Cc]h(apter)?[[:space:]]*([0-9]+(\.[0-9]+)?) ]]; then
        chapter_num="${BASH_REMATCH[2]}"
    else
        # Fallback: use chapter_name as-is
        chapter_num="$chapter_name"
    fi

    # Pad chapter number (e.g., "5" -> "005", "125.5" -> "125.5")
    if [[ "$chapter_num" =~ ^[0-9]+$ ]]; then
        chapter_num=$(printf "%03d" "$chapter_num")
    fi

    # Output to [Weekly Chapters]/SeriesName/ with c{chapter} naming
    local output_dir="${SUWAYOMI_OUTPUT_DIR}/${series_name}"

    # Create CBZ filename: SeriesName c{chapter}.cbz (matches tankobon v{vol} pattern)
    local cbz_filename="${series_name} c${chapter_num}.cbz"
    local output_path="${output_dir}/${cbz_filename}"

    log "Processing: $series_name c${chapter_num}"
    log "  Source: $source_name ($chapter_name)"
    log "  Images: $image_count"
    log "  Output: [Weekly Chapters]/${series_name}/${cbz_filename}"

    if [[ -f "$output_path" ]]; then
        warn "  Already exists: $output_path"
        mark_processed "$chapter_dir"
        return 0
    fi

    # Create CBZ
    create_cbz "$chapter_dir" "$output_path"

    # Mark as processed
    if [[ "$DRY_RUN" == "false" ]]; then
        mark_processed "$chapter_dir"
    fi
}

# Trigger Komga library scan
trigger_komga_scan() {
    if [[ -z "$KOMGA_USER" || -z "$KOMGA_PASS" ]]; then
        warn "KOMGA_USERNAME/KOMGA_PASSWORD not set - skipping rescan"
        return 0
    fi

    log "Triggering Komga library scan..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would trigger Komga scan"
        return 0
    fi

    # Get library IDs and scan each
    local libraries=$(curl -s -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries" 2>/dev/null)

    if [[ -z "$libraries" ]]; then
        warn "Could not connect to Komga at $KOMGA_URL"
        return 1
    fi

    echo "$libraries" | jq -r '.[] | .id' | while read lib_id; do
        curl -s -X POST -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries/$lib_id/scan" >/dev/null
        log "  Triggered scan for library: $lib_id"
    done
}

# Main scanning function
scan_downloads() {
    log "Scanning: $SUWAYOMI_DOWNLOADS"

    local processed_count=0

    # Find chapter directories (3 levels deep: Source/Series/Chapter)
    find "$SUWAYOMI_DOWNLOADS" -mindepth 3 -maxdepth 3 -type d 2>/dev/null | while read chapter_dir; do
        # Skip hidden directories and thumbnails
        if [[ "$chapter_dir" == *"/."* ]] || [[ "$chapter_dir" == *"/thumbnails"* ]]; then
            continue
        fi

        if process_chapter "$chapter_dir"; then
            ((processed_count++)) || true
        fi
    done

    if [[ $processed_count -gt 0 ]]; then
        trigger_komga_scan
    else
        log "No new chapters found"
    fi
}

# Main
main() {
    log "Suwayomi Chapter Organizer"
    log "  Downloads: $SUWAYOMI_DOWNLOADS"
    log "  Output: $SUWAYOMI_OUTPUT_DIR"
    log "  Komga: $KOMGA_URL"

    if [[ "$WATCH_MODE" == "true" ]]; then
        log "Starting watch mode (interval: ${WATCH_INTERVAL}s)"
        while true; do
            scan_downloads
            sleep $WATCH_INTERVAL
        done
    else
        scan_downloads
    fi
}

main
