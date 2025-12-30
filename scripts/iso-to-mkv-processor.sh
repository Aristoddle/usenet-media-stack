#!/bin/bash
# iso-to-mkv-processor.sh - Extract main title from Blu-ray ISOs for Tdarr transcoding
#
# Architecture:
#   Stage 1 (this script): ISO → MKV via MakeMKV (lossless extraction)
#   Stage 2 (Tdarr):       MKV → AV1 via SVT-AV1 (transcoding)
#
# Usage:
#   ./iso-to-mkv-processor.sh                    # Process all ISOs in pool/movies
#   ./iso-to-mkv-processor.sh --scan             # Scan and report ISOs without processing
#   ./iso-to-mkv-processor.sh /path/to/file.iso  # Process specific ISO
#   ./iso-to-mkv-processor.sh --watch            # Watch for new ISOs and process
#
# Requirements:
#   - Docker running with makemkv container
#   - MakeMKV container has /pool mounted (read-only) and /output (read-write)

set -euo pipefail

# Configuration
POOL_ROOT="${POOL_ROOT:-/var/mnt/pool}"
OUTPUT_ROOT="${MAKEMKV_OUTPUT:-/var/mnt/fast8tb/Local/downloads/makemkv-output}"
PROCESSED_LOG="${OUTPUT_ROOT}/.processed-isos.log"
MIN_LENGTH="${MAKEMKV_MIN_LENGTH:-3600}"  # 60 minutes - filters out bonus content
CONTAINER_NAME="makemkv"
LOG_PREFIX="[iso-processor]"

# Ensure output directory exists
mkdir -p "$OUTPUT_ROOT"

log() {
    echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') $*"
}

log_error() {
    echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') ERROR: $*" >&2
}

# Docker command (use sudo if user can't access docker directly)
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    fi
fi

# Check if MakeMKV container is running
check_container() {
    if ! $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "MakeMKV container '${CONTAINER_NAME}' is not running"
        log "Start with: docker compose up -d makemkv"
        return 1
    fi
    return 0
}

# Convert host path to container path
host_to_container_path() {
    local host_path="$1"
    # Host /var/mnt/pool → Container /pool
    echo "${host_path/$POOL_ROOT//pool}"
}

container_to_host_output_path() {
    local container_path="$1"
    # Container /output → Host $OUTPUT_ROOT
    echo "${container_path//\/output/$OUTPUT_ROOT}"
}

# Check if ISO has already been processed
is_processed() {
    local iso_path="$1"
    if [[ -f "$PROCESSED_LOG" ]]; then
        grep -qF "$iso_path" "$PROCESSED_LOG" 2>/dev/null
    else
        return 1
    fi
}

# Mark ISO as processed
mark_processed() {
    local iso_path="$1"
    echo "$iso_path" >> "$PROCESSED_LOG"
}

# Get basename without extensions
get_movie_name() {
    local iso_path="$1"
    local dirname=$(dirname "$iso_path")
    local folder_name=$(basename "$dirname")

    # Use parent folder name (usually the movie name)
    # Strip common suffixes like "-AsRequested", scene group names, etc.
    echo "$folder_name" | sed -E 's/[-.]*(AsRequested|COMPLETE|UHD|BLURAY|BluRay|2160p|1080p|720p).*//i' | sed 's/\./ /g'
}

# Process a single ISO file
process_iso() {
    local iso_path="$1"
    local container_iso_path=$(host_to_container_path "$iso_path")
    local movie_name=$(get_movie_name "$iso_path")
    local output_subdir=$(basename "$(dirname "$iso_path")")
    local container_output="/output/${output_subdir}"
    local host_output="$OUTPUT_ROOT/${output_subdir}"

    if is_processed "$iso_path"; then
        log "Skipping already processed: $(basename "$iso_path")"
        return 0
    fi

    log "Processing: $movie_name"
    log "  Source: $iso_path"
    log "  Output: $host_output"

    # Create output directory
    mkdir -p "$host_output"

    # Run MakeMKV extraction
    # --minlength filters out bonus content
    # -r = robot mode (parseable output)
    # mkv = output format
    # all = extract all titles matching criteria
    log "  Extracting with MakeMKV (min length: ${MIN_LENGTH}s)..."

    if $DOCKER_CMD exec "$CONTAINER_NAME" /opt/makemkv/bin/makemkvcon \
        --minlength="$MIN_LENGTH" \
        --cache=1024 \
        --decrypt \
        -r \
        mkv "iso:${container_iso_path}" all "$container_output" 2>&1 | while read -r line; do
            # Parse makemkvcon robot output
            case "$line" in
                PRGC:*)
                    # Progress current operation
                    percent=$(echo "$line" | cut -d',' -f3 | tr -d '"')
                    printf "\r  Progress: %s%%" "$percent"
                    ;;
                MSG:*)
                    # Messages - log important ones
                    if echo "$line" | grep -qi "error\|fail\|warning"; then
                        echo ""
                        log "  MakeMKV: $line"
                    fi
                    ;;
            esac
        done; then
        echo ""  # New line after progress

        # Check if any MKVs were created
        local mkv_count=$(find "$host_output" -name "*.mkv" -type f 2>/dev/null | wc -l)

        if [[ "$mkv_count" -gt 0 ]]; then
            log "  Success: Extracted $mkv_count MKV file(s)"

            # List extracted files
            find "$host_output" -name "*.mkv" -type f -exec ls -lh {} \; | while read -r line; do
                log "    $line"
            done

            mark_processed "$iso_path"
            return 0
        else
            log_error "  No MKV files extracted - ISO may be encrypted or empty"
            return 1
        fi
    else
        echo ""
        log_error "  MakeMKV extraction failed"
        return 1
    fi
}

