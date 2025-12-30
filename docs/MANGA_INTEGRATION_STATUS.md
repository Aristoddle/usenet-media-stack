# Manga Integration Status

Current state of manga acquisition and serving stack.

**Last Updated**: 2025-12-30

---

## Component Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Mylar** | Running | Port 8090, 82 series monitored |
| **Prowlarr Integration** | Wired | fullSync, Comics category (7000) - FIXED 12/29 |
| **SABnzbd** | Running | Receives downloads via Prowlarr |
| **Komga Library** | Running | Port 8081, hourly scans |
| **Komf Metadata** | Partial | Running but 0% coverage (0/17200 files) |
| **Suwayomi** | Running | Chapter downloads to Manga subfolder |
| **Post-Download Automation** | Missing | Manual step required SABnzbd -> Comics |
| **Weekly Chapter Acquisition** | Not Wired | Agent exists, not integrated with stack |
| **Collection Naming** | Pending | 97% non-compliant, remediation spec complete |

---

## Recent Fixes (2025-12-29)

- **Prowlarr Category**: Fixed from 7030 to 7000 for Mylar compatibility
- **Suwayomi Organizer**: Created `tools/suwayomi-organizer.sh` for chapter organization
- **Manga Topology**: Documented in `docs/MANGA_COLLECTION_TOPOLOGY.md`
- **Adversarial Review**: Completed - see `docs/decisions/2025-12-29-manga-topology-adversarial-review.md`

---

## Critical Gaps

### 1. No Metadata Coverage (HIGH)
- **Issue**: 0/17,200 files have ComicInfo.xml
- **Impact**: No covers, descriptions, dates in readers
- **Solution**: Run metadata enrichment after naming remediation
- **Target**: >90% ComicInfo.xml coverage

### 2. No Post-Download Automation (MEDIUM)
- **Issue**: Files land in `/downloads` but require manual move
- **Impact**: Mylar acquisitions don't automatically appear in Komga
- **Solution**: Create file watcher + organizer between SABnzbd and Comics root

### 3. Collection Remediation Pending (MEDIUM)
- **Issue**: 97% of files non-compliant with target naming pattern
- **Scope**: 79 series, ~17,667 files, 311 __Panels directories
- **Timeline**: 33-35 hours automated work + human review
- **Status**: MANGA_REMEDIATION_SWARM.md design complete, awaiting implementation

### 4. Weekly Chapter Acquisition Not Wired (LOW)
- **Issue**: Track 2 (weekly chapters) relies on manga-torrent-searcher agent
- **Status**: Agent documented but not integrated with docker-compose

---

## Acquisition Pipeline

```
Mylar (Port 8090)
    |
Prowlarr (Port 9696) - indexer aggregation, category 7000
    |
SABnzbd (Port 8080) - Usenet downloads
    |
[Downloads directory] <- GAP: Manual organization required
    |
[Comics root]
    |
Komga (Port 8081) - Library scanning
    |
Komf (Port 8085) - Metadata enrichment <- GAP: 0% coverage
```

---

## Tools Available

| Tool | Location | Purpose |
|------|----------|---------|
| suwayomi-organizer.sh | tools/ | Organize Suwayomi downloads for Komga |
| flatten-manga.sh | tools/ | Flatten nested manga directories |
| mylar-post-processor.sh | tools/ | Post-download processing |
| komga-collection-sync.sh | tools/ | Sync collections to Komga |

---

## Recommended Actions

### Immediate (Before Next Session)
1. **Validation**: Test Mylar-Prowlarr connection with new category (7000)
2. **Test Flow**: Try downloading one manga volume through full pipeline

### Short-Term
1. Create post-download file organizer (SABnzbd -> Comics -> Komga rescan)
2. Execute MANGA_REMEDIATION_SWARM.md Phase 0-2 (naming standardization)

### Medium-Term
1. Run Komf metadata enrichment on standardized collection
2. Wire manga-torrent-searcher agent for weekly chapter automation

---

## Related Documentation

- [Manga Acquisition Pipeline](MANGA_ACQUISITION_PIPELINE.md) - Two-track system overview
- [Manga Collection Topology](MANGA_COLLECTION_TOPOLOGY.md) - Folder structure
- [Manga Ecosystem Analysis](MANGA_ECOSYSTEM_ANALYSIS.md) - Complete tooling analysis
- [Manga Naming Migration Plan](MANGA_NAMING_MIGRATION_PLAN.md) - Standardization plan
- [Manga Remediation Swarm](archive/projects/MANGA_REMEDIATION_SWARM.md) - Multi-agent remediation spec

---

*Generated: 2025-12-30*
