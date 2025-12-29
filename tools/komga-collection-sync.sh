#!/usr/bin/env bash
# komga-collection-sync.sh
# Creates Komga collections linking same-name series across libraries
#
# Purpose: When you have "Chainsaw Man" in both Manga (Collected) and
# Manga (Weekly) libraries, this script creates a collection containing
# both versions for unified browsing.
#
# USAGE:
#   ./tools/komga-collection-sync.sh [--dry-run]
#
# OPTIONS:
#   --dry-run   Show what collections would be created without making changes
#   --verbose   Show detailed API responses
#
# ENVIRONMENT:
#   KOMGA_URL        Komga server URL (default: http://localhost:8081)
#   KOMGA_USERNAME   Komga admin username
#   KOMGA_PASSWORD   Komga admin password

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
KOMGA_URL="${KOMGA_URL:-http://localhost:8081}"
KOMGA_USER="${KOMGA_USERNAME:-}"
KOMGA_PASS="${KOMGA_PASSWORD:-}"

DRY_RUN=false
VERBOSE=false

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
debug() { [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $1"; }
header() { echo -e "\n${CYAN}=== $1 ===${NC}"; }

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true; log "DRY RUN MODE - No changes will be made" ;;
        --verbose) VERBOSE=true ;;
        --help)
            echo "Usage: $0 [--dry-run] [--verbose]"
            echo ""
            echo "Creates Komga collections linking same-name series across libraries."
            echo ""
            echo "Options:"
            echo "  --dry-run   Show what would be done without making changes"
            echo "  --verbose   Show detailed API responses"
            echo ""
            echo "Environment:"
            echo "  KOMGA_URL        Komga server URL (default: http://localhost:8081)"
            echo "  KOMGA_USERNAME   Komga admin username"
            echo "  KOMGA_PASSWORD   Komga admin password"
            exit 0
            ;;
    esac
done

# Validate credentials
validate_auth() {
    if [[ -z "$KOMGA_USER" || -z "$KOMGA_PASS" ]]; then
        error "KOMGA_USERNAME and KOMGA_PASSWORD must be set"
        exit 1
    fi

    # Test connection
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries")

    if [[ "$response" != "200" ]]; then
        error "Failed to connect to Komga at $KOMGA_URL (HTTP $response)"
        exit 1
    fi

    log "Connected to Komga at $KOMGA_URL"
}

# API helpers
komga_get() {
    local endpoint="$1"
    curl -s -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1$endpoint"
}

komga_post() {
    local endpoint="$1"
    local data="$2"
    curl -s -X POST -u "$KOMGA_USER:$KOMGA_PASS" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$KOMGA_URL/api/v1$endpoint"
}

komga_patch() {
    local endpoint="$1"
    local data="$2"
    curl -s -X PATCH -u "$KOMGA_USER:$KOMGA_PASS" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$KOMGA_URL/api/v1$endpoint"
}

# Get all libraries
get_libraries() {
    komga_get "/libraries"
}

# Get all series (paginated, returns all)
get_all_series() {
    local page=0
    local page_size=500
    local all_series="[]"

    while true; do
        local response
        response=$(komga_get "/series?page=$page&size=$page_size")

        local content
        content=$(echo "$response" | jq '.content')

        if [[ $(echo "$content" | jq 'length') -eq 0 ]]; then
            break
        fi

        all_series=$(echo "$all_series $content" | jq -s 'add')
        ((page++))

        debug "Fetched page $page of series"
    done

    echo "$all_series"
}

# Get existing collections
get_collections() {
    komga_get "/collections"
}

# Normalize series name for matching
# Removes: publisher tags, language tags, year, "Collected/Weekly" markers
normalize_name() {
    local name="$1"

    # Remove publisher in parentheses: "Chainsaw Man (Viz)" -> "Chainsaw Man"
    name=$(echo "$name" | sed -E 's/\s*\([^)]+\)\s*/ /g')

    # Remove language tags in brackets: "[EN]", "[JP]"
    name=$(echo "$name" | sed -E 's/\s*\[[A-Z]{2}\]\s*/ /g')

    # Remove year: "(2020)", "(2019)"
    name=$(echo "$name" | sed -E 's/\s*\([0-9]{4}\)\s*/ /g')

    # Trim and normalize whitespace
    name=$(echo "$name" | sed 's/\s\+/ /g' | sed 's/^ \+//;s/ \+$//')

    # Lowercase for comparison
    echo "$name" | tr '[:upper:]' '[:lower:]'
}

