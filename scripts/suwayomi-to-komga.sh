#!/usr/bin/env bash
# suwayomi-to-komga.sh - Pipeline to process Suwayomi downloads into Komga library
#
# This script:
# 1. Monitors Suwayomi download directory for new manga
# 2. Renames/reorganizes according to NAMING_STANDARD_V2
# 3. Moves to Komga library with proper structure
# 4. Optionally triggers Komga library scan
#
# Usage:
#   ./suwayomi-to-komga.sh              # Process once
#   ./suwayomi-to-komga.sh --watch      # Monitor continuously
#   ./suwayomi-to-komga.sh --dry-run    # Show what would happen
#
# Environment:
#   SUWAYOMI_DOWNLOADS=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/Manga
#   COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
#   KOMGA_URL=http://localhost:8081
#   KOMGA_USER=user@example.com
#   KOMGA_PASS=password
#
set -euo pipefail

# Configuration
SUWAYOMI_DOWNLOADS="${SUWAYOMI_DOWNLOADS:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/Manga}"
COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
KOMGA_URL="${KOMGA_URL:-http://localhost:8081}"
KOMGA_USER="${KOMGA_USER:-}"
KOMGA_PASS="${KOMGA_PASS:-}"
DRY_RUN="${DRY_RUN:-0}"
WATCH_INTERVAL="${WATCH_INTERVAL:-60}"  # seconds

# Colors (disabled if not tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Known publisher mappings (expand as needed)
declare -A PUBLISHER_MAP=(
  # Viz
  ["Chainsaw Man"]="Viz"
  ["One Piece"]="Viz"
  ["Jujutsu Kaisen"]="Viz"
  ["Naruto"]="Viz"
  ["Bleach"]="Viz"
  ["Dragon Ball"]="Viz"
  ["My Hero Academia"]="Viz"
  ["Dandadan"]="Viz"
  ["Spy x Family"]="Viz"
  ["Kagurabachi"]="Viz"
  ["Sakamoto Days"]="Viz"
  ["Blue Box"]="Viz"
  ["One-Punch Man"]="Viz"
  # Kodansha
  ["Blue Lock"]="Kodansha"
  ["Attack on Titan"]="Kodansha"
  ["Blue Period"]="Kodansha"
  ["Vinland Saga"]="Kodansha Comics"
  # Seven Seas
  ["Made in Abyss"]="Seven Seas"
  ["Dungeon Meshi"]="Yen Press"
  ["Mushoku Tensei"]="Seven Seas"
  # Dark Horse
  ["Berserk"]="Dark Horse"
  ["Gantz"]="Dark Horse"
  # Yen Press
  ["Soul Eater"]="Yen Press"
  ["Overlord"]="Yen Press"
)

#######################################
# Log message with timestamp
#######################################
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

#######################################
# Normalize series name from Suwayomi format
# Arguments:
#   $1 - raw folder/file name
# Outputs:
#   normalized series name
#######################################
normalize_series_name() {
  local raw="$1"
  local name

  # Remove source suffix like "(MangaDex)", "(MangaPlus)", etc.
  name=$(echo "$raw" | sed -E 's/\s*\([^)]*[Dd]ex[^)]*\)$//')
  name=$(echo "$name" | sed -E 's/\s*\([^)]*[Pp]lus[^)]*\)$//')

  # Remove "Chapter XXX" suffix
  name=$(echo "$name" | sed -E 's/\s*-?\s*[Cc]hapter\s*[0-9]+.*//')

  # Remove trailing "(YYYY)" year
  name=$(echo "$name" | sed -E 's/\s*\([0-9]{4}\)$//')

  # Trim whitespace
  name=$(echo "$name" | sed -E 's/^\s+//;s/\s+$//')

  echo "$name"
}

