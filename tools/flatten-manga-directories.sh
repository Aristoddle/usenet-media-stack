#!/bin/bash
# flatten-manga-directories.sh
#
# Flattens nested manga directories to comply with Komga/Kavita requirements.
# See docs/MANGA_COLLECTION_TOPOLOGY.md for naming conventions.
#
# Problems this script fixes:
# 1. Nested subfolders (1. Volumes/, 2. Chapters/, 3. Extras/) - Komga treats these as separate series
# 2. __Panels directories - YACReader artifacts
# 3. Hidden directories - Should be removed
#
# Usage:
#   ./flatten-manga-directories.sh --dry-run    # Preview changes
#   ./flatten-manga-directories.sh --execute    # Execute changes
#
# Author: Claude Code Agent
# Date: 2025-12-29

set -euo pipefail

COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
DRY_RUN=true
LOG_FILE="/tmp/flatten-manga-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

usage() {
    echo "Usage: $0 [--dry-run|--execute]"
    echo ""
    echo "Options:"
    echo "  --dry-run   Preview changes without modifying files (default)"
    echo "  --execute   Execute the flattening operation"
    echo ""
    echo "Environment:"
    echo "  COMICS_ROOT  Path to comics directory (default: /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics)"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --execute)
            DRY_RUN=false
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

log "=== Manga Directory Flattening Tool ==="
log "Comics root: $COMICS_ROOT"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN (preview only)' || echo 'EXECUTE')"
log "Log file: $LOG_FILE"
log ""

if [[ ! -d "$COMICS_ROOT" ]]; then
    log "ERROR: Comics root directory does not exist: $COMICS_ROOT"
    exit 1
fi

cd "$COMICS_ROOT"

# Phase 1: Remove __Panels directories (YACReader artifacts)
log "Phase 1: Removing __Panels directories"
panels_count=0
while IFS= read -r -d '' panel_dir; do
    panels_count=$((panels_count + 1))
    log "  Would remove: $panel_dir"
    if [[ "$DRY_RUN" = false ]]; then
        rm -rf "$panel_dir"
        log "  Removed"
    fi
done < <(find . -type d -name "__Panels" -print0 2>/dev/null)
log "Total __Panels directories: $panels_count"
log ""

# Phase 2: Remove __Panels.pkgf files
log "Phase 2: Removing __Panels.pkgf files"
pkgf_count=0
while IFS= read -r -d '' pkgf_file; do
    pkgf_count=$((pkgf_count + 1))
    log "  Would remove: $pkgf_file"
    if [[ "$DRY_RUN" = false ]]; then
        rm -f "$pkgf_file"
        log "  Removed"
    fi
done < <(find . -type f -name "__Panels.pkgf" -print0 2>/dev/null)
log "Total __Panels.pkgf files: $pkgf_count"
log ""

# Phase 3: Flatten nested directories (1. Volumes/, 2. Chapters/, etc.)
log "Phase 3: Flattening nested series directories"
flatten_count=0
for series_dir in */; do
    [[ "$series_dir" == .* ]] && continue  # Skip hidden dirs

    # Check for nested subdirs that need flattening
    nested_dirs=()
    for subdir in "$series_dir"*/; do
        [[ "$subdir" == "$series_dir"*/ ]] || continue
        subdir_name=$(basename "$subdir")

        # Match patterns like "1. Volumes", "2. Chapters", "3. Extras", "Volumes", "Chapters"
        if [[ "$subdir_name" =~ ^[0-9]+\..* ]] || [[ "$subdir_name" == "Volumes" ]] || [[ "$subdir_name" == "Chapters" ]] || [[ "$subdir_name" == "Extras" ]]; then
            nested_dirs+=("$subdir")
        fi
    done

    if [[ ${#nested_dirs[@]} -gt 0 ]]; then
        flatten_count=$((flatten_count + 1))
        log "  Series: ${series_dir%/}"

        for nested_dir in "${nested_dirs[@]}"; do
            # Find all CBZ/CBR files in nested dir
            while IFS= read -r -d '' comic_file; do
                filename=$(basename "$comic_file")
                dest="$series_dir$filename"

                if [[ -f "$dest" ]]; then
                    log "    SKIP (exists): $filename"
                else
                    log "    Would move: $comic_file -> $dest"
                    if [[ "$DRY_RUN" = false ]]; then
                        mv "$comic_file" "$dest"
                        log "    Moved"
                    fi
                fi
            done < <(find "$nested_dir" -maxdepth 1 -type f \( -iname "*.cbz" -o -iname "*.cbr" -o -iname "*.pdf" -o -iname "*.epub" \) -print0 2>/dev/null)
        done

        # Remove empty nested directories
        for nested_dir in "${nested_dirs[@]}"; do
            if [[ "$DRY_RUN" = false ]]; then
                rmdir "$nested_dir" 2>/dev/null || true
            fi
        done
    fi
done
log "Series with nested directories: $flatten_count"
log ""

# Phase 4: Summary
log "=== Summary ==="
log "  __Panels directories: $panels_count"
log "  __Panels.pkgf files: $pkgf_count"
log "  Series needing flattening: $flatten_count"
log ""

if [[ "$DRY_RUN" = true ]]; then
    log "This was a DRY RUN. No files were modified."
    log "To execute changes, run: $0 --execute"
else
    log "Flattening complete."
    log "Please trigger a rescan in Komga/Kavita to reflect changes."
fi