# Find series that exist in multiple libraries
find_cross_library_series() {
    local all_series="$1"

    # Create map: normalized_name -> [series_ids]
    local series_map="{}"

    while IFS= read -r series; do
        [[ -z "$series" ]] && continue

        local id=$(echo "$series" | jq -r '.id')
        local name=$(echo "$series" | jq -r '.name')
        local library_id=$(echo "$series" | jq -r '.libraryId')
        local normalized=$(normalize_name "$name")

        # Add to map
        if echo "$series_map" | jq -e ".[\"$normalized\"]" >/dev/null 2>&1; then
            # Key exists, append
            series_map=$(echo "$series_map" | jq --arg k "$normalized" --arg id "$id" \
                '.[$k] += [$id]')
        else
            # New key
            series_map=$(echo "$series_map" | jq --arg k "$normalized" --arg id "$id" \
                '.[$k] = [$id]')
        fi
    done < <(echo "$all_series" | jq -c '.[]')

    # Filter to only series in multiple libraries
    echo "$series_map" | jq 'to_entries | map(select(.value | length > 1)) | from_entries'
}

# Create collection for a set of series
create_collection() {
    local name="$1"
    local series_ids="$2"

    local collection_name="${name} (All Editions)"

    # Capitalize first letter of each word
    collection_name=$(echo "$collection_name" | sed -E 's/\b(.)/\u\1/g')

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create collection: $collection_name"
        log "  Series: $series_ids"
        return 0
    fi

    # Create collection
    local payload
    payload=$(jq -n \
        --arg name "$collection_name" \
        --argjson seriesIds "$series_ids" \
        '{name: $name, ordered: false, seriesIds: $seriesIds}')

    debug "Creating collection: $payload"

    local response
    response=$(komga_post "/collections" "$payload")

    if echo "$response" | jq -e '.id' >/dev/null 2>&1; then
        local coll_id=$(echo "$response" | jq -r '.id')
        log "Created collection: $collection_name (ID: $coll_id)"
    else
        warn "Failed to create collection: $collection_name"
        debug "Response: $response"
    fi
}

# Update existing collection with new series
update_collection() {
    local collection_id="$1"
    local collection_name="$2"
    local new_series_ids="$3"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would update collection: $collection_name"
        log "  Adding series: $new_series_ids"
        return 0
    fi

    # Get current series in collection
    local current
    current=$(komga_get "/collections/$collection_id")
    local current_series
    current_series=$(echo "$current" | jq '.seriesIds')

    # Merge series (unique)
    local merged
    merged=$(echo "$current_series $new_series_ids" | jq -s 'add | unique')

    local payload
    payload=$(jq -n --argjson seriesIds "$merged" '{seriesIds: $seriesIds}')

    komga_patch "/collections/$collection_id" "$payload"
    log "Updated collection: $collection_name"
}

# Main sync logic
sync_collections() {
    header "Fetching Libraries"
    local libraries
    libraries=$(get_libraries)
    local lib_count=$(echo "$libraries" | jq 'length')
    log "Found $lib_count libraries"

    if [[ $lib_count -lt 2 ]]; then
        log "Need at least 2 libraries for cross-library collections"
        exit 0
    fi

    header "Fetching Series"
    local all_series
    all_series=$(get_all_series)
    local series_count=$(echo "$all_series" | jq 'length')
    log "Found $series_count total series"

    header "Finding Cross-Library Series"
    local cross_library
    cross_library=$(find_cross_library_series "$all_series")
    local cross_count=$(echo "$cross_library" | jq 'length')
    log "Found $cross_count series appearing in multiple libraries"

    if [[ $cross_count -eq 0 ]]; then
        log "No cross-library series found. Nothing to do."
        exit 0
    fi

    header "Fetching Existing Collections"
    local existing_collections
    existing_collections=$(get_collections)
    debug "Existing collections: $(echo "$existing_collections" | jq -c '.[].name')"

    header "Creating/Updating Collections"
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue

        local name=$(echo "$entry" | jq -r '.key')
        local series_ids=$(echo "$entry" | jq '.value')

        # Check if collection already exists (fuzzy match on name)
        local collection_name="${name} (All Editions)"
        collection_name=$(echo "$collection_name" | sed -E 's/\b(.)/\u\1/g')

        local existing
        existing=$(echo "$existing_collections" | jq -r \
            --arg name "$collection_name" \
            '.[] | select(.name == $name) | .id')

        if [[ -n "$existing" ]]; then
            update_collection "$existing" "$collection_name" "$series_ids"
        else
            create_collection "$name" "$series_ids"
        fi
    done < <(echo "$cross_library" | jq -c 'to_entries[]')

    header "Sync Complete"
}

# Main
main() {
    log "Komga Collection Sync"
    log "  URL: $KOMGA_URL"

    validate_auth
    sync_collections
}

main "$@"