# Scan for ISOs in pool
scan_isos() {
    local movies_dir="$POOL_ROOT/movies"
    local report_only="${1:-false}"

    log "Scanning for Blu-ray ISOs in: $movies_dir"

    local total=0
    local unprocessed=0
    local total_size=0

    while IFS= read -r -d '' iso_path; do
        ((total++))
        local size=$(stat -c%s "$iso_path" 2>/dev/null || echo 0)
        total_size=$((total_size + size))

        if is_processed "$iso_path"; then
            if [[ "$report_only" == "true" ]]; then
                log "  [DONE] $(basename "$iso_path") ($(numfmt --to=iec-i --suffix=B $size))"
            fi
        else
            ((unprocessed++))
            if [[ "$report_only" == "true" ]]; then
                log "  [TODO] $(basename "$iso_path") ($(numfmt --to=iec-i --suffix=B $size))"
            fi
        fi
    done < <(find "$movies_dir" -name "*.iso" -type f -print0 2>/dev/null)

    log "Scan complete: $total ISOs found ($unprocessed unprocessed)"
    log "Total ISO size: $(numfmt --to=iec-i --suffix=B $total_size)"

    if [[ "$report_only" != "true" ]]; then
        return $unprocessed
    fi
}

# Process all unprocessed ISOs
process_all() {
    local movies_dir="$POOL_ROOT/movies"
    local processed=0
    local failed=0

    log "Starting batch ISO processing..."

    while IFS= read -r -d '' iso_path; do
        if ! is_processed "$iso_path"; then
            if process_iso "$iso_path"; then
                ((processed++))
            else
                ((failed++))
            fi
            log "Progress: $processed processed, $failed failed"
        fi
    done < <(find "$movies_dir" -name "*.iso" -type f -print0 2>/dev/null | sort -z)

    log "Batch complete: $processed processed, $failed failed"
}

# Watch mode - monitor for new ISOs
watch_mode() {
    if ! command -v inotifywait &>/dev/null; then
        log_error "inotifywait not installed. Install with: sudo dnf install inotify-tools"
        return 1
    fi

    local movies_dir="$POOL_ROOT/movies"
    log "Starting watch mode on: $movies_dir"
    log "Waiting for new ISO files..."

    inotifywait -m -r -e close_write -e moved_to --format '%w%f' "$movies_dir" 2>/dev/null | while read -r filepath; do
        if [[ "$filepath" == *.iso ]]; then
            log "New ISO detected: $(basename "$filepath")"
            sleep 5  # Wait for file to finish writing
            process_iso "$filepath"
        fi
    done
}

# Main
main() {
    case "${1:-}" in
        --scan)
            check_container || exit 1
            scan_isos "true"
            ;;
        --watch)
            check_container || exit 1
            watch_mode
            ;;
        --help|-h)
            cat << 'EOF'
ISO to MKV Processor - Blu-ray extraction pipeline

Usage:
  ./iso-to-mkv-processor.sh                    Process all unprocessed ISOs
  ./iso-to-mkv-processor.sh --scan             Scan and report ISO status
  ./iso-to-mkv-processor.sh --watch            Watch for new ISOs
  ./iso-to-mkv-processor.sh /path/to/file.iso  Process specific ISO

Environment Variables:
  POOL_ROOT          Base path for media pool (default: /var/mnt/pool)
  MAKEMKV_OUTPUT     Output directory for MKVs (default: /var/mnt/fast8tb/Local/downloads/makemkv-output)
  MAKEMKV_MIN_LENGTH Minimum title length in seconds (default: 3600)

After extraction:
  - MKVs are placed in MAKEMKV_OUTPUT/<movie-folder>/
  - Move or symlink MKVs to Tdarr watch folder for transcoding
  - Original ISOs can be deleted after successful transcode
EOF
            ;;
        "")
            check_container || exit 1
            process_all
            ;;
        *)
            if [[ -f "$1" && "$1" == *.iso ]]; then
                check_container || exit 1
                process_iso "$1"
            else
                log_error "Invalid argument: $1"
                log "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
}

main "$@"
