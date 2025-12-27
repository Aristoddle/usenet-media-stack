# Manga Acquisition Pipeline

This documents the two-track system for acquiring manga content, balancing archival quality with staying current on ongoing series.

## Two-Track Manga Acquisition System

### Track 1: Tankobon Volumes (Mylar)

| Attribute | Value |
|-----------|-------|
| **Tool** | Mylar (port 8090) |
| **Source** | ComicVine metadata + Usenet/Prowlarr indexers |
| **What it tracks** | Published tankobon (collected volumes) |
| **Format** | CBZ files, official English releases (Viz, Kodansha, etc.) |
| **Typical delay** | 3-6 months after Japanese release |
| **Best for** | Completed series, official translations, archival quality |

### Track 2: Weekly Chapters (manga-torrent-searcher agent)

| Attribute | Value |
|-----------|-------|
| **Tool** | manga-torrent-searcher agent + Transmission/Nyaa |
| **Source** | Nyaa.si, AniDex, fan translations |
| **What it tracks** | Weekly/monthly chapter releases as they drop |
| **Format** | Individual chapters, scanlations |
| **Delay** | Same-day to 1 week after Japanese release |
| **Best for** | Ongoing series, staying current, series without official English |

## When to Use Which Track

| Use Case | Track |
|----------|-------|
| Series you want to **READ NOW** | Track 2 (Weekly chapters) |
| Series you want to **ARCHIVE** in best quality | Track 1 (Tankobon) |
| Ongoing active reads | Both tracks |

## Configured Series

### Track 1: Mylar Tankobon Monitoring

All 82 series in `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/` are monitored for tankobon releases via Mylar.

### Track 2: Weekly Chapter Monitoring

Currently tracked via `manga-torrent-searcher` agent:
- Chainsaw Man
- Kagurabachi
- Dandadan
- Bug Ego

## API Reference

### Mylar API

**Base URL:** `http://localhost:8090/api?apikey=cad4f40858c77c4177c99bebae4f3e17`

| Endpoint | Description |
|----------|-------------|
| `findComic&name=X` | Search ComicVine for series |
| `addComic&id=X` | Add series by ComicVine ID |
| `getIndex` | List all tracked series |
| `forceSearch&id=X` | Trigger download search for series |

### Example API Calls

```bash
# Search for a series
curl "http://localhost:8090/api?apikey=cad4f40858c77c4177c99bebae4f3e17&cmd=findComic&name=Chainsaw%20Man"

# List all monitored series
curl "http://localhost:8090/api?apikey=cad4f40858c77c4177c99bebae4f3e17&cmd=getIndex"

# Force search for new releases
curl "http://localhost:8090/api?apikey=cad4f40858c77c4177c99bebae4f3e17&cmd=forceSearch&id=COMICVINE_ID"
```

## Related Documentation

- [Collection Gap Fill Strategy](./COLLECTION_GAP_FILL_STRATEGY.md)
- [Manga Remediation Swarm](./MANGA_REMEDIATION_SWARM.md)
- [User Taste Profile](./USER_TASTE_PROFILE.md)
