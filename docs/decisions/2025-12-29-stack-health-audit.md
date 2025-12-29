# Decision: Stack Health Audit - Service Maintenance Status & Readarr Retirement

**Date**: 2025-12-29
**Status**: Accepted
**Deciders**: User, deep-thinker agent
**Consulted**: Web research (GitHub, Servarr Wiki, LinuxServer.io)

## Context

User noticed Readarr in the docker-compose stack and questioned whether it was deprecated/EOL. This prompted a comprehensive audit of all services in the stack to identify:
1. Deprecated or retired services requiring replacement
2. Services with questionable maintenance status
3. Configuration issues (specifically Prowlarr category sync for Mylar)
4. Security concerns from running unmaintained software

## Executive Summary

**CRITICAL FINDING**: Readarr was officially retired on June 27, 2025. The current pinned image (`linuxserver/readarr:develop-0.4.18.2805-ls157`) is unmaintained and should be replaced.

**Stack Health**: 26 of 27 services are actively maintained. Only Readarr requires immediate action.

**Category Configuration Issue**: The Prowlarr-to-Mylar category sync using 7030 may be causing 0 search results. Analysis suggests using broader category 7000 (all Books) is more reliable.

---

## Service Audit Results

### TIER 1: DEPRECATED/RETIRED - IMMEDIATE ACTION REQUIRED

| Service | Status | Action | Alternative |
|---------|--------|--------|-------------|
| **Readarr** | **RETIRED** (June 27, 2025) | **REPLACE IMMEDIATELY** | Bookshelf (fork) or rreading-glasses |

**Details - Readarr Retirement**:
- GitHub repository archived on June 27, 2025 (read-only)
- LinuxServer.io deprecated the Docker image
- Reasons: Metadata service became unusable, lack of developers
- The pinned version `develop-0.4.18.2805-ls157` will receive no security updates

**Recommended Replacement - Bookshelf**:
```yaml
readarr:  # REPLACE WITH:
bookshelf:
  image: ghcr.io/pennydreadful/bookshelf:hardcover  # or :softcover for Goodreads
  container_name: bookshelf
  # ... (same volume/port configuration as Readarr)
```

**Benefits of Bookshelf**:
- Active development (fork maintained by pennydreadful)
- Hardcover metadata support (better quality than defunct Readarr metadata)
- Native MyAnonaMouse support without Prowlarr
- Backward-compatible with existing Readarr databases
- Removed Servarr analytics

**Alternative - rreading-glasses**:
- Drop-in metadata service replacement
- Works with existing Readarr installation
- ~7000 daily users as of August 2025
- Lower migration effort but keeps unmaintained codebase

---

### TIER 2: ACTIVELY MAINTAINED - NO ACTION REQUIRED

| Service | Container | Status | Last Activity | Notes |
|---------|-----------|--------|---------------|-------|
| **Sonarr** | linuxserver/sonarr | Active | Dec 2025 | Core Servarr, funded & maintained |
| **Radarr** | linuxserver/radarr | Active | Dec 2025 | Core Servarr, funded & maintained |
| **Prowlarr** | linuxserver/prowlarr | Active | Dec 2025 | Core Servarr indexer manager |
| **Lidarr** | linuxserver/lidarr | Active | Dec 2025 | v3.1.1.4876 (Nov 2025), metadata server issues noted |
| **Bazarr** | linuxserver/bazarr | Active | Dec 2025 | Subtitle companion, actively maintained |
| **Whisparr** | thespad/whisparr | Active | Nov 2025 | Adult content *arr, v3 recommended |
| **SABnzbd** | linuxserver/sabnzbd | Active | Dec 2025 | Primary Usenet downloader |
| **Transmission** | linuxserver/transmission | Active | Dec 2025 | Torrent fallback client |
| **Plex** | linuxserver/plex | Active | Dec 2025 | Commercial product, well-maintained |
| **Tautulli** | linuxserver/tautulli | Active | Dec 2025 | Plex monitoring |
| **Overseerr** | linuxserver/overseerr | Active | Dec 2025 | Request management |
| **Recyclarr** | recyclarr/recyclarr | Active | Dec 2025 | v7.5.2, TRaSH guide sync |
| **Tdarr** | haveagitgat/tdarr | Active | Nov 2025 | v2.58.02, transcoding automation |
| **Tdarr-node** | haveagitgat/tdarr_node | Active | Nov 2025 | Secondary transcoding node |
| **Mylar3** | linuxserver/mylar3 | Active | Dec 2025 | Comics, 2025 pull-list updates |
| **Komga** | gotson/komga | Active | Dec 2025 | v1.23.6, manga/comics server |
| **Komf** | sndxr/komf | Active | Dec 2025 | v1.3.0, metadata fetcher |
| **Kavita** | jvmilazz0/kavita | Active | Dec 2025 | Ebook reader, beta active dev |
| **Suwayomi** | suwayomi/suwayomi-server | Active | Dec 2025 | Manga reader, Tachiyomi extensions |
| **Audiobookshelf** | advplyr/audiobookshelf | Active | Dec 2025 | Audiobook/podcast server |
| **Stash** | stashapp/stash | Active | Dec 2025 | Adult content organizer |
| **Portainer** | portainer/portainer-ce | Active | Dec 2025 | Container management |
| **Uptime Kuma** | louislam/uptime-kuma | Active | Dec 2025 | Monitoring |
| **Netdata** | netdata/netdata | Active | Dec 2025 | System monitoring |
| **Samba** | servercontainers/samba | Active | Dec 2025 | File sharing |
| **Aria2** | custom build | N/A | Local | DDL client, custom Dockerfile |

