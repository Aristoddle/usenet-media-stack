#!/usr/bin/env bash
#
# usb-movie-importer.sh - Import movies from USB/external drive to Radarr
#
# Usage:
#   ./usb-movie-importer.sh /path/to/movies           # Analyze and report
#   ./usb-movie-importer.sh /path/to/movies --import  # Actually import unique movies
#   ./usb-movie-importer.sh /path/to/movies --dry-run # Preview what would be imported
#
# Environment:
#   RADARR_URL      - Radarr URL (default: http://localhost:7878)
#   RADARR_API_KEY  - Radarr API key (required)
#   POOL_MOVIES     - Target movies root path (default: /pool/movies)
#
# Features:
#   - Scans directory for movie folders
#   - Parses folder names for title and year
#   - Queries Radarr for existing movies
#   - Reports: unique movies, duplicates, quality comparison
#   - Optional: imports unique movies to Radarr library
#

set -euo pipefail

# Configuration
RADARR_URL="${RADARR_URL:-http://localhost:7878}"
RADARR_API_KEY="${RADARR_API_KEY:-}"
POOL_MOVIES="${POOL_MOVIES:-/pool/movies}"
DRY_RUN=false
IMPORT_MODE=false
VERBOSE=false
QUALITY_THRESHOLD="${QUALITY_THRESHOLD:-1080}"  # Minimum resolution to prefer

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_debug() { [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }
log_unique() { echo -e "${CYAN}[UNIQUE]${NC} $*"; }
log_dupe() { echo -e "${YELLOW}[DUPE]${NC} $*"; }

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] MOVIES_PATH

Analyze and import movies from USB/external drive to Radarr.

Arguments:
  MOVIES_PATH       Path to movies directory (e.g., /run/media/deck/Slow_4TB_2/Movies)

Options:
  --import          Import unique movies to Radarr
  --dry-run         Preview what would be imported (with --import)
  --verbose, -v     Enable verbose output
  --help, -h        Show this help message

Environment Variables:
  RADARR_URL        Radarr server URL (default: http://localhost:7878)
  RADARR_API_KEY    Radarr API key (required)
  POOL_MOVIES       Target movies root path (default: /pool/movies)

Examples:
  # Analyze USB movies (report only)
  RADARR_API_KEY=xxx $(basename "$0") /run/media/deck/Slow_4TB_2/Movies

  # Preview import
  RADARR_API_KEY=xxx $(basename "$0") /run/media/deck/Slow_4TB_2/Movies --import --dry-run

  # Import unique movies
  RADARR_API_KEY=xxx $(basename "$0") /run/media/deck/Slow_4TB_2/Movies --import
EOF
    exit 0
}

# Parse arguments
parse_args() {
    local positional=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --import)
                IMPORT_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    MOVIES_PATH="${positional[0]:-}"
}

# Check dependencies
check_deps() {
    local deps=(curl jq)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Required dependency not found: $dep"
            exit 1
        fi
    done
}

# Validate Radarr connection
check_radarr() {
    if [[ -z "$RADARR_API_KEY" ]]; then
        log_error "RADARR_API_KEY environment variable not set"
        log_info "Get your API key from Radarr: Settings -> General -> API Key"
        exit 1
    fi

    log_debug "Checking Radarr connection at $RADARR_URL"

    local response
    if ! response=$(curl -s --max-time 10 "$RADARR_URL/api/v3/system/status" \
        -H "X-Api-Key: $RADARR_API_KEY" 2>/dev/null); then
        log_error "Cannot connect to Radarr at $RADARR_URL"
        exit 1
    fi

    if ! echo "$response" | jq -e '.version' &>/dev/null; then
        log_error "Invalid response from Radarr (API key may be wrong)"
        exit 1
    fi

    local version
    version=$(echo "$response" | jq -r '.version')
    log_info "Connected to Radarr v$version"
}

# Get all movies from Radarr
get_radarr_movies() {
    curl -s "$RADARR_URL/api/v3/movie" \
        -H "X-Api-Key: $RADARR_API_KEY"
}

