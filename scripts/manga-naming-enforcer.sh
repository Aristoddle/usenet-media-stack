#!/usr/bin/env bash
# manga-naming-enforcer.sh - Audit and enforce NAMING_STANDARD_V2 compliance
#
# Usage:
#   ./manga-naming-enforcer.sh              # Audit mode (default)
#   ./manga-naming-enforcer.sh --fix        # Fix mode with dry-run
#   ./manga-naming-enforcer.sh --fix --exec # Fix mode for real
#   ./manga-naming-enforcer.sh --cleanup    # Remove Mylar3 stubs
#
# Environment:
#   COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics (default)
#
set -euo pipefail

# Configuration
COMICS_ROOT="${COMICS_ROOT:-/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics}"
MODE="${1:-audit}"
EXEC="${2:-}"

# Colors (disabled if not tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Counters
declare -i total=0 compliant=0 non_compliant=0 stubs=0 fixed=0

# Patterns
STANDARD_PATTERN='.+ \([A-Za-z ]+\) \[EN\]$'
YEAR_ONLY_PATTERN='.+ \([0-9]{4}\)$'

#######################################
# Check if folder follows naming standard
# Arguments:
#   $1 - folder name
# Returns:
#   0 if compliant, 1 if not
#######################################
is_compliant() {
  local folder="$1"
  [[ "$folder" =~ $STANDARD_PATTERN ]]
}

#######################################
# Check if folder is a Mylar3 stub (year-only, no comics)
# Arguments:
#   $1 - folder path
# Returns:
#   0 if stub, 1 if not
#######################################
is_mylar_stub() {
  local path="$1"
  local folder
  folder=$(basename "$path")

  # Must match year-only pattern
  if [[ ! "$folder" =~ $YEAR_ONLY_PATTERN ]]; then
    return 1
  fi

  # Must have zero comic files
  local cbz_count
  cbz_count=$(find "$path" -type f \( -iname "*.cbz" -o -iname "*.cbr" \) 2>/dev/null | wc -l)

  [[ "$cbz_count" -eq 0 ]]
}

#######################################
# Get folder statistics
# Arguments:
#   $1 - folder path
# Outputs:
#   file_count cbz_count size_mb
#######################################
get_folder_stats() {
  local path="$1"
  local file_count cbz_count size_bytes size_mb

  file_count=$(find "$path" -type f 2>/dev/null | wc -l)
  cbz_count=$(find "$path" -type f \( -iname "*.cbz" -o -iname "*.cbr" \) 2>/dev/null | wc -l)
  size_bytes=$(du -sb "$path" 2>/dev/null | cut -f1)
  size_mb=$((size_bytes / 1024 / 1024))

  echo "$file_count $cbz_count $size_mb"
}

#######################################
# Audit mode - report compliance status
#######################################
audit_mode() {
  echo "========================================"
  echo "MANGA NAMING STANDARD AUDIT"
  echo "========================================"
  echo "Root: $COMICS_ROOT"
  echo "Standard: NAMING_STANDARD_V2 (Series (Publisher) [Language])"
  echo ""

  echo -e "${BLUE}=== COMPLIANT FOLDERS ===${NC}"

  for dir in "$COMICS_ROOT"/*/; do
    local folder
    folder=$(basename "$dir")

    # Skip hidden and special folders
    [[ "$folder" == .* ]] && continue
    [[ "$folder" == "MANGA_PROJECT_DOCS" ]] && continue
    [[ "$folder" == "Manga" ]] && continue
    [[ "$folder" == "logs" ]] && continue

    ((total++))

    if is_compliant "$folder"; then
      ((compliant++))
      read -r files cbz size <<< "$(get_folder_stats "$dir")"
      echo -e "${GREEN}[OK]${NC} $folder (${cbz} CBZ, ${size}MB)"
    fi
  done

  echo ""
  echo -e "${YELLOW}=== NON-COMPLIANT FOLDERS ===${NC}"

  for dir in "$COMICS_ROOT"/*/; do
    local folder
    folder=$(basename "$dir")

    # Skip hidden and special folders
    [[ "$folder" == .* ]] && continue
    [[ "$folder" == "MANGA_PROJECT_DOCS" ]] && continue
    [[ "$folder" == "Manga" ]] && continue
    [[ "$folder" == "logs" ]] && continue

    if ! is_compliant "$folder"; then
      ((non_compliant++))
      read -r files cbz size <<< "$(get_folder_stats "$dir")"

      if is_mylar_stub "$dir"; then
        ((stubs++))
        echo -e "${RED}[STUB]${NC} $folder (metadata only, 0 CBZ)"
      else
        echo -e "${YELLOW}[FIX]${NC} $folder (${cbz} CBZ, ${size}MB)"
      fi
    fi
  done

  echo ""
  echo "========================================"
  echo "SUMMARY"
  echo "========================================"
  echo "Total folders: $total"
  echo -e "${GREEN}Compliant: $compliant${NC} ($(( compliant * 100 / total ))%)"
  echo -e "${YELLOW}Non-compliant: $non_compliant${NC}"
  echo -e "${RED}Mylar3 stubs: $stubs${NC} (safe to remove)"
}