#######################################
# Look up publisher for series
# Arguments:
#   $1 - series name
# Outputs:
#   publisher name or "Unknown"
#######################################
lookup_publisher() {
  local series="$1"

  # Check exact match
  if [[ -v "PUBLISHER_MAP[$series]" ]]; then
    echo "${PUBLISHER_MAP[$series]}"
    return
  fi

  # Check fuzzy match (first word)
  local first_word
  first_word=$(echo "$series" | awk '{print $1}')
  for key in "${!PUBLISHER_MAP[@]}"; do
    if [[ "$key" == "$first_word"* ]]; then
      echo "${PUBLISHER_MAP[$key]}"
      return
    fi
  done

  echo "Unknown"
}

#######################################
# Generate target folder name per NAMING_STANDARD_V2
# Arguments:
#   $1 - series name
# Outputs:
#   target folder name
#######################################
generate_target_name() {
  local series="$1"
  local publisher
  publisher=$(lookup_publisher "$series")

  echo "$series ($publisher) [EN]"
}

#######################################
# Check if target folder already exists
# Arguments:
#   $1 - series name
# Returns:
#   0 if exists, 1 if not
# Outputs:
#   existing folder path
#######################################
find_existing_folder() {
  local series="$1"

  # Look for exact match or pattern match
  for dir in "$COMICS_ROOT"/*/; do
    local folder
    folder=$(basename "$dir")

    # Skip special folders
    [[ "$folder" == .* ]] && continue
    [[ "$folder" == "MANGA_PROJECT_DOCS" ]] && continue
    [[ "$folder" == "Manga" ]] && continue

    # Check if folder contains series name
    if [[ "$folder" == *"$series"* ]]; then
      echo "$dir"
      return 0
    fi
  done

  return 1
}

#######################################
# Process a single downloaded series folder
# Arguments:
#   $1 - source path (Suwayomi download)
#######################################
process_series() {
  local src_path="$1"
  local folder_name
  folder_name=$(basename "$src_path")

  log "${BLUE}Processing:${NC} $folder_name"

  # Normalize name
  local series_name
  series_name=$(normalize_series_name "$folder_name")
  log "  Normalized: $series_name"

  # Find or create target folder
  local target_folder existing_folder
  if existing_folder=$(find_existing_folder "$series_name"); then
    target_folder="$existing_folder"
    log "  Found existing: $target_folder"
  else
    target_folder="$COMICS_ROOT/$(generate_target_name "$series_name")"
    log "  Creating new: $target_folder"
  fi

  # Determine chapter structure
  local has_chapters has_volumes
  has_chapters=$(find "$src_path" -maxdepth 1 -type d -name "[Cc]hapter*" 2>/dev/null | wc -l)
  has_volumes=$(find "$src_path" -maxdepth 1 -type f \( -iname "*.cbz" -o -iname "*.cbr" \) 2>/dev/null | wc -l)

  # Process files
  if [[ "$DRY_RUN" == "1" ]]; then
    log "${YELLOW}  [DRY-RUN] Would move to: $target_folder${NC}"
    if [[ $has_chapters -gt 0 ]]; then
      log "  [DRY-RUN] Chapter folders: $has_chapters"
    fi
    if [[ $has_volumes -gt 0 ]]; then
      log "  [DRY-RUN] Volume files: $has_volumes"
    fi
  else
    # Create target structure
    mkdir -p "$target_folder"

    # Determine subfolder (Chapters for Suwayomi downloads)
    local chapter_dir="$target_folder/2. Chapters"
    if [[ ! -d "$target_folder/1. Volumes" ]]; then
      chapter_dir="$target_folder/Chapters"
    fi
    mkdir -p "$chapter_dir"

    # Move chapter folders
    if [[ $has_chapters -gt 0 ]]; then
      find "$src_path" -maxdepth 1 -type d -name "[Cc]hapter*" -exec mv {} "$chapter_dir/" \;
      log "${GREEN}  Moved chapter folders to: $chapter_dir${NC}"
    fi

    # Move CBZ files directly
    if [[ $has_volumes -gt 0 ]]; then
      find "$src_path" -maxdepth 1 -type f \( -iname "*.cbz" -o -iname "*.cbr" \) -exec mv {} "$chapter_dir/" \;
      log "${GREEN}  Moved volume files to: $chapter_dir${NC}"
    fi

    # Clean up empty source folder
    if [[ -z "$(ls -A "$src_path")" ]]; then
      rmdir "$src_path"
      log "  Removed empty source folder"
    fi
  fi
}

#######################################
# Trigger Komga library scan
#######################################
trigger_komga_scan() {
  if [[ -z "$KOMGA_USER" || -z "$KOMGA_PASS" ]]; then
    log "${YELLOW}Skipping Komga scan (credentials not set)${NC}"
    return
  fi

  log "Triggering Komga library scan..."

  # Get library ID
  local lib_response
  lib_response=$(curl -sf -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries" 2>/dev/null || echo "")

  if [[ -z "$lib_response" ]]; then
    log "${YELLOW}Could not connect to Komga${NC}"
    return
  fi

  local lib_id
  lib_id=$(echo "$lib_response" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null || echo "")

  if [[ -z "$lib_id" ]]; then
    log "${YELLOW}Could not determine library ID${NC}"
    return
  fi

  # Trigger scan
  curl -sf -u "$KOMGA_USER:$KOMGA_PASS" -X POST "$KOMGA_URL/api/v1/libraries/$lib_id/scan" >/dev/null 2>&1

  log "${GREEN}Komga scan triggered for library: $lib_id${NC}"
}

#######################################
# Process all pending downloads
#######################################
process_all() {
  log "========================================"
  log "SUWAYOMI TO KOMGA PIPELINE"
  log "========================================"
  log "Source: $SUWAYOMI_DOWNLOADS"
  log "Target: $COMICS_ROOT"
  log "Dry-run: $DRY_RUN"
  log ""

  if [[ ! -d "$SUWAYOMI_DOWNLOADS" ]]; then
    log "${YELLOW}Suwayomi downloads folder not found${NC}"
    return 1
  fi

  local processed=0

  for dir in "$SUWAYOMI_DOWNLOADS"/*/; do
    [[ ! -d "$dir" ]] && continue

    local folder_name
    folder_name=$(basename "$dir")

    # Skip hidden folders
    [[ "$folder_name" == .* ]] && continue

    process_series "$dir"
    ((processed++))
  done

  log ""
  log "========================================"
  log "SUMMARY"
  log "========================================"
  log "Processed: $processed series"

  if [[ "$DRY_RUN" == "0" && $processed -gt 0 ]]; then
    trigger_komga_scan
  fi
}