# Parse movie folder name to extract title and year
parse_folder_name() {
    local folder="$1"

    # Common patterns:
    # "Movie Name (2023)"
    # "Movie Name (2023) 1080p"
    # "Movie.Name.2023.1080p.BluRay"

    # Extract year (last 4-digit number in parentheses or standalone)
    local year=""
    if [[ "$folder" =~ \(([0-9]{4})\) ]]; then
        year="${BASH_REMATCH[1]}"
    elif [[ "$folder" =~ \.([0-9]{4})\. ]]; then
        year="${BASH_REMATCH[1]}"
    elif [[ "$folder" =~ ([0-9]{4})$ ]]; then
        year="${BASH_REMATCH[1]}"
    fi

    # Extract title (everything before the year)
    local title="$folder"
    if [[ -n "$year" ]]; then
        # Remove year and everything after
        title=$(echo "$folder" | sed -E "s/[.\s\(]*${year}.*//")
    fi

    # Clean up title
    title=$(echo "$title" | sed 's/\./ /g' | sed 's/_/ /g' | sed 's/  */ /g' | xargs)

    echo "${title}|${year}"
}

# Search for movie in Radarr
search_movie() {
    local title="$1"
    local year="$2"

    local term="${title}"
    [[ -n "$year" ]] && term="${title} ${year}"

    local encoded
    encoded=$(echo "$term" | jq -sRr @uri)

    curl -s "$RADARR_URL/api/v3/movie/lookup?term=${encoded}" \
        -H "X-Api-Key: $RADARR_API_KEY"
}

# Check if movie exists by TMDB ID
movie_exists_by_tmdb() {
    local tmdb_id="$1"
    local radarr_movies="$2"

    echo "$radarr_movies" | jq --arg id "$tmdb_id" '[.[] | select(.tmdbId == ($id | tonumber))] | length > 0'
}

# Get movie details from Radarr by TMDB ID
get_movie_by_tmdb() {
    local tmdb_id="$1"
    local radarr_movies="$2"

    echo "$radarr_movies" | jq --arg id "$tmdb_id" '.[] | select(.tmdbId == ($id | tonumber))'
}

# Analyze USB movie vs Radarr
analyze_movie() {
    local folder="$1"
    local radarr_movies="$2"

    local parsed
    parsed=$(parse_folder_name "$folder")
    local title="${parsed%%|*}"
    local year="${parsed##*|}"

    log_debug "Analyzing: $folder -> Title: '$title', Year: '$year'"

    # Search for movie
    local search_result
    search_result=$(search_movie "$title" "$year")
    sleep 0.2  # Rate limit

    local result_count
    result_count=$(echo "$search_result" | jq 'length')

    if [[ "$result_count" -eq 0 ]]; then
        echo "NOT_FOUND|$folder|$title|$year|"
        return
    fi

    # Get best match
    local best_match
    best_match=$(echo "$search_result" | jq '.[0]')
    local tmdb_id
    tmdb_id=$(echo "$best_match" | jq -r '.tmdbId')
    local matched_title
    matched_title=$(echo "$best_match" | jq -r '.title')

    # Check if exists in Radarr
    local exists
    exists=$(movie_exists_by_tmdb "$tmdb_id" "$radarr_movies")

    if [[ "$exists" == "true" ]]; then
        local existing
        existing=$(get_movie_by_tmdb "$tmdb_id" "$radarr_movies")
        local quality
        quality=$(echo "$existing" | jq -r '.movieFile.quality.quality.name // "No file"')
        echo "DUPLICATE|$folder|$matched_title|$year|$quality"
    else
        echo "UNIQUE|$folder|$matched_title|$year|$tmdb_id"
    fi
}

