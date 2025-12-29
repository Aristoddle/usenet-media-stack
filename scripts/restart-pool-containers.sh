#!/bin/bash
# restart-pool-containers.sh - Restart all containers that depend on MergerFS pool
#
# Run this after MergerFS (re)mounts to fix stale FUSE mount references.
# Can be called manually or by systemd after mergerfs-pool.service starts.
#
# Usage:
#   ./restart-pool-containers.sh           # Restart all pool-dependent containers
#   ./restart-pool-containers.sh --check   # Only check mount status, don't restart

set -euo pipefail

COMPOSE_FILE="/var/home/deck/Documents/Code/media-automation/usenet-media-stack/docker-compose.yml"
LOG_PREFIX="[pool-containers]"

# Determine if we need sudo (systemd runs as root, manual runs as user)
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        echo "ERROR: Cannot access Docker daemon"
        exit 1
    fi
fi

# Containers that mount from /var/mnt/pool
POOL_CONTAINERS=(
    "sabnzbd"
    "transmission"
    "tdarr"
    "tdarr-node"
    "radarr"
    "sonarr"
    "lidarr"
    "bazarr"
    "whisparr"
    "plex"
    "komga"
    "kavita"
    "audiobookshelf"
    "mylar"
    "stash"
)

log() {
    echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') $*"
}

check_pool_mounted() {
    if mount | grep -q "mergerfs-pool on /var/mnt/pool"; then
        return 0
    else
        return 1
    fi
}

check_container_mount() {
    local container="$1"
    # Check if container can access common pool/media paths
    # Different containers mount different paths, so check several
    local paths=("/downloads" "/pool" "/movies" "/tv" "/anime-tv" "/comics" "/data")

    for path in "${paths[@]}"; do
        if $DOCKER_CMD exec "$container" ls "$path" >/dev/null 2>&1; then
            echo "ok"
            return 0
        fi
    done

    # If none of the paths work, check if the failure is "no such file" vs "socket not connected"
    # "Socket not connected" indicates stale FUSE mount
    local err=$($DOCKER_CMD exec "$container" ls /downloads 2>&1 || true)
    if echo "$err" | grep -qi "socket not connected\|transport endpoint\|stale"; then
        echo "stale"
    else
        # No error or just "no such file" - container is fine, just doesn't have that path
        echo "ok"
    fi
}

if [[ "${1:-}" == "--check" ]]; then
    log "Checking pool mount status..."

    if ! check_pool_mounted; then
        log "ERROR: MergerFS pool is NOT mounted!"
        exit 1
    fi

    log "Pool mounted. Checking containers..."

    stale_count=0
    for container in "${POOL_CONTAINERS[@]}"; do
        # Check if container is running (match exact name or _name suffix)
        if $DOCKER_CMD ps --format '{{.Names}}' | grep -qE "(^|_)${container}$"; then
            actual_name=$($DOCKER_CMD ps --format '{{.Names}}' | grep -E "(^|_)${container}$" | head -1)
            status=$(check_container_mount "$actual_name" 2>/dev/null || echo "error")

            if [[ "$status" == "stale" ]]; then
                log "  $container: STALE MOUNT - needs restart"
                ((stale_count++))
            elif [[ "$status" == "error" ]]; then
                log "  $container: ERROR checking mount"
            else
                log "  $container: OK"
            fi
        else
            log "  $container: not running"
        fi
    done

    if [[ $stale_count -gt 0 ]]; then
        log "Found $stale_count containers with stale mounts. Run without --check to fix."
        exit 1
    else
        log "All running containers have valid mounts."
        exit 0
    fi
fi

# Main restart logic
log "Starting pool container restart..."

if ! check_pool_mounted; then
    log "ERROR: MergerFS pool is not mounted! Aborting."
    exit 1
fi

log "MergerFS pool is mounted. Restarting containers..."

cd "$(dirname "$COMPOSE_FILE")"

# Use sudo for docker compose if needed
COMPOSE_CMD="docker compose"
if [[ "$DOCKER_CMD" == "sudo docker" ]]; then
    COMPOSE_CMD="sudo docker compose"
fi

# Restart containers in groups for efficiency
$COMPOSE_CMD restart sabnzbd transmission 2>&1 | while read line; do log "  $line"; done
$COMPOSE_CMD restart tdarr tdarr-node 2>&1 | while read line; do log "  $line"; done
$COMPOSE_CMD restart radarr sonarr lidarr bazarr 2>&1 | while read line; do log "  $line"; done
$COMPOSE_CMD restart plex 2>&1 | while read line; do log "  $line"; done
$COMPOSE_CMD restart komga kavita audiobookshelf mylar 2>&1 | while read line; do log "  $line"; done

# Optionally restart stash and whisparr if they exist
$COMPOSE_CMD restart whisparr 2>&1 | while read line; do log "  $line"; done || true
$COMPOSE_CMD restart stash 2>&1 | while read line; do log "  $line"; done || true

log "All pool-dependent containers restarted."
log "Verifying mounts..."

sleep 5

# Quick verification
stale_count=0
for container in sabnzbd tdarr-node plex; do
    actual_name=$($DOCKER_CMD ps --format '{{.Names}}' | grep -E "(^|_)${container}$" | head -1)
    if [[ -n "$actual_name" ]]; then
        status=$(check_container_mount "$actual_name" 2>/dev/null || echo "error")
        if [[ "$status" != "ok" ]]; then
            log "  WARNING: $container still has stale mount!"
            ((stale_count++))
        fi
    fi
done

if [[ $stale_count -eq 0 ]]; then
    log "✓ All containers verified with healthy mounts."
else
    log "WARNING: $stale_count containers still have issues. Check manually."
fi
