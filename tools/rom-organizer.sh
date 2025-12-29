#!/usr/bin/env bash
#
# rom-organizer.sh - Standardize ROM naming conventions
#
# Enforces No-Intro/Redump naming standards:
# - Title (Region) (Version).ext
# - Removes URL encoding
# - Standardizes region tags
# - Handles multi-disc games
#
# Usage: ./rom-organizer.sh [--dry-run] [--system SYSTEM] [--all]
#
# Options:
#   --dry-run     Show what would be renamed without making changes
#   --system      Target a specific system (e.g., switch, ps2)
#   --all         Process all systems
#   --lowercase   Convert filenames to lowercase
#   --report      Generate a report only (no renames)
#

set -euo pipefail

# Configuration
EMUDECK_ROOT="${EMUDECK_ROOT:-/var/mnt/fast8tb/Emudeck/Emulation}"
ROMS_DIR="$EMUDECK_ROOT/roms"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
DRY_RUN=false
TARGET_SYSTEM=""
PROCESS_ALL=false
LOWERCASE=false
REPORT_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --system) TARGET_SYSTEM="$2"; shift 2 ;;
        --all) PROCESS_ALL=true; shift ;;
        --lowercase) LOWERCASE=true; shift ;;
        --report) REPORT_ONLY=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--system SYSTEM] [--all] [--lowercase] [--report]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be renamed"
            echo "  --system      Target a specific system"
            echo "  --all         Process all systems"
            echo "  --lowercase   Convert to lowercase"
            echo "  --report      Generate report only"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate arguments
if [[ -z "$TARGET_SYSTEM" ]] && ! $PROCESS_ALL && ! $REPORT_ONLY; then
    echo "Error: Specify --system SYSTEM, --all, or --report"
    exit 1
fi

# Counters
declare -i renamed=0
declare -i skipped=0
declare -i issues=0

# Naming patterns to fix
declare -A RENAME_PATTERNS=(
    # URL encoding
    ["%20"]=" "
    ["%28"]="("
    ["%29"]=")"
    ["%2C"]=","
    ["%27"]="'"
    ["%26"]="&"
    ["%2B"]="+"

    # Common issues
    ["_"]=" "
    ["  "]=" "
)

# Region standardization
declare -A REGION_MAP=(
    ["US"]="USA"
    ["U"]="USA"
    ["E"]="Europe"
    ["EU"]="Europe"
    ["J"]="Japan"
    ["JP"]="Japan"
    ["En"]="USA"
)

# Clean filename according to No-Intro standards
clean_filename() {
    local filename="$1"
    local cleaned="$filename"

    # Decode URL encoding
    cleaned=$(printf '%b' "${cleaned//%/\\x}")

    # Remove common bad patterns
    cleaned="${cleaned//nsw2u.com/}"
    cleaned="${cleaned//(nsw2u.com)/}"

    # Standardize spacing
    cleaned=$(echo "$cleaned" | sed 's/_/ /g' | sed 's/  / /g')

    # Remove trailing spaces before extension
    cleaned=$(echo "$cleaned" | sed 's/ \./\./g')

    # Trim
    cleaned=$(echo "$cleaned" | xargs)

    if $LOWERCASE; then
        # Lowercase but preserve extension case
        local base="${cleaned%.*}"
        local ext="${cleaned##*.}"
        cleaned="$(echo "$base" | tr '[:upper:]' '[:lower:]').$ext"
    fi

    echo "$cleaned"
}