---

### TIER 3: DISABLED/OPTIONAL SERVICES

| Service | Replicas | Notes |
|---------|----------|-------|
| **NFS Server** | 0 | Disabled, available if needed |
| **Docs (nginx)** | 0 | Disabled, local VitePress docs |

---

## Prowlarr Category Configuration Analysis

### The Problem

User reports Prowlarr syncing category **7030** (Books/Comics) to Mylar returns **0 search results**.

### Root Cause Analysis

**Newznab Category Hierarchy (7000 - Books)**:

| Category ID | Name | Description |
|-------------|------|-------------|
| 7000 | Books | Parent category (all books) |
| 7010 | Books/Ebook | General ebooks |
| 7020 | Books/Comics | Comics specifically |
| 7030 | Books/Magazines | Magazines |
| 7040 | Books/Technical | Technical books |
| 7060 | Books/Foreign | Non-English books |

**CRITICAL INSIGHT**: The standard Newznab spec defines **7020** as Comics, **NOT 7030**.

Some indexer implementations vary:
- Older Newznab: 7030 = Comics (non-standard)
- Modern Newznab: 7020 = Comics (standard)
- Some indexers: Don't categorize comics at all, put them in 7010 (Ebook)

### Recommended Solution

**Option A (Broader search - Recommended)**:
```
Prowlarr -> Mylar sync categories: 7000
```
This includes ALL book subcategories, catching comics regardless of how indexers categorize them.

**Option B (Specific categories)**:
```
Prowlarr -> Mylar sync categories: 7020,7010
```
Includes both Comics (7020) and Ebooks (7010) to catch miscategorized items.

### Manga-Specific Considerations

**Manga has no dedicated Newznab category**. Manga content appears in:
- 7020 (Comics) - when treated as comic format
- 7010 (Ebook) - when treated as digital publication
- 5070 (TV/Anime) - if it's anime video content

**For manga acquisition via Usenet**:
1. Use Mylar3 with category 7000 (broadest coverage)
2. Configure multiple indexers in Prowlarr
3. Consider Suwayomi for scanlation sources (already in stack)
4. Torrent fallback via Transmission for rare content

---

## Security Considerations

### Running Unmaintained Software Risks

**Readarr (CRITICAL)**:
- No security patches since June 2025
- Known vulnerabilities will remain unpatched
- API keys and credentials stored in unmaintained codebase
- Potential attack vector if exposed to network

**Mitigation Actions**:
1. Replace Readarr with Bookshelf immediately
2. If delayed, isolate container network access
3. Review firewall rules for port 8787
4. Rotate API keys after migration

### General Security Notes

All other services are actively maintained. Key security practices:
- Keep images updated (`docker compose pull`)
- Use LinuxServer.io images when available (security-focused)
- Avoid exposing *arr services to public internet without auth proxy

---

## Implementation Plan

### Phase 1: Readarr Replacement (Priority: CRITICAL)

**Timeline**: Immediate (within 1 week)

1. **Backup Readarr database**:
   ```bash
   cp -r ${CONFIG_ROOT}/readarr ${CONFIG_ROOT}/readarr-backup-$(date +%Y%m%d)
   ```

