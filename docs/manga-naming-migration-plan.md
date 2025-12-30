# Manga Naming Migration Plan

**Generated:** 2025-12-29
**Target:** Clean up 81 Mylar3 stub folders + ensure 100% NAMING_STANDARD_V2 compliance
**Risk Level:** Low (removals are metadata-only folders)

---

## Current State Summary

| Category | Count | Action Needed |
|----------|-------|---------------|
| STANDARD folders (content) | 78 | None - compliant |
| YEAR_ONLY folders (stubs) | 81 | Remove (metadata only) |
| Duplicate pairs | 33 | Remove YEAR_ONLY copy |
| Unique YEAR_ONLY | 48 | Remove or convert |

---

## Phase 1: Remove Mylar3 Metadata Stubs

### Why These Can Be Safely Removed

The YEAR_ONLY folders (`Series Name (YYYY)`) were created by Mylar3 for metadata tracking but contain:
- `series.json` - Mylar metadata
- `cvinfo` - ComicVine info file
- **Zero CBZ/CBR files**

The actual content exists in the STANDARD folders. Example:

```
Chainsaw Man (2020)/         # 0 CBZ, just series.json + cvinfo
Chainsaw Man (Viz) [EN]/     # 6.61GB, 244 CBZ files
```

### Stub Removal Script

```bash
#!/usr/bin/env bash
set -euo pipefail

COMICS_ROOT="/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics"
DRY_RUN="${DRY_RUN:-1}"  # Default to dry-run

# Folders matching "(YYYY)" pattern that are metadata-only
YEAR_ONLY_STUBS=(
  "20th Century Boys The Perfect Edition (2018)"
  "A Silent Voice (2015)"
  "Akame ga Kill Zero (2016)"
  "Akane-banashi (2023)"
  "Akira Toriyamas Manga Theater (2021)"
  "Alice in the Country of Joker Circus and Liars Game (2013)"
  "Ashita no Joe Fighting for Tomorrow (2024)"
  "Assassination Classroom (2014)"
  "BLAME Master Edition (2016)"
  "Bakuman (2010)"
  "Barakamon (2014)"
  "Berserk (2011)"
  "Berserk of Gluttony (2021)"
  "Billy Bat (2008)"
  "Black Clover (2016)"
  "Blade of the Immortal Omnibus (2016)"
  "Bleach (2011)"
  "Blue Box (2022)"
  "Blue Lock Episode Nagi (2024)"
  "Blue Period (2020)"
  "Chainsaw Man (2020)"
  "Choujin X (2023)"
  "Claymore (2006)"
  "Dai Dark (2021)"
  "Dandadan (2022)"
  "Deadpool Classic (2008)"
  "Death Note (2005)"
  "Demon Slayer - Kimetsu no Yaiba (2020)"
  "Dorohedoro (2010)"
  "Dr. STONE Reboot Byakuya (2021)"
  "Eyeshield 21 (2005)"
  "Fire Punch (2018)"
  "Fist of the North Star Blood Brothers (1998)"
  "Food Wars Shokugeki no Soma (2014)"
  "Four Lives Remain Tatsuya Endo Before Spy x Family (2025)"
  "Frieren Beyond Journeys End (2021)"
  "Fullmetal Alchemist The Complete Four-Panel Comics (2019)"
  "GTO Paradise Lost (2017)"
  "Gachiakuta (2024)"
  "Gantz G (2018)"
  "Goodbye Eri (2023)"
  "Haikyu (2024)"
  "Hajime no Ippo (2017)"
  "Hellsing (Second Edition) (2023)"
  "Hunter x Hunter (2012)"
  "Hunter x Hunter (2025)"
  "JoJos Bizarre Adventure Shining Diamonds Demonic Heartbreak (2024)"
  "Jujutsu Kaisen (2019)"
  "Kagurabachi (2024)"
  "Kagurabachi - Boruto -Two Blue Vortex- Free Comic Book Day 2025 Edition (2025)"
  "Kaguya-sama Love is War (2018)"
  "Kaijin Fugeki (2024)"
  "Kaiju No. 8 B-Side (2025)"
  "Kakegurui Twin (2019)"
  "Kingdom (2025)"
  "Korogaru Hoshi no Asterism (2025)"
  "Koyoharu Gotouge Before Demon Slayer Kimetsu no Yaiba (2024)"
  "Look Back (2022)"
  "Made in Abyss (2018)"
  "Made in Abyss Official Anthology (2020)"
  "Mob Psycho 100 Reigen - The Man With Level 131 Max Spirit Power (2020)"
  "My Hero Academia (2016)"
  "Naoki Urasawas Monster (2006)"
  "Naruto Konohas Story - The Steam Ninja Scrolls The Manga (2024)"
  "Nine Dragons Ball Parade (2022)"
  "One Piece Aces Story - The Manga (2024)"
  "One-Punch Man (2014)"
  "One-Punch Man (2016)"
  "Parasyte (2007)"
  "Pluto Urasawa x Tezuka (2009)"
  "Rurouni Kenshin (2017)"
  "Sakamoto Days (2022)"
  "Sand Land (2003)"
  "Slam Dunk (2008)"
  "Smoking Behind the Supermarket with You (2024)"
  "Soul Eater Soul Art (2017)"
  "Spirit Circle (2017)"
  "Sunny (2013)"
  "Tsubaki-chou Lonely Planet (2022)"
  "Vagabond (2002)"
  "Vinland Saga (2013)"
)

echo "=== Mylar3 Stub Folder Cleanup ==="
echo "DRY_RUN=$DRY_RUN (set DRY_RUN=0 to execute)"
echo ""

removed=0
skipped=0

for folder in "${YEAR_ONLY_STUBS[@]}"; do
  path="$COMICS_ROOT/$folder"

  if [[ ! -d "$path" ]]; then
    echo "SKIP: $folder (not found)"
    ((skipped++))
    continue
  fi

  # Count CBZ/CBR files
  cbz_count=$(find "$path" -type f \( -name "*.cbz" -o -name "*.cbr" \) 2>/dev/null | wc -l)

  if [[ "$cbz_count" -gt 0 ]]; then
    echo "SKIP: $folder (has $cbz_count comic files)"
    ((skipped++))
    continue
  fi

  # Verify it's metadata-only
  file_count=$(find "$path" -type f 2>/dev/null | wc -l)

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "WOULD REMOVE: $folder ($file_count files, 0 comics)"
  else
    rm -rf "$path"
    echo "REMOVED: $folder"
  fi
  ((removed++))
done

echo ""
echo "Summary: $removed removed, $skipped skipped"
```

