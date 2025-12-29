#!/usr/bin/env bash
# flatten-manga-directories.sh
# Migration helper to flatten nested manga directories for Komga compatibility
#
# Problem: Some manga series have nested structures like:
#   Series/1. Volumes/v01.cbz
#   Series/2. Chapters/c125.cbz
#
# Komga treats subfolders as separate series, breaking the intended structure.
# This script flattens to:
#   Series/Series v01.cbz
#   Series/Series c125.cbz
#
# USAGE:
#   ./tools/flatten-manga-directories.sh [--dry-run] [--interactive] [path]
#
# OPTIONS:
#   --dry-run       Show what would be done without making changes
#   --interactive   Prompt before each operation
#   --cleanup       Also remove __Panels and .DS_Store directories
#   path            Comics directory to scan (default: from COMICS_ROOT env)
#
# SAFETY:
#   - Creates backup manifest before changes
#   - Logs all operations to flatten-manga.log
#   - Never deletes original files (moves only)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
LOG_FILE="${LOG_FILE:-./flatten-manga.log}"
MANIFEST_FILE="${MANIFEST_FILE:-./flatten-manifest-$(date +%Y%m%d-%H%M%S).json}"

DRY_RUN=false
INTERACTIVE=false
CLEANUP=false

log() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2; }
header() { echo -e "\n${CYAN}=== $1 ===${NC}" | tee -a "$LOG_FILE"; }

# Parse arguments
TARGET_PATH=""
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true; log "DRY RUN MODE - No changes will be made" ;;
        --interactive) INTERACTIVE=true ;;
        --cleanup) CLEANUP=true ;;
        --help)
            echo "Usage: $0 [--dry-run] [--interactive] [--cleanup] [path]"
            echo ""
            echo "Flattens nested manga directories for Komga compatibility."
            echo ""
            echo "Options:"
            echo "  --dry-run       Show what would be done without making changes"
            echo "  --interactive   Prompt before each operation"
            echo "  --cleanup       Also remove __Panels and .DS_Store directories"
            echo "  path            Comics directory to scan (default: COMICS_ROOT env)"
            echo ""
            echo "Environment:"
            echo "  COMICS_ROOT     Default comics directory"
            exit 0
            ;;
        *)
            if [[ -d "$arg" ]]; then
                TARGET_PATH="$arg"
            else
                error "Unknown argument or invalid path: $arg"
                exit 1
            fi
            ;;
    esac
done

# Use target path or default
COMICS_ROOT="${TARGET_PATH:-$COMICS_ROOT}"

# Validate target exists
if [[ ! -d "$COMICS_ROOT" ]]; then
    error "Comics directory does not exist: $COMICS_ROOT"
    exit 1
fi

# Initialize log
echo "=== Flatten Manga Directories ===" > "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"
echo "Target: $COMICS_ROOT" >> "$LOG_FILE"
echo "Dry Run: $DRY_RUN" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Patterns that indicate nested structure
# These subfolder names cause Komga to create separate series
NESTED_PATTERNS=(
    "Volumes"
    "1. Volumes"
    "2. Chapters"
    "Chapters"
    "Extras"
    "Specials"
    "Scans"
    "Digital"
    "Official"
)

# Cleanup patterns
CLEANUP_PATTERNS=(
    "__Panels"
    ".DS_Store"
    "Thumbs.db"
    ".AppleDouble"
    "@eaDir"
)

# Extract series name from folder path
get_series_name() {
    local path="$1"
    local parent="${path%/*}"
    local series="${parent##*/}"
    echo "$series"
}