#######################################
# Watch mode - continuous monitoring
#######################################
watch_mode() {
  log "Starting watch mode (interval: ${WATCH_INTERVAL}s)"
  log "Press Ctrl+C to stop"
  log ""

  while true; do
    # Check for new content
    local count
    count=$(find "$SUWAYOMI_DOWNLOADS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

    if [[ $count -gt 0 ]]; then
      log "Found $count items to process"
      process_all
    fi

    sleep "$WATCH_INTERVAL"
  done
}

#######################################
# Main
#######################################
main() {
  case "${1:-}" in
    --watch|-w)
      watch_mode
      ;;
    --dry-run|-n)
      DRY_RUN=1
      process_all
      ;;
    --help|-h)
      echo "suwayomi-to-komga.sh - Process Suwayomi downloads into Komga library"
      echo ""
      echo "Usage:"
      echo "  suwayomi-to-komga.sh              # Process once"
      echo "  suwayomi-to-komga.sh --watch      # Monitor continuously"
      echo "  suwayomi-to-komga.sh --dry-run    # Show what would happen"
      echo ""
      echo "Environment:"
      echo "  SUWAYOMI_DOWNLOADS  Path to Suwayomi downloads"
      echo "  COMICS_ROOT         Path to Komga library"
      echo "  KOMGA_URL           Komga server URL"
      echo "  KOMGA_USER          Komga username"
      echo "  KOMGA_PASS          Komga password"
      echo "  WATCH_INTERVAL      Seconds between checks (watch mode)"
      echo ""
      echo "Publisher Mappings:"
      echo "  Edit the PUBLISHER_MAP in this script to add known series->publisher"
      ;;
    *)
      process_all
      ;;
  esac
}

main "$@"
