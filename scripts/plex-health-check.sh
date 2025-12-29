#!/bin/bash
#
# Plex Library Health Check Script
# Identifies duplicates, naming issues, empty folders, and other problems
#
# Usage: ./plex-health-check.sh [--json] [--quick]
#
# Options:
#   --json   Output in JSON format for automation
#   --quick  Skip slow operations (file counting in large directories)
#

set -uo pipefail
# Note: removed -e to allow commands that find nothing to not fail the script

# Configuration
POOL_ROOT="${POOL_ROOT:-/var/mnt/pool}"
MOVIES_PATH="$POOL_ROOT/movies"
TV_PATH="$POOL_ROOT/tv"
ANIME_TV_PATH="$POOL_ROOT/anime-tv"
ANIME_MOVIES_PATH="$POOL_ROOT/anime-movies"
CHRISTMAS_MOVIES_PATH="$POOL_ROOT/christmas-movies"
CHRISTMAS_TV_PATH="$POOL_ROOT/christmas-tv"
DOWNLOADS_PATH="$POOL_ROOT/downloads"

# Output format
OUTPUT_JSON=false
QUICK_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors (only for non-JSON output)
if [[ "$OUTPUT_JSON" == "false" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Counters
declare -A STATS
STATS[movies_folders]=0
STATS[movies_empty]=0
STATS[movies_files]=0
STATS[tv_series]=0
STATS[tv_episodes]=0
STATS[anime_tv_series]=0
STATS[anime_tv_episodes]=0
STATS[anime_movies_folders]=0
STATS[anime_movies_files]=0
STATS[downloads_orphaned]=0
STATS[naming_issues]=0
STATS[potential_duplicates]=0

# Issues arrays (bash 4+)
declare -a EMPTY_FOLDERS
declare -a NAMING_ISSUES
declare -a DUPLICATES
declare -a ORPHANED_DOWNLOADS
declare -a FOREIGN_ONLY

# Helper function to count video files
count_videos() {
    local path="$1"
    find "$path" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.m4v" \) 2>/dev/null | wc -l
}

# Helper function to check if directory is empty
is_empty_dir() {
    local path="$1"
    [[ -z "$(ls -A "$path" 2>/dev/null)" ]]
}

print_header() {
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}  $1${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    fi
}

print_section() {
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        echo ""
        echo -e "${YELLOW}▶ $1${NC}"
    fi
}

print_ok() {
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        echo -e "  ${GREEN}✓${NC} $1"
    fi
}

print_warn() {
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        echo -e "  ${YELLOW}⚠${NC} $1"
    fi
}

print_error() {
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        echo -e "  ${RED}✗${NC} $1"
    fi
}

# Start health check
print_header "PLEX LIBRARY HEALTH CHECK - $(date '+%Y-%m-%d %H:%M:%S')"

# Check if pool is mounted
if [[ ! -d "$POOL_ROOT" ]]; then
    print_error "Pool not mounted at $POOL_ROOT"
    exit 1
fi

# Get pool stats
POOL_TOTAL=$(df -h "$POOL_ROOT" | awk 'NR==2 {print $2}')
POOL_USED=$(df -h "$POOL_ROOT" | awk 'NR==2 {print $3}')
POOL_AVAIL=$(df -h "$POOL_ROOT" | awk 'NR==2 {print $4}')
POOL_PERCENT=$(df -h "$POOL_ROOT" | awk 'NR==2 {print $5}')

print_section "Pool Status"
print_ok "Pool: $POOL_TOTAL total, $POOL_USED used, $POOL_AVAIL available ($POOL_PERCENT)"

# Movies Library Check
print_section "Movies Library ($MOVIES_PATH)"

if [[ -d "$MOVIES_PATH" ]]; then
    STATS[movies_folders]=$(find "$MOVIES_PATH" -maxdepth 1 -type d | wc -l)
    ((STATS[movies_folders]--)) # Subtract the directory itself

    # Find empty folders
    while IFS= read -r -d '' folder; do
        EMPTY_FOLDERS+=("$folder")
        ((STATS[movies_empty]++))
    done < <(find "$MOVIES_PATH" -maxdepth 1 -type d -empty -print0 2>/dev/null)

    if [[ "$QUICK_MODE" == "false" ]]; then
        STATS[movies_files]=$(count_videos "$MOVIES_PATH")
    fi

    print_ok "Folders: ${STATS[movies_folders]}"
    [[ "$QUICK_MODE" == "false" ]] && print_ok "Video files: ${STATS[movies_files]}"

    if [[ ${STATS[movies_empty]} -gt 0 ]]; then
        print_warn "Empty folders: ${STATS[movies_empty]} (cleanup recommended)"
    else
        print_ok "No empty folders"
    fi

    # Check for naming issues (folders without year)
    NO_YEAR_COUNT=$(find "$MOVIES_PATH" -maxdepth 1 -type d -not -name "*([0-9][0-9][0-9][0-9])*" -not -name "movies" | wc -l)
    if [[ $NO_YEAR_COUNT -gt 50 ]]; then
        print_warn "Many folders without year in name: $NO_YEAR_COUNT"
        ((STATS[naming_issues]+=$NO_YEAR_COUNT))
    fi
else
    print_error "Movies library not found"
fi

# TV Library Check
print_section "TV Library ($TV_PATH)"

if [[ -d "$TV_PATH" ]]; then
    STATS[tv_series]=$(find "$TV_PATH" -maxdepth 1 -type d | wc -l)
    ((STATS[tv_series]--))

    if [[ "$QUICK_MODE" == "false" ]]; then
        STATS[tv_episodes]=$(count_videos "$TV_PATH")
    fi

    print_ok "Series: ${STATS[tv_series]}"
    [[ "$QUICK_MODE" == "false" ]] && print_ok "Episode files: ${STATS[tv_episodes]}"

    # Check Doctor Who specifically
    WHO_1963="$TV_PATH/Doctor Who (1963)"
    WHO_2005="$TV_PATH/Doctor Who (2005)"

    if [[ -d "$WHO_1963" ]]; then
        WHO_1963_FILES=$(count_videos "$WHO_1963")
        print_ok "Doctor Who (1963): $WHO_1963_FILES files"

        # Check for German content
        GERMAN_COUNT=$(find "$WHO_1963" -name "*GERMAN*" -o -name "*German*" 2>/dev/null | wc -l)
        if [[ $GERMAN_COUNT -gt 0 ]]; then
            print_warn "German dubs in Classic Who: $GERMAN_COUNT"
            FOREIGN_ONLY+=("Doctor Who (1963): $GERMAN_COUNT German files")
        fi
    fi

    if [[ -d "$WHO_2005" ]]; then
        WHO_2005_FILES=$(count_videos "$WHO_2005")
        print_ok "Doctor Who (2005): $WHO_2005_FILES files"

        # Check for foreign content
        FOREIGN_COUNT=$(find "$WHO_2005" -name "*GERMAN*" -o -name "*German*" -o -name "*ITA*" 2>/dev/null | wc -l)
        if [[ $FOREIGN_COUNT -gt 0 ]]; then
            print_warn "Foreign-only content in NuWho: $FOREIGN_COUNT"
            FOREIGN_ONLY+=("Doctor Who (2005): $FOREIGN_COUNT foreign files")
        fi

        # Check for .nzb files
        NZB_COUNT=$(find "$WHO_2005" -name "*.nzb" 2>/dev/null | wc -l)
        if [[ $NZB_COUNT -gt 0 ]]; then
            print_warn ".nzb files in library: $NZB_COUNT (delete recommended)"
        fi
    fi
else
    print_error "TV library not found"
fi

# Anime TV Library Check
print_section "Anime TV Library ($ANIME_TV_PATH)"

if [[ -d "$ANIME_TV_PATH" ]]; then
    STATS[anime_tv_series]=$(find "$ANIME_TV_PATH" -maxdepth 1 -type d | wc -l)
    ((STATS[anime_tv_series]--))

    if [[ "$QUICK_MODE" == "false" ]]; then
        STATS[anime_tv_episodes]=$(count_videos "$ANIME_TV_PATH")
    fi

    print_ok "Series: ${STATS[anime_tv_series]}"
    [[ "$QUICK_MODE" == "false" ]] && print_ok "Episode files: ${STATS[anime_tv_episodes]}"
else
    print_error "Anime TV library not found"
fi

# Anime Movies Check
print_section "Anime Movies Library ($ANIME_MOVIES_PATH)"

if [[ -d "$ANIME_MOVIES_PATH" ]]; then
    STATS[anime_movies_folders]=$(find "$ANIME_MOVIES_PATH" -maxdepth 1 -type d | wc -l)
    ((STATS[anime_movies_folders]--))
    STATS[anime_movies_files]=$(count_videos "$ANIME_MOVIES_PATH")

    print_ok "Folders: ${STATS[anime_movies_folders]}"
    print_ok "Video files: ${STATS[anime_movies_files]}"

    if [[ ${STATS[anime_movies_files]} -lt ${STATS[anime_movies_folders]} ]]; then
        DIFF=$((STATS[anime_movies_folders] - STATS[anime_movies_files]))
        print_warn "Potential empty/broken folders: ~$DIFF"
    fi
else
    print_error "Anime movies library not found"
fi

# Downloads Check
print_section "Downloads Staging ($DOWNLOADS_PATH)"

if [[ -d "$DOWNLOADS_PATH" ]]; then
    COMPLETE_SIZE=$(du -sh "$DOWNLOADS_PATH/complete" 2>/dev/null | cut -f1 || echo "0")
    INCOMPLETE_SIZE=$(du -sh "$DOWNLOADS_PATH/incomplete" 2>/dev/null | cut -f1 || echo "0")

    print_ok "Complete: $COMPLETE_SIZE"
    print_ok "Incomplete: $INCOMPLETE_SIZE"

    # Check for orphaned content in complete
    if [[ -d "$DOWNLOADS_PATH/complete" ]]; then
        ORPHAN_COUNT=$(find "$DOWNLOADS_PATH/complete" -name "*.mkv" -o -name "*.mp4" 2>/dev/null | wc -l)
        if [[ $ORPHAN_COUNT -gt 0 ]]; then
            print_warn "Orphaned videos in complete: $ORPHAN_COUNT"
            STATS[downloads_orphaned]=$ORPHAN_COUNT
        else
            print_ok "No orphaned content"
        fi
    fi
else
    print_warn "Downloads path not found"
fi

# Summary
print_header "HEALTH CHECK SUMMARY"

TOTAL_ISSUES=0
((TOTAL_ISSUES+=${STATS[movies_empty]}))
((TOTAL_ISSUES+=${STATS[naming_issues]}))
((TOTAL_ISSUES+=${STATS[downloads_orphaned]}))
((TOTAL_ISSUES+=${#FOREIGN_ONLY[@]}))

if [[ "$OUTPUT_JSON" == "false" ]]; then
    echo ""
    echo "Library Counts:"
    echo "  Movies:        ${STATS[movies_folders]} folders"
    echo "  TV Series:     ${STATS[tv_series]} series"
    echo "  Anime TV:      ${STATS[anime_tv_series]} series"
    echo "  Anime Movies:  ${STATS[anime_movies_folders]} folders"
    echo ""
    echo "Issues Found:"
    echo "  Empty folders:        ${STATS[movies_empty]}"
    echo "  Naming issues:        ${STATS[naming_issues]}"
    echo "  Orphaned downloads:   ${STATS[downloads_orphaned]}"
    echo "  Foreign-only content: ${#FOREIGN_ONLY[@]}"
    echo ""

    if [[ $TOTAL_ISSUES -eq 0 ]]; then
        echo -e "${GREEN}✓ Library is healthy - no issues found${NC}"
    else
        echo -e "${YELLOW}⚠ Found $TOTAL_ISSUES issues requiring attention${NC}"
    fi

    echo ""
    echo "Recommendations:"

    if [[ ${STATS[movies_empty]} -gt 0 ]]; then
        echo "  - Delete ${STATS[movies_empty]} empty movie folders"
    fi

    if [[ ${STATS[downloads_orphaned]} -gt 0 ]]; then
        echo "  - Import or delete ${STATS[downloads_orphaned]} orphaned downloads"
    fi

    if [[ ${#FOREIGN_ONLY[@]} -gt 0 ]]; then
        echo "  - Review foreign-only content in Doctor Who libraries"
    fi

    echo ""
    echo "Run with --json for machine-readable output"
else
    # JSON Output
    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "pool": {
    "path": "$POOL_ROOT",
    "total": "$POOL_TOTAL",
    "used": "$POOL_USED",
    "available": "$POOL_AVAIL",
    "percent_used": "$POOL_PERCENT"
  },
  "libraries": {
    "movies": {
      "folders": ${STATS[movies_folders]},
      "empty_folders": ${STATS[movies_empty]},
      "video_files": ${STATS[movies_files]}
    },
    "tv": {
      "series": ${STATS[tv_series]},
      "episodes": ${STATS[tv_episodes]}
    },
    "anime_tv": {
      "series": ${STATS[anime_tv_series]},
      "episodes": ${STATS[anime_tv_episodes]}
    },
    "anime_movies": {
      "folders": ${STATS[anime_movies_folders]},
      "files": ${STATS[anime_movies_files]}
    }
  },
  "issues": {
    "total": $TOTAL_ISSUES,
    "empty_folders": ${STATS[movies_empty]},
    "naming_issues": ${STATS[naming_issues]},
    "orphaned_downloads": ${STATS[downloads_orphaned]},
    "foreign_only_content": ${#FOREIGN_ONLY[@]}
  },
  "health": "$( [[ $TOTAL_ISSUES -eq 0 ]] && echo "healthy" || echo "needs_attention" )"
}
EOF
fi

exit 0
