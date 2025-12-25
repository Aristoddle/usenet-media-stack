# Collection Gap-Fill Strategy

**Version**: 1.0.0
**Created**: 2025-12-24
**Status**: Active
**Philosophy**: Max Bitrate Enthusiast

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current Quality Profile Analysis](#2-current-quality-profile-analysis)
3. [Max Bitrate Optimization Recommendations](#3-max-bitrate-optimization-recommendations)
4. [Gap-Fill Methodology](#4-gap-fill-methodology)
5. [Curated Seed Lists](#5-curated-seed-lists)
6. [Radarr/Sonarr Lists Integration](#6-radarrsonarr-lists-integration)
7. [Automation Recommendations](#7-automation-recommendations)
8. [Implementation Roadmap](#8-implementation-roadmap)

---

## 1. Executive Summary

### Context

Following the accidental 3TB+ data loss during drive migration, this document serves as the strategic roadmap for rebuilding the media collection with an emphasis on:

- **Maximum quality**: Prioritize highest bitrate releases available
- **Canonical curation**: Focus on essential films and TV first
- **Persona alignment**: Collection should reflect user taste, not just popularity lists
- **Automated gap-filling**: Leverage *arr ecosystem for systematic acquisition

### Current State

| Component | Status | Notes |
|-----------|--------|-------|
| Recyclarr | Configured | Using TRaSH templates |
| Radarr Profile | UHD Bluray + WEB | Good baseline, needs optimization |
| Sonarr Profile | WEB-2160p | **Suboptimal for max bitrate** |
| Pool Storage | ~48TB available | mergerfs pool configured |
| Usenet Access | Active | SABnzbd + Prowlarr operational |

### Key Recommendations (TL;DR)

1. **Upgrade Radarr to Remux + WEB 2160p profile** (50-80GB per film vs 15-25GB)
2. **Enable advanced audio custom formats** (TrueHD Atmos, DTS-X)
3. **Enable DV Boost and HDR10+ Boost** for premium HDR
4. **Add IMAX Enhanced scoring** for blockbuster films
5. **Use curated lists** (IMDb, Trakt, Letterboxd) via *arr import

---

## 2. Current Quality Profile Analysis

### 2.1 Radarr Configuration Review

**Current recyclarr.yml:**
```yaml
radarr:
  radarr-4k:
    include:
      - template: radarr-quality-definition-movie
      - template: radarr-quality-profile-uhd-bluray-web
      - template: radarr-custom-formats-uhd-bluray-web
```

**Profile: UHD Bluray + WEB**

| Setting | Current Value | Max Bitrate Optimal |
|---------|---------------|---------------------|
| Target Quality | Bluray-2160p | Remux-2160p |
| Quality Hierarchy | Bluray > WEB | Remux > Bluray > WEB |
| Upgrade Until | Bluray-2160p | Remux-2160p |
| Min Format Score | 0 | 0 (correct) |

**Assessment**: The current profile settles for Bluray encodes (~15-25GB) instead of Remux (~50-80GB). This conflicts with the "max bitrate enthusiast" philosophy.

### 2.2 Sonarr Configuration Review

**Current recyclarr.yml:**
```yaml
sonarr:
  sonarr-4k:
    include:
      - template: sonarr-quality-definition-series
      - template: sonarr-v4-quality-profile-web-2160p
      - template: sonarr-v4-custom-formats-web-2160p
```

**Profile: WEB-2160p**

| Setting | Current Value | Assessment |
|---------|---------------|------------|
| Target Quality | WEB 2160p | **Acceptable** - TV Remux rarely available |
| Quality Hierarchy | WEBDL = WEBRip | Correct for TV |
| Upgrade Until | WEB 2160p | Correct |

**Assessment**: WEB-2160p is appropriate for TV. Unlike films, TV series Remux releases are rare and inconsistent. WEB-DL from premium services (AMZN, NF, ATVP) typically provides the best available quality.

### 2.3 Custom Format Gaps

**Currently Commented Out (Should Be Enabled for Max Quality):**

| Custom Format | Trash ID | Why Enable |
|--------------|----------|------------|
| TrueHD Atmos | `496f355514737f7d83bf7aa4d24f8169` | Best lossless object-based audio |
| DTS-X | `2f22d89048b01681dde8afe203bf2e95` | Alternative lossless object audio |
| DTS-HD MA | `dcf3ec6938fa32445f590a4da84256cd` | High-quality lossless audio |
| TrueHD | `3cafb66171b47f226146a0770576870f` | Lossless audio baseline |
| DV Boost | `b337d6812e06c200ec9a2d3cfa9d20a7` | Prefer Dolby Vision releases |
| HDR10+ Boost | `caa37d0df9c348912df1fb1d88f9273a` | Prefer HDR10+ releases |
| IMAX Enhanced | `9f6cbff8cfe4ebbc1bde14c7b7bec0de` | Expanded aspect ratio |
| IMAX | `eecf3a857724171f968a66cb5719e152` | Standard IMAX releases |
| Criterion | `e0c07d59beb37348e975a930d5e50319` | Premium film restoration |
| 4K Remaster | `eca37840c13c6ef2dd0262b141a5482f` | Prefer newer 4K scans |

---

## 3. Max Bitrate Optimization Recommendations

### 3.1 Recommended Radarr Profile Change

Switch from `uhd-bluray-web` to `remux-web-2160p`:

**Updated recyclarr.yml:**
```yaml
radarr:
  radarr-4k:
    base_url: http://radarr:7878
    api_key: !secret radarr_api_key
    include:
      - template: radarr-quality-definition-movie
      - template: radarr-quality-profile-remux-web-2160p
      - template: radarr-custom-formats-remux-web-2160p

    custom_formats:
      # === ADVANCED AUDIO (ENABLE ALL) ===
      - trash_ids:
          - 496f355514737f7d83bf7aa4d24f8169 # TrueHD Atmos
          - 2f22d89048b01681dde8afe203bf2e95 # DTS X
          - 417804f7f2c4308c1f4c5d380d4c4475 # ATMOS (undefined)
          - 1af239278386be2919e1bcee0bde047e # DD+ ATMOS
          - 3cafb66171b47f226146a0770576870f # TrueHD
          - dcf3ec6938fa32445f590a4da84256cd # DTS-HD MA
          - a570d4a0e56a2874b64e5bfa55202a1b # FLAC
          - e7c2fcae07cbada050a0af3357491d7b # PCM
        assign_scores_to:
          - name: Remux + WEB 2160p

      # === MOVIE VERSIONS (ENABLE PREMIUM) ===
      - trash_ids:
          - eecf3a857724171f968a66cb5719e152 # IMAX
          - 9f6cbff8cfe4ebbc1bde14c7b7bec0de # IMAX Enhanced
          - e0c07d59beb37348e975a930d5e50319 # Criterion Collection
          - 9d27d9d2181838f76dee150882bdc58c # Masters of Cinema
          - db9b4c4b53d312a3ca5f1378f6440fc9 # Vinegar Syndrome
          - eca37840c13c6ef2dd0262b141a5482f # 4K Remaster
          - 570bc9ebecd92723d2d21500f4be314c # Remaster
        assign_scores_to:
          - name: Remux + WEB 2160p

      # === HDR BOOST (BOTH ENABLED) ===
      - trash_ids:
          - b337d6812e06c200ec9a2d3cfa9d20a7 # DV Boost
          - caa37d0df9c348912df1fb1d88f9273a # HDR10+ Boost
        assign_scores_to:
          - name: Remux + WEB 2160p

      # === BLOCK SDR FOR UHD ===
      - trash_ids:
          - 9c38ebb7384dada637be8899efa68e6f # SDR
        assign_scores_to:
          - name: Remux + WEB 2160p
```

### 3.2 Enhanced Sonarr Configuration

Keep WEB-2160p profile but enable HDR boosts:

**Updated recyclarr.yml:**
```yaml
sonarr:
  sonarr-4k:
    base_url: http://sonarr:8989
    api_key: !secret sonarr_api_key
    include:
      - template: sonarr-quality-definition-series
      - template: sonarr-v4-quality-profile-web-2160p
      - template: sonarr-v4-custom-formats-web-2160p

    custom_formats:
      # === HDR BOOST (BOTH ENABLED) ===
      - trash_ids:
          - 0c4b99df9206d2cfac3c05ab897dd62a # HDR10+ Boost
          - 7c3a61a9c6cb04f52f1544be6d44a026 # DV Boost
        assign_scores_to:
          - name: WEB-2160p

      # === BLOCK SDR ===
      - trash_ids:
          - 2016d1676f5ee13a5b7257ff86ac9a93 # SDR
        assign_scores_to:
          - name: WEB-2160p
```

### 3.3 Storage Impact Analysis

| Profile | Avg File Size | 100 Films | 500 Films |
|---------|--------------|-----------|-----------|
| UHD Bluray + WEB | 18 GB | 1.8 TB | 9 TB |
| Remux + WEB 2160p | 55 GB | 5.5 TB | 27.5 TB |

**Recommendation**: With 48TB pool capacity, Remux profile is viable for ~800 films at average size. Prioritize curated essentials first.

---

## 4. Gap-Fill Methodology

### 4.1 Tiered Acquisition Strategy

```
TIER 1: Canon (Must-Have)
   |
   +-- AFI Top 100
   +-- Sight & Sound Top 250
   +-- Academy Award Best Picture Winners
   |
   v
TIER 2: Peak TV
   |
   +-- HBO Golden Age (Wire, Sopranos, etc.)
   +-- AMC Prestige (Breaking Bad, Mad Men)
   +-- FX Anthology (Fargo, Legion)
   +-- Limited Series (Chernobyl, Band of Brothers)
   |
   v
TIER 3: Persona-Aligned
   |
   +-- Genre preferences (inferred from existing collection)
   +-- Director filmographies (auteur completionism)
   +-- LLM recommendations (Claude/GPT curation)
   |
   v
TIER 4: Discovery
   |
   +-- Festival darlings
   +-- International cinema
   +-- Cult classics
```

### 4.2 Gap Identification Workflow

1. **Export current library** from Radarr/Sonarr via API
2. **Cross-reference with canonical lists** to find missing titles
3. **Prioritize by tier** (Canon > Peak TV > Persona > Discovery)
4. **Import to *arr wanted lists** for automated acquisition

```bash
# Export Radarr library
curl -s "http://localhost:7878/api/v3/movie?apikey=YOUR_KEY" | \
  jq -r '.[].title' > /tmp/current-movies.txt

# Compare against AFI list
comm -23 <(sort lists/afi-top-100.txt) <(sort /tmp/current-movies.txt) > /tmp/missing-afi.txt
```

### 4.3 Quality-First Acquisition

Configure Radarr to only grab releases meeting minimum quality:

1. **Set Minimum Custom Format Score**: 0 (allow any matching profile)
2. **Set Upgrade Until Score**: 10000 (always upgrade if better available)
3. **Enable "Prefer Existing Media"**: Prevents re-downloading same quality

---

## 5. Curated Seed Lists

### 5.1 Film Canon (Tier 1)

#### AFI Top 100 (2007 Edition)

Essential American cinema foundation. Import via IMDb list or manual Trakt list.

**Key Titles for 4K Remux Priority:**
- Citizen Kane (Criterion 4K)
- The Godfather I & II (Paramount 4K Restoration)
- Casablanca (Warner 4K)
- Schindler's List (Universal 4K)
- 2001: A Space Odyssey (Warner 4K)
- Lawrence of Arabia (Sony 4K)
- Psycho (Universal 4K)
- Vertigo (Universal 4K)
- Apocalypse Now (Lionsgate 4K)
- Raging Bull (Criterion 4K)

**Import Method:**
```
Radarr > Lists > Add > IMDb
URL: https://www.imdb.com/list/ls055592025/
```

#### Sight & Sound Top 250

Critics' poll representing global cinema canon. Emphasizes international and art house.

**Key International Titles:**
- Tokyo Story (Criterion)
- Seven Samurai (Criterion)
- 8 1/2 (Criterion)
- Persona (Criterion)
- In the Mood for Love (Criterion)
- Jeanne Dielman (Criterion)
- Beau Travail (Criterion)
- Mulholland Drive (Criterion)
- Stalker (Criterion)
- Mirror (Mosfilm restoration)

**Import Method:**
```
Radarr > Lists > Add > Trakt List
URL: Create custom Trakt list from BFI data
```

### 5.2 Peak TV Essentials (Tier 2)

#### HBO Golden Age (1999-2015)

| Series | Years | Seasons | Notes |
|--------|-------|---------|-------|
| The Sopranos | 1999-2007 | 6 | All seasons available in HD |
| The Wire | 2002-2008 | 5 | Remastered HD |
| Deadwood | 2004-2006 | 3 | + 2019 Movie |
| Six Feet Under | 2001-2005 | 5 | |
| Oz | 1997-2003 | 6 | |
| Band of Brothers | 2001 | 1 | Mini-series |
| The Pacific | 2010 | 1 | Mini-series |
| Boardwalk Empire | 2010-2014 | 5 | |
| True Detective S1 | 2014 | 1 | Anthology |
| Chernobyl | 2019 | 1 | Mini-series |

#### AMC Prestige

| Series | Years | Seasons | Notes |
|--------|-------|---------|-------|
| Breaking Bad | 2008-2013 | 5 | + El Camino movie |
| Better Call Saul | 2015-2022 | 6 | |
| Mad Men | 2007-2015 | 7 | |
| The Walking Dead | 2010-2022 | 11 | First 5 seasons essential |

#### FX Excellence

| Series | Years | Seasons | Notes |
|--------|-------|---------|-------|
| The Americans | 2013-2018 | 6 | |
| Fargo | 2014-present | 5 | Anthology |
| Atlanta | 2016-2022 | 4 | |
| The Bear | 2022-present | 3 | |
| Shogun | 2024 | 1 | |

### 5.3 Persona-Aligned Recommendations (Tier 3)

#### Inferred from "Max Bitrate Enthusiast" Profile

**Visual Spectacle Priority:**
- Films known for cinematography (Blade Runner 2049, Dune)
- IMAX-shot films (Oppenheimer, Interstellar, The Dark Knight)
- Heavy VFX with reference-quality transfers (Avatar, Mad Max: Fury Road)

**Director Filmographies (Completionist):**
- Christopher Nolan (all films in 4K)
- Denis Villeneuve (all films in 4K)
- David Fincher (all films, Criterion preferred)
- Stanley Kubrick (all films, 4K restorations)
- Ridley Scott (all films, focus on Director's Cuts)

**Reference Demo Material:**
- Planet Earth II & III (BBC 4K)
- Blue Planet II (BBC 4K)
- Cosmos: A Spacetime Odyssey
- Moving Art (Netflix)

#### LLM-Curated Recommendations

Prompt template for Claude/GPT curation:

```
Given a user who:
- Prioritizes maximum bitrate and visual quality
- Values auteur directors and cinematography
- Already owns: [paste current library]
- Likes: [genres/themes observed]

Recommend 25 films they would love but likely don't own, focusing on:
1. Stunning visual presentation
2. Available in high-quality 4K release
3. Critically acclaimed or cult classic status

Format as: Title (Year) - Director - Why recommend
```

### 5.4 Discovery Queue (Tier 4)

#### Festival Circuit

- Cannes Palme d'Or winners (recent decade)
- Venice Golden Lion winners
- A24 catalog (completionist approach)
- Neon catalog (specialty distributor)

#### International Cinema by Region

| Region | Key Titles | Notes |
|--------|------------|-------|
| Korean | Parasite, Oldboy, The Handmaiden | 4K releases available |
| Japanese | Kurosawa catalog, Ghibli films | Criterion/GKids |
| French | New Wave classics | Criterion restorations |
| Mexican | Del Toro catalog, Roma | Netflix originals in 4K |
| Scandinavian | Bergman catalog | Criterion |

---

## 6. Radarr/Sonarr Lists Integration

### 6.1 Recommended List Sources

#### For Radarr (Films)

| Source | Type | URL Pattern | Notes |
|--------|------|-------------|-------|
| IMDb | Curated | `https://www.imdb.com/list/ls000000000/` | User-created lists |
| IMDb | Charts | `https://www.imdb.com/chart/top` | Top 250 |
| Trakt | List | `https://trakt.tv/users/{user}/lists/{list}` | Requires API key |
| Letterboxd | List | Via Trakt sync | Indirect import |
| TMDB | Discover | API-based | Filter by quality/year |

#### For Sonarr (TV)

| Source | Type | URL Pattern | Notes |
|--------|------|-------------|-------|
| IMDb | List | User lists | Requires conversion to TVDB |
| Trakt | List | `https://trakt.tv/users/{user}/lists/{list}` | Best source for TV |
| TVDB | Favorites | Via Trakt | |

### 6.2 List Configuration in Radarr

**Add IMDb List:**
```
Settings > Lists > + > IMDb Lists

Name: AFI Top 100
List URL: https://www.imdb.com/list/ls055592025/
Monitor: All Movies
Search on Add: Yes
Quality Profile: Remux + WEB 2160p
Minimum Availability: Released
Tags: canon, afi
```

**Add Trakt List:**
```
Settings > Lists > + > Trakt Lists

Name: Sight & Sound 2022
Access Token: [configure OAuth]
List Name: sight-sound-2022
Monitor: All Movies
Search on Add: Yes
Quality Profile: Remux + WEB 2160p
Tags: canon, bfi
```

### 6.3 List Configuration in Sonarr

**Add Trakt List:**
```
Settings > Import Lists > + > Trakt List

Name: Peak TV
Access Token: [configure OAuth]
List Name: peak-tv-essentials
Monitor: All
Season Folder: Yes
Quality Profile: WEB-2160p
Tags: prestige
```

### 6.4 Trakt OAuth Setup

1. Create Trakt account at https://trakt.tv
2. Create API app at https://trakt.tv/oauth/applications
3. Get Client ID and Client Secret
4. In Radarr/Sonarr: Settings > Lists > Trakt > Authenticate

---

## 7. Automation Recommendations

### 7.1 Prowlarr Indexer Optimization

Ensure high-quality indexers are prioritized:

```
Settings > Indexers

Priority Order:
1. NZBGeek (general, reliable)
2. DrunkenSlug (quality focus)
3. NZBFinder (backup)
4. [Torrent indexers as fallback]
```

### 7.2 Recyclarr Scheduled Sync

Configure automatic profile updates:

```yaml
# In recyclarr container environment
CRON_SCHEDULE: "0 4 * * *"  # Daily at 4 AM
TZ: America/Los_Angeles
```

### 7.3 Custom Scripts

#### Gap Analysis Script

```bash
#!/bin/bash
# gap-analysis.sh - Compare library against canonical lists

RADARR_API="http://localhost:7878/api/v3"
RADARR_KEY="your-api-key"

# Get current library
curl -s "${RADARR_API}/movie?apikey=${RADARR_KEY}" | \
  jq -r '.[].imdbId' | sort > /tmp/current-imdb.txt

# Compare against AFI list (stored locally)
comm -23 lists/afi-top-100-imdb.txt /tmp/current-imdb.txt > /tmp/missing-afi.txt

echo "Missing from AFI Top 100:"
wc -l /tmp/missing-afi.txt

# Convert IMDb IDs to titles for readability
while read imdb_id; do
  curl -s "https://www.omdbapi.com/?i=${imdb_id}&apikey=YOUR_OMDB_KEY" | \
    jq -r '.Title'
done < /tmp/missing-afi.txt
```

#### Upgrade Checker Script

```bash
#!/bin/bash
# upgrade-check.sh - Find movies that can be upgraded

RADARR_API="http://localhost:7878/api/v3"
RADARR_KEY="your-api-key"

# Find movies not at Remux quality
curl -s "${RADARR_API}/movie?apikey=${RADARR_KEY}" | \
  jq -r '.[] | select(.movieFile != null) |
         select(.movieFile.quality.quality.name != "Remux-2160p") |
         "\(.title) - \(.movieFile.quality.quality.name)"' | \
  sort
```

### 7.4 Notification Integration

Configure Discord/Gotify webhooks for acquisition alerts:

```
Radarr > Settings > Connect > + > Discord

Name: Media Acquisitions
Webhook URL: https://discord.com/api/webhooks/xxx/yyy
On Grab: Yes
On Import: Yes
On Upgrade: Yes
Include Health Warnings: No
```

---

## 8. Implementation Roadmap

### Phase 1: Profile Optimization (Day 1)

- [ ] Backup current `recyclarr.yml`
- [ ] Update Radarr profile to Remux + WEB 2160p
- [ ] Enable advanced audio custom formats
- [ ] Enable DV Boost and HDR10+ Boost
- [ ] Run `recyclarr sync` to apply changes
- [ ] Verify profiles in Radarr/Sonarr UI

### Phase 2: Canonical Lists (Week 1)

- [ ] Create Trakt account and API credentials
- [ ] Create curated Trakt lists for each tier
- [ ] Add AFI Top 100 list to Radarr
- [ ] Add Sight & Sound Top 250 to Radarr
- [ ] Add Peak TV list to Sonarr
- [ ] Configure search and monitoring options

### Phase 3: Gap Analysis (Week 1-2)

- [ ] Export current library
- [ ] Run gap analysis against Tier 1 lists
- [ ] Prioritize missing canonical titles
- [ ] Queue high-priority acquisitions
- [ ] Monitor Prowlarr for availability

### Phase 4: Persona Curation (Week 2-4)

- [ ] Analyze existing collection patterns
- [ ] Create LLM-curated recommendations
- [ ] Build director filmography lists
- [ ] Add reference demo material list
- [ ] Schedule lower-priority acquisitions

### Phase 5: Ongoing Maintenance (Ongoing)

- [ ] Weekly gap analysis review
- [ ] Monthly recyclarr profile updates
- [ ] Quarterly quality audit (upgrade opportunities)
- [ ] Annual canonical list refresh

---

## Appendix A: Quick Reference

### Updated recyclarr.yml (Complete)

```yaml
# Recyclarr configuration - Max Bitrate Optimized
# Version: 1.1.0 (Gap-Fill Strategy Update)

sonarr:
  sonarr-4k:
    base_url: http://sonarr:8989
    api_key: !secret sonarr_api_key
    include:
      - template: sonarr-quality-definition-series
      - template: sonarr-v4-quality-profile-web-2160p
      - template: sonarr-v4-custom-formats-web-2160p

    custom_formats:
      - trash_ids:
          - 0c4b99df9206d2cfac3c05ab897dd62a # HDR10+ Boost
          - 7c3a61a9c6cb04f52f1544be6d44a026 # DV Boost
        assign_scores_to:
          - name: WEB-2160p

      - trash_ids:
          - 2016d1676f5ee13a5b7257ff86ac9a93 # SDR
        assign_scores_to:
          - name: WEB-2160p

radarr:
  radarr-4k:
    base_url: http://radarr:7878
    api_key: !secret radarr_api_key
    include:
      - template: radarr-quality-definition-movie
      - template: radarr-quality-profile-remux-web-2160p
      - template: radarr-custom-formats-remux-web-2160p

    custom_formats:
      # Advanced Audio
      - trash_ids:
          - 496f355514737f7d83bf7aa4d24f8169 # TrueHD Atmos
          - 2f22d89048b01681dde8afe203bf2e95 # DTS X
          - 417804f7f2c4308c1f4c5d380d4c4475 # ATMOS (undefined)
          - 1af239278386be2919e1bcee0bde047e # DD+ ATMOS
          - 3cafb66171b47f226146a0770576870f # TrueHD
          - dcf3ec6938fa32445f590a4da84256cd # DTS-HD MA
          - a570d4a0e56a2874b64e5bfa55202a1b # FLAC
          - e7c2fcae07cbada050a0af3357491d7b # PCM
        assign_scores_to:
          - name: Remux + WEB 2160p

      # Movie Versions
      - trash_ids:
          - eecf3a857724171f968a66cb5719e152 # IMAX
          - 9f6cbff8cfe4ebbc1bde14c7b7bec0de # IMAX Enhanced
          - e0c07d59beb37348e975a930d5e50319 # Criterion Collection
          - 9d27d9d2181838f76dee150882bdc58c # Masters of Cinema
          - db9b4c4b53d312a3ca5f1378f6440fc9 # Vinegar Syndrome
          - eca37840c13c6ef2dd0262b141a5482f # 4K Remaster
          - 570bc9ebecd92723d2d21500f4be314c # Remaster
        assign_scores_to:
          - name: Remux + WEB 2160p

      # HDR Boost
      - trash_ids:
          - b337d6812e06c200ec9a2d3cfa9d20a7 # DV Boost
          - caa37d0df9c348912df1fb1d88f9273a # HDR10+ Boost
        assign_scores_to:
          - name: Remux + WEB 2160p

      # Block SDR
      - trash_ids:
          - 9c38ebb7384dada637be8899efa68e6f # SDR
        assign_scores_to:
          - name: Remux + WEB 2160p
```

### Custom Format Trash IDs Reference

| Format | Trash ID | Profile |
|--------|----------|---------|
| TrueHD Atmos | `496f355514737f7d83bf7aa4d24f8169` | Radarr |
| DTS X | `2f22d89048b01681dde8afe203bf2e95` | Radarr |
| DTS-HD MA | `dcf3ec6938fa32445f590a4da84256cd` | Radarr |
| TrueHD | `3cafb66171b47f226146a0770576870f` | Radarr |
| DV Boost | `b337d6812e06c200ec9a2d3cfa9d20a7` | Radarr |
| HDR10+ Boost | `caa37d0df9c348912df1fb1d88f9273a` | Radarr |
| DV Boost (Sonarr) | `7c3a61a9c6cb04f52f1544be6d44a026` | Sonarr |
| HDR10+ Boost (Sonarr) | `0c4b99df9206d2cfac3c05ab897dd62a` | Sonarr |
| IMAX | `eecf3a857724171f968a66cb5719e152` | Radarr |
| IMAX Enhanced | `9f6cbff8cfe4ebbc1bde14c7b7bec0de` | Radarr |
| Criterion | `e0c07d59beb37348e975a930d5e50319` | Radarr |
| SDR (Radarr) | `9c38ebb7384dada637be8899efa68e6f` | Radarr |
| SDR (Sonarr) | `2016d1676f5ee13a5b7257ff86ac9a93` | Sonarr |

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-24 | Initial gap-fill strategy document |

---

*This document integrates with POST_MIGRATION_PLAN.md and provides the collection curation strategy for the post-migration media server rebuild.*