#######################################
# Cleanup mode - remove Mylar3 stubs
#######################################
cleanup_mode() {
  local exec_mode="${1:-dry-run}"

  echo "========================================"
  echo "MYLAR3 STUB CLEANUP"
  echo "========================================"
  echo "Root: $COMICS_ROOT"
  echo "Mode: $exec_mode"
  echo ""

  for dir in "$COMICS_ROOT"/*/; do
    local folder
    folder=$(basename "$dir")

    # Skip hidden and special folders
    [[ "$folder" == .* ]] && continue
    [[ "$folder" == "MANGA_PROJECT_DOCS" ]] && continue
    [[ "$folder" == "Manga" ]] && continue
    [[ "$folder" == "logs" ]] && continue

    if is_mylar_stub "$dir"; then
      ((stubs++))

      if [[ "$exec_mode" == "--exec" ]]; then
        rm -rf "$dir"
        echo -e "${GREEN}[REMOVED]${NC} $folder"
        ((fixed++))
      else
        echo -e "${YELLOW}[WOULD REMOVE]${NC} $folder"
      fi
    fi
  done

  echo ""
  echo "========================================"
  echo "SUMMARY"
  echo "========================================"
  echo "Stubs found: $stubs"

  if [[ "$exec_mode" == "--exec" ]]; then
    echo -e "${GREEN}Removed: $fixed${NC}"
  else
    echo "Run with --exec to remove"
  fi
}

#######################################
# Fix mode - suggest/apply renames
#######################################
fix_mode() {
  local exec_mode="${1:-dry-run}"

  echo "========================================"
  echo "NAMING STANDARD FIX MODE"
  echo "========================================"
  echo "Root: $COMICS_ROOT"
  echo "Mode: $exec_mode"
  echo ""

  # Known publisher mappings
  declare -A publisher_map=(
    ["Death Note"]="Viz"
    ["Kingdom"]="Kodansha"
    ["Parasyte"]="Kodansha"
    ["Billy Bat"]="Fan Translation"
    ["My Hero Academia"]="Viz"
  )

  for dir in "$COMICS_ROOT"/*/; do
    local folder
    folder=$(basename "$dir")

    # Skip hidden and special folders
    [[ "$folder" == .* ]] && continue
    [[ "$folder" == "MANGA_PROJECT_DOCS" ]] && continue
    [[ "$folder" == "Manga" ]] && continue
    [[ "$folder" == "logs" ]] && continue

    # Skip already compliant
    is_compliant "$folder" && continue

    # Skip Mylar3 stubs (use --cleanup instead)
    is_mylar_stub "$dir" && continue

    ((non_compliant++))

    # Extract base name (remove year pattern)
    local base_name
    base_name=$(echo "$folder" | sed -E 's/ \([0-9]{4}\)$//')

    # Look up publisher
    local publisher="${publisher_map[$base_name]:-UNKNOWN}"
    local new_name="$base_name ($publisher) [EN]"

    if [[ "$exec_mode" == "--exec" ]]; then
      local new_path="$COMICS_ROOT/$new_name"
      if [[ -d "$new_path" ]]; then
        echo -e "${RED}[CONFLICT]${NC} $folder -> $new_name (target exists)"
      else
        mv "$dir" "$new_path"
        echo -e "${GREEN}[RENAMED]${NC} $folder -> $new_name"
        ((fixed++))
      fi
    else
      echo -e "${YELLOW}[WOULD RENAME]${NC}"
      echo "  From: $folder"
      echo "  To:   $new_name"
    fi
  done

  echo ""
  echo "========================================"
  echo "SUMMARY"
  echo "========================================"
  echo "Non-compliant (with content): $non_compliant"

  if [[ "$exec_mode" == "--exec" ]]; then
    echo -e "${GREEN}Renamed: $fixed${NC}"
  else
    echo "Run with --exec to rename"
    echo ""
    echo "NOTE: Review suggested names. Some may need manual publisher research."
    echo "Edit the publisher_map in this script to add known mappings."
  fi
}

#######################################
# Main
#######################################
main() {
  if [[ ! -d "$COMICS_ROOT" ]]; then
    echo "Error: Comics root not found: $COMICS_ROOT" >&2
    exit 1
  fi

  case "$MODE" in
    audit|--audit|-a)
      audit_mode
      ;;
    --cleanup|-c)
      cleanup_mode "$EXEC"
      ;;
    --fix|-f)
      fix_mode "$EXEC"
      ;;
    --help|-h)
      echo "manga-naming-enforcer.sh - Audit and enforce NAMING_STANDARD_V2"
      echo ""
      echo "Usage:"
      echo "  manga-naming-enforcer.sh              # Audit mode (default)"
      echo "  manga-naming-enforcer.sh --fix        # Fix mode (dry-run)"
      echo "  manga-naming-enforcer.sh --fix --exec # Fix mode (execute)"
      echo "  manga-naming-enforcer.sh --cleanup    # Remove Mylar3 stubs (dry-run)"
      echo "  manga-naming-enforcer.sh --cleanup --exec # Remove stubs (execute)"
      echo ""
      echo "Environment:"
      echo "  COMICS_ROOT  Path to comics folder"
      echo "               Default: /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics"
      ;;
    *)
      echo "Unknown mode: $MODE (use --help for usage)" >&2
      exit 1
      ;;
  esac
}

main "$@"