# Add movie to Radarr
add_movie() {
    local folder="$1"
    local tmdb_id="$2"

    # Get movie details from TMDB via Radarr lookup
    local movie_data
    movie_data=$(curl -s "$RADARR_URL/api/v3/movie/lookup/tmdb?tmdbId=${tmdb_id}" \
        -H "X-Api-Key: $RADARR_API_KEY")

    local payload
    payload=$(echo "$movie_data" | jq --arg root "$POOL_MOVIES" '{
        title: .title,
        tmdbId: .tmdbId,
        year: .year,
        qualityProfileId: 1,
        rootFolderPath: $root,
        monitored: true,
        addOptions: {
            searchForMovie: false
        }
    }')

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would add: $(echo "$payload" | jq -r '.title')"
        return 0
    fi

    local response
    response=$(curl -s -X POST "$RADARR_URL/api/v3/movie" \
        -H "X-Api-Key: $RADARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | jq -e '.id' &>/dev/null; then
        return 0
    else
        log_error "Failed to add movie: $(echo "$response" | jq -r '.message // "Unknown error"')"
        return 1
    fi
}

# Scan directory for movies
scan_directory() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        log_error "Directory not found: $path"
        exit 1
    fi

    log_info "Scanning: $path"
    log_info "Fetching Radarr library..."

    local radarr_movies
    radarr_movies=$(get_radarr_movies)
    local radarr_count
    radarr_count=$(echo "$radarr_movies" | jq 'length')
    log_info "Radarr has $radarr_count movies"

    # Get list of movie folders
    local folders=()
    while IFS= read -r -d '' dir; do
        local name
        name=$(basename "$dir")
        # Skip hidden files and Windows system files
        [[ "$name" == .* ]] && continue
        [[ "$name" == "desktop.ini" ]] && continue
        folders+=("$name")
    done < <(find "$path" -maxdepth 1 -type d -print0 | sort -z)

    # Remove the root directory itself
    folders=("${folders[@]:1}")

    log_info "Found ${#folders[@]} movie folders"
    echo ""

    # Counters and lists
    local unique=0
    local duplicates=0
    local not_found=0
    local unique_list=()
    local dupe_list=()
    local not_found_list=()

    echo "=== Analysis ==="
    echo ""

    for folder in "${folders[@]}"; do
        local result
        result=$(analyze_movie "$folder" "$radarr_movies")

        local status="${result%%|*}"
        local rest="${result#*|}"
        local orig_folder="${rest%%|*}"
        rest="${rest#*|}"
        local title="${rest%%|*}"
        rest="${rest#*|}"
        local year="${rest%%|*}"
        local extra="${rest#*|}"

        case "$status" in
            UNIQUE)
                log_unique "$title ($year) - TMDB: $extra"
                ((unique++))
                unique_list+=("$folder|$extra")
                ;;
            DUPLICATE)
                log_dupe "$title ($year) - Existing quality: $extra"
                ((duplicates++))
                dupe_list+=("$folder")
                ;;
            NOT_FOUND)
                log_warn "[NOT FOUND] $folder -> searched: '$title' ($year)"
                ((not_found++))
                not_found_list+=("$folder")
                ;;
        esac
    done

    echo ""
    echo "=== Summary ==="
    log_info "Unique (not in Radarr): $unique"
    log_info "Duplicates (in Radarr): $duplicates"
    log_warn "Not found (no TMDB match): $not_found"
    echo ""

    # Import unique movies if requested
    if [[ "$IMPORT_MODE" == "true" ]] && [[ ${#unique_list[@]} -gt 0 ]]; then
        echo "=== Import ==="
        local imported=0
        local failed=0

        for item in "${unique_list[@]}"; do
            local folder="${item%%|*}"
            local tmdb_id="${item##*|}"

            if add_movie "$folder" "$tmdb_id"; then
                log_info "Added: $folder"
                ((imported++))
            else
                ((failed++))
            fi

            sleep 0.2  # Rate limit
        done

        echo ""
        log_info "Imported: $imported"
        [[ $failed -gt 0 ]] && log_error "Failed: $failed"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo ""
            log_info "[DRY-RUN] No changes were made. Remove --dry-run to apply."
        fi
    elif [[ "$IMPORT_MODE" == "false" ]] && [[ ${#unique_list[@]} -gt 0 ]]; then
        echo ""
        log_info "To import unique movies, run with --import flag"
    fi

    # Report not found
    if [[ ${#not_found_list[@]} -gt 0 ]]; then
        echo ""
        log_warn "Movies not found in TMDB (may need manual search):"
        for folder in "${not_found_list[@]}"; do
            echo "  - $folder"
        done
    fi
}

# Main
main() {
    parse_args "$@"
    check_deps

    if [[ -z "$MOVIES_PATH" ]]; then
        log_error "Movies path required"
        echo ""
        usage
    fi

    check_radarr
    scan_directory "$MOVIES_PATH"
}

main "$@"
