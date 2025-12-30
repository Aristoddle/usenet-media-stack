# Decision: Migrate from Readarr to Bookshelf

**Date**: 2025-12-30
**Status**: Proposed
**Deciders**: User, deep-thinker agent
**Consulted**: Web research (GitHub, ghcr.io package registry)

## Context

Readarr was officially retired on June 27, 2025. The LinuxServer.io Docker image was deprecated and archived. The current stack runs a pinned unmaintained image (`linuxserver/readarr:develop-0.4.18.2805-ls157`).

**Current State Analysis** (per 2025-12-29 stack health audit):
- Container: DISABLED (not running)
- Database: EMPTY (0 authors, 0 books)
- Security: Authentication was disabled (vulnerability if exposed)
- Migration complexity: TRIVIAL (no data to preserve)

## Decision

Replace Readarr with [Bookshelf](https://github.com/pennydreadful/bookshelf) (the actively-maintained community fork).

**Why Bookshelf over alternatives**:
| Option | Pros | Cons |
|--------|------|------|
| **Bookshelf** | Active fork, Hardcover/Goodreads metadata, backward-compatible | Newer project |
| rreading-glasses | Minimal change, drop-in proxy | Keeps unmaintained Readarr codebase |
| Manual acquisition | Zero containers | No automation, no monitoring |

Bookshelf wins because it provides active development, proper metadata sources, and the empty database makes this a fresh start anyway.

---

## Docker-Compose Changes

### Current Configuration (Lines 461-497)

```yaml
readarr:
  <<: *network_tweaks
  image: linuxserver/readarr:develop-0.4.18.2805-ls157
  container_name: readarr
  hostname: readarr
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=Etc/UTC
  volumes:
    - ${CONFIG_ROOT:-/srv/usenet/config}/readarr:/config:rw,z
    - ${DOWNLOADS_ROOT:-/srv/usenet/downloads}:/downloads:rw,z
    - ${EBOOKS_ROOT:-/srv/usenet/books/eBooks}:/books:rw,z
    - ${BOOKS_ROOT:-/srv/usenet/books}:/books-all:rw,z
    - ${POOL_ROOT:-/var/mnt/pool}:/pool:rw,z
  ports:
    - 8787:8787
  # ... rest of config
```

### New Configuration

```yaml
bookshelf:
  <<: *network_tweaks
  image: ghcr.io/pennydreadful/bookshelf:hardcover
  container_name: bookshelf
  hostname: bookshelf
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=Etc/UTC
  volumes:
    - ${CONFIG_ROOT:-/srv/usenet/config}/bookshelf:/config:rw,z
    - ${DOWNLOADS_ROOT:-/srv/usenet/downloads}:/downloads:rw,z
    - ${EBOOKS_ROOT:-/srv/usenet/books/eBooks}:/books:rw,z
    - ${BOOKS_ROOT:-/srv/usenet/books}:/books-all:rw,z
    - ${POOL_ROOT:-/var/mnt/pool}:/pool:rw,z
  ports:
    - 8787:8787
  restart: unless-stopped
  deploy:
    mode: replicated
    replicas: 1
    placement:
      constraints:
        - node.labels.storage == true
    resources:
      limits:
        cpus: '1.0'
        memory: 1G
      reservations:
        cpus: '0.25'
        memory: 256M
  depends_on:
    - sabnzbd
    - transmission
  logging:
    driver: json-file
    options: *id002
```

### Key Changes Summary

| Aspect | Old (Readarr) | New (Bookshelf) |
|--------|---------------|-----------------|
| Image | `linuxserver/readarr:develop-0.4.18.2805-ls157` | `ghcr.io/pennydreadful/bookshelf:hardcover` |
| Container name | `readarr` | `bookshelf` |
| Config path | `/config/readarr` | `/config/bookshelf` |
| Port | 8787 | 8787 (unchanged) |
| Metadata source | Defunct | Hardcover (or `:softcover` for Goodreads) |

### Image Tag Options

| Tag | Metadata Source | Use Case |
|-----|-----------------|----------|
| `hardcover` | Hardcover.app | Recommended - better metadata quality |
| `hardcover-v0.4.20.91` | Hardcover.app | Pinned version for stability |
| `softcover` | Goodreads | Drop-in Readarr compatibility |
| `softcover-v0.4.20.91` | Goodreads | Pinned Goodreads version |

---

## Prowlarr App Sync Updates

### Remove Old Readarr Connection

1. Open Prowlarr: http://192.168.6.167:9696
2. Go to **Settings** > **Apps**
3. Find and DELETE the Readarr application entry (if present)

### Add Bookshelf Connection

1. **Settings** > **Apps** > **+** > **Readarr** (Bookshelf uses same API)
2. Configure:
   - **Name**: Bookshelf
   - **Sync Level**: Full Sync
   - **Prowlarr Server**: http://prowlarr:9696
   - **Readarr Server**: http://bookshelf:8787
   - **API Key**: (get from Bookshelf Settings > General)
3. Test and Save

### Category Mapping

Ensure indexers sync with category **7000** (Books - All) for broad coverage:
- 7010: EBook
- 7020: Comics
- 7030: Magazines
- 7040: Technical
- 7050: Audiobook

---

## Pre-Migration Checklist

- [ ] **Verify Readarr is stopped**: `podman ps | grep readarr` (should return nothing)
- [ ] **Confirm empty database**: No authors/books to migrate (already verified)
- [ ] **Backup config directory** (optional, but good practice):
  ```bash
  cp -r /srv/usenet/config/readarr /srv/usenet/config/readarr.bak.$(date +%Y%m%d)
  ```
- [ ] **Pull new image**:
  ```bash
  podman pull ghcr.io/pennydreadful/bookshelf:hardcover
  ```
- [ ] **Remove Prowlarr Readarr sync** (if exists) to prevent API errors during transition

---

## Migration Steps

```bash
# 1. Stop and remove old container (if running)
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack
podman-compose stop readarr 2>/dev/null || true
podman-compose rm -f readarr 2>/dev/null || true

# 2. Create fresh config directory for Bookshelf
mkdir -p /srv/usenet/config/bookshelf

# 3. Update docker-compose.yml (see configuration above)
# Edit the readarr service to bookshelf

# 4. Start Bookshelf
podman-compose up -d bookshelf

# 5. Verify startup
podman logs -f bookshelf
```

---

## Post-Migration Validation

### Container Health

```bash
# Check container is running
podman ps --filter name=bookshelf

# Verify port binding
curl -s http://localhost:8787/ping && echo "OK"

# Check logs for errors
podman logs bookshelf --tail 50 | grep -i error
```

### Web UI Validation

1. Open http://192.168.6.167:8787
2. Complete initial setup wizard:
   - Set authentication (Forms or Basic - DO NOT disable)
   - Configure root folder: `/books` or `/pool/books`
   - Add download clients (SABnzbd, Transmission)
3. Verify metadata source shows "Hardcover" in Settings > Metadata

### Prowlarr Integration

1. Add Bookshelf in Prowlarr Apps (see above)
2. Run **Sync App Indexers** in Prowlarr
3. Verify Bookshelf shows indexers in Settings > Indexers

### Functional Test

1. Search for a known book (e.g., "Project Hail Mary")
2. Verify results appear from indexers
3. Test download queue integration (grab a free/test item)

---

## Rollback Plan

If Bookshelf fails to work:

```bash
# 1. Stop Bookshelf
podman-compose stop bookshelf

# 2. Revert docker-compose.yml to Readarr config
# (restore from git or backup)

# 3. Restart old Readarr (note: still deprecated/insecure)
podman-compose up -d readarr
```

**Alternative**: If neither Readarr nor Bookshelf work, use manual acquisition through Prowlarr direct search + SABnzbd for books until a solution stabilizes.

---

## Security Improvements

This migration addresses the security finding from the 2025-12-29 audit:

| Issue | Old State | New State |
|-------|-----------|-----------|
| Authentication | Disabled | Enabled (required during setup) |
| Software updates | Abandoned | Active development |
| Metadata API | Defunct/unreliable | Hardcover (active) |

**Post-migration security checklist**:
- [ ] Authentication enabled (Forms recommended)
- [ ] API key generated and not shared publicly
- [ ] Container not exposed beyond LAN (verify firewall)

---

## References

- [Bookshelf GitHub Repository](https://github.com/pennydreadful/bookshelf)
- [Bookshelf Docker Package](https://github.com/pennydreadful/bookshelf/pkgs/container/bookshelf)
- [LinuxServer Readarr Deprecation Notice](https://docs.linuxserver.io/deprecated_images/docker-readarr/)
- Previous decision: [2025-12-29-stack-health-audit.md](./2025-12-29-stack-health-audit.md)
