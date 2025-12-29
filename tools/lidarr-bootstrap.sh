#!/usr/bin/env bash
#
# lidarr-bootstrap.sh - Bootstrap Lidarr with artists from USB/external directory
#
# Usage:
#   ./lidarr-bootstrap.sh /path/to/music           # Add all artists
#   ./lidarr-bootstrap.sh /path/to/music --dry-run # Preview what would be added
#   ./lidarr-bootstrap.sh --list                   # List current Lidarr artists
#
# Environment:
#   LIDARR_URL      - Lidarr URL (default: http://localhost:8686)
#   LIDARR_API_KEY  - Lidarr API key (required)
#   MUSIC_ROOT      - Default music library path for Lidarr
#
# Features:
#   - Scans directory for artist folders
#   - Queries MusicBrainz for artist metadata
#   - Adds artists to Lidarr with monitoring enabled
#   - Skips already-monitored artists
#   - Reports unmatched artists for manual review
#
# Rate Limiting:
#   - MusicBrainz: 1 request per second
#   - Lidarr: 5 requests per second
#

set -euo pipefail

# Configuration
LIDARR_URL="${LIDARR_URL:-http://localhost:8686}"
LIDARR_API_KEY="${LIDARR_API_KEY:-}"
MUSIC_ROOT="${MUSIC_ROOT:-/pool/music}"
DRY_RUN=false
LIST_ONLY=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_debug() { [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [MUSIC_PATH]

Bootstrap Lidarr with artists from a directory.

Arguments:
  MUSIC_PATH        Path to music directory (e.g., /run/media/deck/Slow_3TB_HD/Music)

Options:
  --dry-run         Preview what would be added without making changes
  --list            List current Lidarr artists and exit
  --verbose, -v     Enable verbose output
  --help, -h        Show this help message

Environment Variables:
  LIDARR_URL        Lidarr server URL (default: http://localhost:8686)
  LIDARR_API_KEY    Lidarr API key (required)
  MUSIC_ROOT        Target music root path in Lidarr (default: /pool/music)

Examples:
  # Preview import from USB drive
  $(basename "$0") /run/media/deck/Slow_3TB_HD/Music --dry-run

  # Import all artists
  LIDARR_API_KEY=xxx $(basename "$0") /run/media/deck/Slow_3TB_HD/Music

  # List current Lidarr artists
  LIDARR_API_KEY=xxx $(basename "$0") --list
EOF
    exit 0
}

# Parse arguments
parse_args() {
    local positional=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --list)
                LIST_ONLY=true
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

    MUSIC_PATH="${positional[0]:-}"
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

# Validate Lidarr connection
check_lidarr() {
    if [[ -z "$LIDARR_API_KEY" ]]; then
        log_error "LIDARR_API_KEY environment variable not set"
        log_info "Get your API key from Lidarr: Settings -> General -> API Key"
        exit 1
    fi

    log_debug "Checking Lidarr connection at $LIDARR_URL"

    local response
    if ! response=$(curl -s --max-time 10 "$LIDARR_URL/api/v1/system/status" \
        -H "X-Api-Key: $LIDARR_API_KEY" 2>/dev/null); then
        log_error "Cannot connect to Lidarr at $LIDARR_URL"
        exit 1
    fi

    if ! echo "$response" | jq -e '.version' &>/dev/null; then
        log_error "Invalid response from Lidarr (API key may be wrong)"
        log_debug "Response: $response"
        exit 1
    fi

    local version
    version=$(echo "$response" | jq -r '.version')
    log_info "Connected to Lidarr v$version"
}

# Get current Lidarr artists
get_lidarr_artists() {
    curl -s "$LIDARR_URL/api/v1/artist" \
        -H "X-Api-Key: $LIDARR_API_KEY" | jq -r '.[].artistName' | sort
}

# Check if artist exists in Lidarr
artist_exists() {
    local name="$1"
    local encoded
    encoded=$(echo "$name" | jq -sRr @uri)

    local count
    count=$(curl -s "$LIDARR_URL/api/v1/artist" \
        -H "X-Api-Key: $LIDARR_API_KEY" | \
        jq --arg name "$name" '[.[] | select(.artistName | ascii_downcase == ($name | ascii_downcase))] | length')

    [[ "$count" -gt 0 ]]
}

# Search for artist in MusicBrainz via Lidarr
search_artist() {
    local name="$1"
    local encoded
    encoded=$(echo "$name" | jq -sRr @uri)

    # Rate limit: 1 request per second for MusicBrainz
    sleep 1

    curl -s "$LIDARR_URL/api/v1/artist/lookup?term=${encoded}" \
        -H "X-Api-Key: $LIDARR_API_KEY"
}

# Add artist to Lidarr
add_artist() {
    local artist_data="$1"

    local payload
    payload=$(echo "$artist_data" | jq --arg root "$MUSIC_ROOT" '{
        artistName: .artistName,
        foreignArtistId: .foreignArtistId,
        qualityProfileId: 1,
        metadataProfileId: 1,
        rootFolderPath: $root,
        monitored: true,
        monitorNewItems: "all",
        addOptions: {
            monitor: "all",
            searchForMissingAlbums: false
        }
    }')

    log_debug "Adding artist: $(echo "$payload" | jq -r '.artistName')"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would add: $(echo "$payload" | jq -r '.artistName')"
        return 0
    fi

    local response
    response=$(curl -s -X POST "$LIDARR_URL/api/v1/artist" \
        -H "X-Api-Key: $LIDARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | jq -e '.id' &>/dev/null; then
        return 0
    else
        log_error "Failed to add artist: $(echo "$response" | jq -r '.message // "Unknown error"')"
        return 1
    fi
}

# List current artists
list_artists() {
    check_lidarr

    log_info "Current Lidarr artists:"
    echo ""

    local artists
    artists=$(get_lidarr_artists)
    local count
    count=$(echo "$artists" | grep -c . || echo 0)

    echo "$artists"
    echo ""
    log_info "Total: $count artists"
}

# Scan directory for artists
scan_directory() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        log_error "Directory not found: $path"
        exit 1
    fi

    log_info "Scanning: $path"

    # Get list of artist folders (skip hidden files and desktop.ini)
    local artists=()
    while IFS= read -r -d '' dir; do
        local name
        name=$(basename "$dir")
        # Skip hidden files and Windows system files
        [[ "$name" == .* ]] && continue
        [[ "$name" == "desktop.ini" ]] && continue
        artists+=("$name")
    done < <(find "$path" -maxdepth 1 -type d -print0 | sort -z)

    # Remove the root directory itself
    artists=("${artists[@]:1}")

    log_info "Found ${#artists[@]} artist folders"
    echo ""

    # Counters
    local added=0
    local skipped=0
    local not_found=0
    local failed=0
    local not_found_list=()

    for artist in "${artists[@]}"; do
        log_debug "Processing: $artist"

        # Check if already in Lidarr
        if artist_exists "$artist"; then
            log_info "  [SKIP] $artist (already in Lidarr)"
            ((skipped++))
            continue
        fi

        # Search for artist
        local search_result
        search_result=$(search_artist "$artist")

        # Check if we got results
        local result_count
        result_count=$(echo "$search_result" | jq 'length')

        if [[ "$result_count" -eq 0 ]]; then
            log_warn "  [NOT FOUND] $artist"
            ((not_found++))
            not_found_list+=("$artist")
            continue
        fi

        # Get the best match (first result)
        local best_match
        best_match=$(echo "$search_result" | jq '.[0]')
        local matched_name
        matched_name=$(echo "$best_match" | jq -r '.artistName')

        # Add the artist
        if add_artist "$best_match"; then
            log_info "  [ADDED] $artist -> $matched_name"
            ((added++))
        else
            ((failed++))
        fi

        # Rate limit for Lidarr API
        sleep 0.2
    done

    echo ""
    log_info "=== Summary ==="
    log_info "Added:     $added"
    log_info "Skipped:   $skipped (already in Lidarr)"
    log_info "Not Found: $not_found"
    log_info "Failed:    $failed"

    if [[ ${#not_found_list[@]} -gt 0 ]]; then
        echo ""
        log_warn "Artists not found in MusicBrainz:"
        printf '  - %s\n' "${not_found_list[@]}"
        echo ""
        log_info "These may need manual addition with different spellings"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        log_info "[DRY-RUN] No changes were made. Remove --dry-run to apply."
    fi
}

# Main
main() {
    parse_args "$@"
    check_deps

    if [[ "$LIST_ONLY" == "true" ]]; then
        list_artists
        exit 0
    fi

    if [[ -z "$MUSIC_PATH" ]]; then
        log_error "Music path required"
        echo ""
        usage
    fi

    check_lidarr
    scan_directory "$MUSIC_PATH"
}

main "$@"