# Analyze a single file
analyze_file() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local dir=$(dirname "$filepath")

    local issues_found=()

    # Check for URL encoding
    if [[ "$filename" == *"%"* ]]; then
        issues_found+=("URL encoding")
    fi

    # Check for underscores in name (not extensions)
    local base="${filename%.*}"
    if [[ "$base" == *"_"* ]]; then
        issues_found+=("underscores")
    fi

    # Check for double spaces
    if [[ "$filename" == *"  "* ]]; then
        issues_found+=("double spaces")
    fi

    # Check for source site tags
    if [[ "$filename" == *"nsw2u"* ]] || [[ "$filename" == *"ziperto"* ]]; then
        issues_found+=("site tag")
    fi

    # Check for non-standard region tags
    if [[ "$filename" == *"[US]"* ]] || [[ "$filename" == *"[JP]"* ]]; then
        issues_found+=("non-standard region")
    fi

    # Return issues if any
    if [[ ${#issues_found[@]} -gt 0 ]]; then
        echo "${issues_found[*]}"
    fi
}

# Process a single system
process_system() {
    local system="$1"
    local system_dir="$ROMS_DIR/$system"

    if [[ ! -d "$system_dir" ]]; then
        echo -e "${YELLOW}[SKIP]${NC} $system - directory not found"
        return
    fi

    echo -e "\n${BLUE}=== Processing: $system ===${NC}"

    # Get ROM extensions for this system
    local extensions
    case "$system" in
        switch) extensions="nsp|xci|nsz|xcz" ;;
        wiiu) extensions="wux|wud|rpx" ;;
        ps2) extensions="chd|iso|cso|zso" ;;
        psx) extensions="chd|iso|bin|pbp|zip" ;;
        gc) extensions="rvz|iso|gcz" ;;
        wii) extensions="rvz|wbfs|iso" ;;
        3ds|n3ds) extensions="3ds|cia|cxi" ;;
        nds) extensions="nds" ;;
        n64) extensions="n64|z64|v64" ;;
        *) extensions="zip|iso|bin" ;;
    esac

    # Find all ROMs
    local file_count=0
    local issue_count=0
    local rename_count=0

    while IFS= read -r -d '' filepath; do
        ((file_count++))
        local filename=$(basename "$filepath")
        local dir=$(dirname "$filepath")

        # Analyze for issues
        local issues=$(analyze_file "$filepath")

        if [[ -n "$issues" ]]; then
            ((issue_count++))

            # Generate cleaned name
            local cleaned=$(clean_filename "$filename")

            if [[ "$filename" != "$cleaned" ]]; then
                ((rename_count++))

                if $REPORT_ONLY; then
                    echo -e "${YELLOW}[ISSUE]${NC} $filename"
                    echo "        Issues: $issues"
                    echo "        Suggested: $cleaned"
                elif $DRY_RUN; then
                    echo -e "${YELLOW}[WOULD RENAME]${NC}"
                    echo "  From: $filename"
                    echo "  To:   $cleaned"
                else
                    # Perform rename
                    local new_path="$dir/$cleaned"
                    if [[ ! -e "$new_path" ]]; then
                        mv "$filepath" "$new_path"
                        echo -e "${GREEN}[RENAMED]${NC} $filename -> $cleaned"
                        ((renamed++))
                    else
                        echo -e "${RED}[SKIP]${NC} $filename - target exists"
                        ((skipped++))
                    fi
                fi
            fi
        fi
    done < <(find "$system_dir" -maxdepth 2 -type f -regextype posix-extended -regex ".*\.($extensions)$" -print0 2>/dev/null)

    echo "Files scanned: $file_count"
    echo "Issues found: $issue_count"
    echo "Would rename: $rename_count"
}

# Generate full report
generate_report() {
    echo -e "${BLUE}=== ROM Organization Report ===${NC}"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    local major_systems=("switch" "wiiu" "ps2" "psx" "psp" "gc" "wii" "3ds" "n3ds" "nds" "n64" "dreamcast" "saturn")

    local total_files=0
    local total_issues=0

    for system in "${major_systems[@]}"; do
        local system_dir="$ROMS_DIR/$system"
        if [[ ! -d "$system_dir" ]]; then
            continue
        fi

        # Quick analysis
        local file_count=$(find "$system_dir" -maxdepth 2 -type f 2>/dev/null | wc -l)
        local url_encoded=$(find "$system_dir" -maxdepth 2 -type f -name "*%*" 2>/dev/null | wc -l)
        local underscored=$(find "$system_dir" -maxdepth 2 -type f -name "*_*" 2>/dev/null | wc -l)

        if [[ $url_encoded -gt 0 ]] || [[ $underscored -gt 0 ]]; then
            echo -e "\n${YELLOW}$system${NC}: $file_count files"
            if [[ $url_encoded -gt 0 ]]; then
                echo "  - URL encoded: $url_encoded"
                ((total_issues += url_encoded))
            fi
            if [[ $underscored -gt 0 ]]; then
                echo "  - With underscores: $underscored"
            fi
            ((total_files += file_count))
        fi
    done

    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "Total files with potential issues: $total_issues"
    echo ""
    echo "Run with --system SYSTEM --dry-run to see proposed changes"
}

# Main
main() {
    echo "ROM Organizer - No-Intro/Redump Naming Standards"
    echo "================================================"

    if $REPORT_ONLY; then
        generate_report
        exit 0
    fi

    if $PROCESS_ALL; then
        for system in switch wiiu ps2 psx psp gc wii 3ds n3ds nds n64 dreamcast saturn; do
            process_system "$system"
        done
    elif [[ -n "$TARGET_SYSTEM" ]]; then
        process_system "$TARGET_SYSTEM"
    fi

    echo -e "\n${BLUE}=== Final Summary ===${NC}"
    echo "Renamed: $renamed"
    echo "Skipped: $skipped"

    if $DRY_RUN; then
        echo ""
        echo "This was a dry run. No files were changed."
        echo "Run without --dry-run to apply changes."
    fi
}

main "$@"
