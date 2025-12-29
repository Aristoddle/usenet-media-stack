#!/usr/bin/env bash
# migrate-readarr-to-bookshelf.sh
# Safely migrate from retired Readarr to Bookshelf fork
#
# Readarr was officially retired June 27, 2025
# Bookshelf is the actively maintained fork with Hardcover metadata support
#
# USAGE:
#   ./tools/migrate-readarr-to-bookshelf.sh [--dry-run]
#
# ROLLBACK:
#   1. Restore docker-compose.yml.readarr-backup
#   2. docker compose up -d readarr
#   3. If config corrupted, restore from config/readarr-backup-YYYYMMDD/

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_ROOT="${CONFIG_ROOT:-/var/mnt/fast8tb/config}"
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Parse args
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    log "DRY RUN MODE - No changes will be made"
fi

cd "$PROJECT_DIR"

# Step 1: Pre-flight checks
log "Step 1: Pre-flight checks"

if ! docker ps | grep -q readarr; then
    warn "Readarr container not running - may already be migrated"
fi

if ! docker image inspect ghcr.io/pennydreadful/bookshelf:hardcover &>/dev/null; then
    log "Pulling Bookshelf image..."
    if [[ "$DRY_RUN" == "false" ]]; then
        docker pull ghcr.io/pennydreadful/bookshelf:hardcover
    else
        echo "  [DRY RUN] Would pull ghcr.io/pennydreadful/bookshelf:hardcover"
    fi
fi

# Step 2: Backup current config
log "Step 2: Backing up Readarr config"
BACKUP_DIR="${CONFIG_ROOT}/readarr-backup-${BACKUP_DATE}"

if [[ "$DRY_RUN" == "false" ]]; then
    if [[ -d "${CONFIG_ROOT}/readarr" ]]; then
        cp -a "${CONFIG_ROOT}/readarr" "$BACKUP_DIR"
        log "  Config backed up to: $BACKUP_DIR"
    else
        warn "  No Readarr config directory found at ${CONFIG_ROOT}/readarr"
    fi

    # Backup docker-compose.yml
    cp docker-compose.yml "docker-compose.yml.readarr-backup-${BACKUP_DATE}"
    log "  docker-compose.yml backed up"
else
    echo "  [DRY RUN] Would backup ${CONFIG_ROOT}/readarr to $BACKUP_DIR"
    echo "  [DRY RUN] Would backup docker-compose.yml"
fi

# Step 3: Stop Readarr
log "Step 3: Stopping Readarr container"
if [[ "$DRY_RUN" == "false" ]]; then
    docker compose stop readarr 2>/dev/null || true
    log "  Readarr stopped"
else
    echo "  [DRY RUN] Would stop readarr container"
fi

# Step 4: Update docker-compose.yml
log "Step 4: Updating docker-compose.yml image reference"

if [[ "$DRY_RUN" == "false" ]]; then
    # Use sed to replace the image line
    sed -i 's|image: linuxserver/readarr:develop-0.4.18.2805-ls157|image: ghcr.io/pennydreadful/bookshelf:hardcover|g' docker-compose.yml

    # Also update container name and hostname for clarity
    sed -i 's|container_name: readarr|container_name: bookshelf|g' docker-compose.yml
    sed -i 's|hostname: readarr|hostname: bookshelf|g' docker-compose.yml

    log "  Image updated to ghcr.io/pennydreadful/bookshelf:hardcover"
    log "  Container renamed to bookshelf"
else
    echo "  [DRY RUN] Would replace:"
    echo "    linuxserver/readarr:develop-0.4.18.2805-ls157"
    echo "  With:"
    echo "    ghcr.io/pennydreadful/bookshelf:hardcover"
fi

# Step 5: Start Bookshelf
log "Step 5: Starting Bookshelf container"
if [[ "$DRY_RUN" == "false" ]]; then
    docker compose up -d bookshelf
    log "  Bookshelf started"
else
    echo "  [DRY RUN] Would run: docker compose up -d bookshelf"
fi

# Step 6: Verify
log "Step 6: Verification"
if [[ "$DRY_RUN" == "false" ]]; then
    sleep 5
    if docker ps | grep -q bookshelf; then
        log "  Bookshelf container is running"

        # Check if web UI is accessible
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8787 | grep -q "200\|302"; then
            log "  Web UI accessible at http://localhost:8787"
        else
            warn "  Web UI not yet accessible (may still be initializing)"
        fi
    else
        error "  Bookshelf container failed to start!"
        error "  Check logs: docker logs bookshelf"
        exit 1
    fi
else
    echo "  [DRY RUN] Would verify container is running"
fi

# Summary
echo ""
log "Migration complete!"
echo ""
echo "NEXT STEPS:"
echo "  1. Access Bookshelf at http://localhost:8787"
echo "  2. Verify your library and settings imported correctly"
echo "  3. Configure Hardcover metadata provider (Settings -> Metadata)"
echo "  4. Update Prowlarr app connection if needed"
echo ""
echo "ROLLBACK (if needed):"
echo "  1. docker compose stop bookshelf"
echo "  2. cp docker-compose.yml.readarr-backup-${BACKUP_DATE} docker-compose.yml"
echo "  3. cp -a $BACKUP_DIR ${CONFIG_ROOT}/readarr"
echo "  4. docker compose up -d readarr"