2. **Update docker-compose.yml**:
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
       - ${CONFIG_ROOT:-/srv/usenet/config}/readarr:/config:rw,z  # Uses existing config
       - ${DOWNLOADS_ROOT:-/srv/usenet/downloads}:/downloads:rw,z
       - ${EBOOKS_ROOT:-/srv/usenet/books/eBooks}:/books:rw,z
       - ${BOOKS_ROOT:-/srv/usenet/books}:/books-all:rw,z
       - ${POOL_ROOT:-/var/mnt/pool}:/pool:rw,z
     ports:
       - 8787:8787
     restart: unless-stopped
     # ... (same resource limits)
   ```

3. **Test migration**:
   ```bash
   docker compose up -d bookshelf
   # Verify web UI at http://localhost:8787
   # Check existing library imports correctly
   ```

4. **Update Prowlarr application sync** (if configured)

### Phase 2: Prowlarr Category Fix (Priority: HIGH)

**Timeline**: After Readarr replacement

1. Open Prowlarr UI: http://localhost:9696
2. Navigate to Settings -> Apps -> Mylar
3. Update sync categories from `7030` to `7000` (or `7020,7010`)
4. Test search in Mylar for a known comic title

### Phase 3: Ongoing Maintenance (Priority: MEDIUM)

**Monthly tasks**:
- `docker compose pull` to update images
- Check GitHub releases for breaking changes
- Monitor Servarr Wiki for deprecation notices

---

## Validation Criteria

- [ ] Readarr container replaced with Bookshelf
- [ ] Existing ebook library accessible in Bookshelf
- [ ] Bookshelf connected to SABnzbd/Transmission
- [ ] Prowlarr syncing categories correctly to Mylar
- [ ] Mylar searches return results for comics
- [ ] No unmaintained containers in `docker ps`

---

## References

### Readarr Retirement
- [LinuxServer.io Deprecation Notice (2025-06-27)](https://info.linuxserver.io/issues/2025-06-27-readarr/)
- [Servarr Wiki - Readarr Status (Retired)](https://wiki.servarr.com/readarr/status)
- [GitHub - Readarr/Readarr (Archived)](https://github.com/Readarr/Readarr)
- [LinuxServer.io Deprecated Images - Readarr](https://docs.linuxserver.io/deprecated_images/docker-readarr/)

### Bookshelf (Readarr Fork)
- [GitHub - pennydreadful/bookshelf](https://github.com/pennydreadful/bookshelf)
- [Docker Package - bookshelf](https://github.com/pennydreadful/bookshelf/pkgs/container/bookshelf)
- [Ultra.CC Feedback - Bookshelf](https://feedback.ultra.cc/p/readarr-is-dead-long-live-readarr)

### rreading-glasses (Alternative)
- [GitHub - blampe/rreading-glasses](https://github.com/blampe/rreading-glasses)
- [Ultra.CC Feedback - rreading-glasses](https://feedback.ultra.cc/p/rreading-glasses-readarr-replacement)

### Newznab Categories
- [Newznab API Categories](https://inhies.github.io/Newznab-API/categories/)
- [Jackett Categories (reference)](https://github.com/Jackett/Jackett/wiki/Jackett-Categories)
- [Mylar Issue #596 - Category Discussion](https://github.com/evilhero/mylar/issues/596)

### Prowlarr + Mylar Integration
- [MediaStack Guide - Prowlarr](https://mediastack.guide/config/prowlarr/)
- [Mylar Forum - Prowlarr Integration](https://forum.mylarcomics.com/viewtopic.php?t=2459)

### Service Status Pages
- [Servarr Wiki](https://wiki.servarr.com/)
- [Mylar3 GitHub](https://github.com/mylar3/mylar3)
- [Komga Official](https://komga.org/)
- [Kavita Reader](https://www.kavitareader.com/)
- [Suwayomi GitHub](https://github.com/Suwayomi/Suwayomi-Server)
- [Audiobookshelf](https://www.audiobookshelf.org/)
- [Tdarr](https://home.tdarr.io/)
- [Stash GitHub](https://github.com/stashapp/stash)

---

## Appendix: Complete Service Inventory

**Total Services in docker-compose.yml**: 27

**By Category**:
- Media Automation (*arr): Sonarr, Radarr, Prowlarr, Lidarr, Bazarr, Whisparr, ~~Readarr~~ Bookshelf, Mylar3, Recyclarr
- Download Clients: SABnzbd, Transmission, Aria2
- Media Servers: Plex, Stash
- Book/Comic Readers: Komga, Kavita, Suwayomi, Audiobookshelf
- Metadata: Komf
- Transcoding: Tdarr, Tdarr-node
- Request/Monitoring: Overseerr, Tautulli, Uptime Kuma, Netdata
- Infrastructure: Portainer, Samba, NFS Server (disabled), Docs (disabled)

---

**Document Version**: 1.0.0
**Last Updated**: 2025-12-29
**Next Review**: 2026-03-29 (quarterly)