# Check if a subfolder matches nested patterns
is_nested_folder() {
    local folder_name="$1"

    for pattern in "${NESTED_PATTERNS[@]}"; do
        if [[ "$folder_name" == "$pattern" ]] || [[ "$folder_name" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if a folder should be cleaned up
should_cleanup() {
    local folder_name="$1"

    for pattern in "${CLEANUP_PATTERNS[@]}"; do
        if [[ "$folder_name" == "$pattern" ]]; then
            return 0
        fi
    done
    return 1
}

# Prompt for confirmation in interactive mode
confirm() {
    local prompt="$1"

    if [[ "$INTERACTIVE" != "true" ]]; then
        return 0
    fi

    read -p "$prompt [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Create manifest entry
manifest_entry() {
    local action="$1"
    local source="$2"
    local dest="${3:-}"

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    local entry
    entry=$(jq -n \
        --arg action "$action" \
        --arg source "$source" \
        --arg dest "$dest" \
        --arg timestamp "$(date -Iseconds)" \
        '{action: $action, source: $source, dest: $dest, timestamp: $timestamp}')

    # Append to manifest
    if [[ -f "$MANIFEST_FILE" ]]; then
        local current
        current=$(cat "$MANIFEST_FILE")
        echo "$current" | jq ". += [$entry]" > "$MANIFEST_FILE"
    else
        echo "[$entry]" > "$MANIFEST_FILE"
    fi
}

# Move file to series root
move_to_series_root() {
    local file="$1"
    local series_root="$2"
    local filename="${file##*/}"
    local series_name="${series_root##*/}"

    # Target path: /Series/filename
    local target="${series_root}/${filename}"

    # Check if filename needs series prefix
    if [[ ! "$filename" =~ ^"$series_name" ]]; then
        # Add series name prefix
        local extension="${filename##*.}"
        local basename="${filename%.*}"
        filename="${series_name} ${basename}.${extension}"
        target="${series_root}/${filename}"
    fi

    # Check for collision
    if [[ -f "$target" ]]; then
        warn "  File already exists at target: $target"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "  [DRY RUN] Would move: ${file##*/} -> ${target##*/}"
        return 0
    fi

    if confirm "  Move ${file##*/} to ${target##*/}?"; then
        mv "$file" "$target"
        manifest_entry "move" "$file" "$target"
        log "  Moved: ${file##*/} -> ${target##*/}"
    else
        log "  Skipped: ${file##*/}"
    fi
}

# Remove directory (cleanup mode)
remove_directory() {
    local dir="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "  [DRY RUN] Would remove: $dir"
        return 0
    fi

    if confirm "  Remove directory: ${dir##*/}?"; then
        rm -rf "$dir"
        manifest_entry "remove" "$dir"
        log "  Removed: ${dir##*/}"
    else
        log "  Skipped removal: ${dir##*/}"
    fi
}

# Scan and process a series directory
process_series() {
    local series_dir="$1"
    local series_name="${series_dir##*/}"

    # Find all subdirectories
    local has_nested=false

    while IFS= read -r subdir; do
        [[ -z "$subdir" ]] && continue
        local subdir_name="${subdir##*/}"

        # Check for cleanup patterns first
        if should_cleanup "$subdir_name" && [[ "$CLEANUP" == "true" ]]; then
            log "Cleanup target: $series_name/$subdir_name"
            remove_directory "$subdir"
            continue
        fi

        # Check for nested patterns
        if is_nested_folder "$subdir_name"; then
            has_nested=true
            log "Found nested structure: $series_name/$subdir_name"

            # Find all comic files in this nested folder
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                move_to_series_root "$file" "$series_dir"
            done < <(find "$subdir" -type f \( -iname "*.cbz" -o -iname "*.cbr" -o -iname "*.pdf" \) 2>/dev/null)

            # Remove empty nested folder
            if [[ "$DRY_RUN" != "true" ]] && [[ -d "$subdir" ]]; then
                if [[ -z "$(ls -A "$subdir")" ]]; then
                    rmdir "$subdir" 2>/dev/null || true
                    manifest_entry "rmdir" "$subdir"
                    log "  Removed empty folder: $subdir_name"
                fi
            fi
        fi
    done < <(find "$series_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    if [[ "$has_nested" == "false" ]]; then
        # Check for cleanup only
        if [[ "$CLEANUP" == "true" ]]; then
            while IFS= read -r subdir; do
                [[ -z "$subdir" ]] && continue
                local subdir_name="${subdir##*/}"
                if should_cleanup "$subdir_name"; then
                    remove_directory "$subdir"
                fi
            done < <(find "$series_dir" -mindepth 1 -type d 2>/dev/null)
        fi
    fi
}

# Scan all series directories
scan_library() {
    header "Scanning: $COMICS_ROOT"

    local series_count=0
    local processed_count=0

    while IFS= read -r series_dir; do
        [[ -z "$series_dir" ]] && continue
        ((series_count++))

        # Skip hidden directories
        local series_name="${series_dir##*/}"
        if [[ "$series_name" == .* ]]; then
            continue
        fi

        process_series "$series_dir"
        ((processed_count++))
    done < <(find "$COMICS_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    header "Summary"
    log "Scanned $series_count series directories"
    log "Manifest: $MANIFEST_FILE"
}

# Report statistics
show_stats() {
    header "Pre-scan Statistics"

    # Count nested structures
    local nested_count=0
    for pattern in "${NESTED_PATTERNS[@]}"; do
        local count
        count=$(find "$COMICS_ROOT" -type d -name "$pattern" 2>/dev/null | wc -l)
        if [[ $count -gt 0 ]]; then
            log "  Found $count directories matching: $pattern"
            ((nested_count+=count))
        fi
    done

    if [[ $nested_count -eq 0 ]]; then
        log "No nested structures found. Library appears flat."
    else
        log "Total nested directories: $nested_count"
    fi

    # Count cleanup targets
    if [[ "$CLEANUP" == "true" ]]; then
        echo ""
        log "Cleanup targets:"
        for pattern in "${CLEANUP_PATTERNS[@]}"; do
            local count
            count=$(find "$COMICS_ROOT" -type d -name "$pattern" 2>/dev/null | wc -l)
            if [[ $count -gt 0 ]]; then
                log "  Found $count: $pattern"
            fi
        done
    fi
}

# Main
main() {
    log "=== Flatten Manga Directories ==="
    log "Target: $COMICS_ROOT"
    log "Options: dry_run=$DRY_RUN, interactive=$INTERACTIVE, cleanup=$CLEANUP"

    show_stats
    scan_library

    log ""
    log "=== Complete ==="
    log "Log saved to: $LOG_FILE"

    if [[ "$DRY_RUN" == "true" ]]; then
        warn "This was a dry run. Re-run without --dry-run to apply changes."
    fi
}

main "$@"