### Execution

```bash
# Step 1: Dry run (default)
./scripts/cleanup-mylar3-stubs.sh

# Step 2: Verify output looks correct

# Step 3: Execute for real
DRY_RUN=0 ./scripts/cleanup-mylar3-stubs.sh
```

---

## Phase 2: Standardize Remaining Non-Compliant Folders

### Series Needing Publisher Identification

Some YEAR_ONLY folders may have content and need conversion to STANDARD format:

| Current Name | Target Name | Publisher |
|--------------|-------------|-----------|
| Death Note (2005) | Death Note (Viz) [EN] | Viz |
| Kingdom (2025) | Kingdom (Kodansha) [EN] | Kodansha |
| Parasyte (2007) | Parasyte (Kodansha) [EN] | Kodansha |
| Billy Bat (2008) | Billy Bat (Urasawa) [EN] | Fan (unlicensed) |

### Publisher Research Workflow

For any folder without clear publisher:

```bash
# Use WebSearch to identify publisher
# Query: "{Series Name} manga publisher english official"

# Common publisher patterns:
# - "Viz Media" -> (Viz)
# - "Kodansha USA/Comics" -> (Kodansha) or (Kodansha Comics)
# - "Seven Seas Entertainment" -> (Seven Seas)
# - "Yen Press" -> (Yen Press)
# - "Dark Horse" -> (Dark Horse)
# - "Square Enix" -> (Square Enix)
# - No English release -> (Fan) or (Scanlation)
```

---

## Phase 3: Internal Structure Standardization

### Apply Tier Classification

For each series, apply the appropriate tier from NAMING_STANDARD_V2:

**Tier 1 (Simple - 60% of series)**
```
Series Name (Publisher) [EN]/
└── Volumes/
```

**Tier 2 (Format Variants - 15%)**
```
Series Name (Publisher) [EN]/
├── 1. Volumes/
├── 1c. Volumes [Colored]/
└── 2. Chapters/
```

**Tier 3 (Related Works - 15%)**
```
Series Name (Publisher) [EN]/
├── 1. Main Series (YYYY-YYYY)/
├── 2. Sequel Name [Sequel] (YYYY-present)/
└── Extras/
```

**Tier 4 (Multi-Part Sagas - 10%)**
```
Series Name (Publisher) [EN]/
├── 1. Part One (YYYY-YYYY)/
├── 2. Part Two (YYYY-YYYY)/
└── 3. Part Three (YYYY-present)/
```

---

## Phase 4: Komga Library Refresh

After folder changes:

```bash
# Force Komga library rescan
KOMGA_URL="http://localhost:8081"
KOMGA_USER="your_email"
KOMGA_PASS="your_password"

# Get library ID
LIB_ID=$(curl -s -u "$KOMGA_USER:$KOMGA_PASS" "$KOMGA_URL/api/v1/libraries" | jq -r '.[0].id')

# Trigger scan
curl -u "$KOMGA_USER:$KOMGA_PASS" -X POST "$KOMGA_URL/api/v1/libraries/$LIB_ID/scan"

echo "Scan triggered for library: $LIB_ID"
```

---

## Validation Checklist

### Pre-Migration

- [ ] Backup MANGA_PROJECT_DOCS (git commit)
- [ ] Pause OneDrive sync (if applicable)
- [ ] Close any Komga/Panels sessions

### Post-Migration

- [ ] Verify 78 STANDARD folders intact
- [ ] Verify 81 YEAR_ONLY stubs removed
- [ ] Run Komga library scan
- [ ] Check Panels app displays correctly
- [ ] Resume OneDrive sync

---

## Rollback Plan

### If Something Goes Wrong

The YEAR_ONLY folders are Mylar3-generated and can be recreated by:
1. Re-adding series to Mylar3
2. Running Mylar3 metadata refresh

However, since they contain no actual content, there is nothing critical to recover.

### Git Recovery (for documentation)

```bash
cd /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
git log --oneline -20  # Find pre-migration commit
git checkout <commit> -- .  # Restore if needed
```

---

## Schedule

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Remove stubs | 5 minutes | None |
| Phase 2: Standardize names | 30 minutes | Publisher research |
| Phase 3: Internal structure | 60 minutes | Per-series analysis |
| Phase 4: Komga refresh | 10 minutes | Scan completion |
| **Total** | ~2 hours | |

---

## Related Scripts

| Script | Purpose |
|--------|---------|
| `scripts/manga-naming-enforcer.sh` | Audit + fix naming |
| `scripts/cleanup-mylar3-stubs.sh` | Phase 1 removal |
| `scripts/komga-gap-report.py` | Post-migration validation |

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-29 | Initial migration plan |
