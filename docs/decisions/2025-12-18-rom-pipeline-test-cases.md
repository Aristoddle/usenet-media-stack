# ROM Pipeline E2E Test Cases

**Date**: 2025-12-18
**Related Decision**: 2025-12-18-rom-acquisition-pipeline.md

## Test Strategy

### Test Prioritization

| Priority | Test | Reason |
|----------|------|--------|
| P0 | NDS search + download | Smallest files, best indexer coverage |
| P1 | PSP search + download | Good coverage, medium file size |
| P1 | Hash verification | Core feature validation |
| P2 | Wii/Switch search | Larger files, obfuscated names |
| P3 | Torrent fallback | Secondary workflow |

---

## P0: NDS ROM Acquisition (First Test)

### Test Case: TC-ROM-001 - NDS Search and Download

**Objective**: Validate complete Usenet pipeline for NDS ROMs

**Test ROM**: "New Super Mario Bros (USA)"
- Expected size: ~30MB
- No-Intro name: `New Super Mario Bros. (USA, Europe).nds`
- Category: 101010 (NDS)
- Known good SHA1: `3b1eb8b3e2ab16a1a7426a03bff93cb34d1e1fd4` (verify against current DAT)

**Prerequisites**:
1. Prowlarr running and accessible at localhost:9696
2. SABnzbd running at localhost:8080
3. SABnzbd category `roms` configured
4. At least one Console indexer enabled in Prowlarr

**Test Steps**:

```bash
# Step 1: Pre-flight check
source /var/home/deck/.claude/skills/rom-acquisition-agent/SKILL.md
rom_preflight

# Expected output:
# OK: Prowlarr accessible
# OK: SABnzbd accessible
# OK: Staging directories exist
# OK: ROM root accessible

# Step 2: Search Prowlarr
prowlarr_search_rom "New Super Mario Bros" 101010

# Expected output: At least one result with size ~30MB
# Example:
# 28.5MB|NZBPlanet|New Super Mario Bros (USA)|http://...

# Step 3: Full pipeline (if search succeeds)
rom_acquire "New Super Mario Bros" 101010 nds

# Expected output:
# === ROM Acquisition Pipeline ===
# [phases 1-6 complete]
# === Pipeline Complete ===
# Verified ROM ready at: /var/mnt/fast8tb/Local/downloads/staging/roms/verified/
```

**Validation Criteria**:
- [ ] Search returns at least 1 result
- [ ] NZB downloads successfully (size > 100 bytes)
- [ ] SABnzbd accepts upload (status: true)
- [ ] Download completes within 5 minutes
- [ ] File appears in staging/verified/
- [ ] File size matches expected (~30MB)

**Rollback**:
- Remove from staging: `rm -rf /var/mnt/fast8tb/Local/downloads/staging/roms/pending/*`
- Check SABnzbd history for failed downloads

---

## P0: Hash Verification Test

### Test Case: TC-ROM-002 - SHA1 Verification

**Objective**: Validate hash verification against No-Intro

**Prerequisites**:
- Downloaded ROM from TC-ROM-001 in staging/verified/
- No-Intro NDS DAT available

**Test Steps**:

```bash
# Step 1: Get No-Intro hash for test ROM
# (Manual lookup or DAT parser)
EXPECTED_HASH="3b1eb8b3e2ab16a1a7426a03bff93cb34d1e1fd4"  # Replace with actual

# Step 2: Verify downloaded ROM
ROM_FILE="/var/mnt/fast8tb/Local/downloads/staging/roms/verified/New Super Mario Bros*.nds"
ACTUAL_HASH=$(sha1sum "$ROM_FILE" | cut -d' ' -f1)

echo "Expected: $EXPECTED_HASH"
echo "Actual:   $ACTUAL_HASH"

# Step 3: Compare
if [[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]]; then
  echo "PASS: Hash matches No-Intro"
else
  echo "FAIL: Hash mismatch"
fi
```

**Validation Criteria**:
- [ ] SHA1 computation completes
- [ ] Hash matches No-Intro database
- [ ] If mismatch, ROM moved to staging/rejected/

---

## P1: PSP ROM Acquisition

### Test Case: TC-ROM-003 - PSP Search and Download

**Objective**: Validate pipeline for medium-sized PSP ROMs

**Test ROM**: "LocoRoco (USA)"
- Expected size: ~40MB
- Category: 101020 (PSP)
- Format: ISO

**Test Steps**:

```bash
# Search
prowlarr_search_rom "LocoRoco" 101020

# Full pipeline
rom_acquire "LocoRoco" 101020 psp

# Verify file
ls -la /var/mnt/fast8tb/Local/downloads/staging/roms/verified/*.iso
```

**Validation Criteria**:
- [ ] Search returns PSP-specific results
- [ ] Download completes (may take longer than NDS)
- [ ] ISO file integrity (not corrupted)

---

## P1: Collection Replace Test

### Test Case: TC-ROM-004 - Replace ROM in Collection

**Objective**: Validate safe replacement with backup

**Prerequisites**:
- Verified ROM in staging/verified/
- Existing ROM in collection (or empty target)

**Test Steps**:

```bash
# Check current state
ls -la /var/mnt/fast8tb/Emudeck/Emulation/roms/nds/ | grep -i "super mario"

# Replace
replace_rom "/var/mnt/fast8tb/Local/downloads/staging/roms/verified/New Super Mario Bros*.nds" nds

# Verify
ls -la /var/mnt/fast8tb/Emudeck/Emulation/roms/nds/ | grep -i "super mario"
ls -la /var/mnt/fast8tb/Local/downloads/staging/roms/replaced/
```

**Validation Criteria**:
- [ ] Original ROM backed up to staging/replaced/
- [ ] New ROM in correct collection folder
- [ ] File permissions correct (readable by ES-DE)

---

## P2: Switch ROM Search

### Test Case: TC-ROM-005 - Switch Search (Obfuscated Names)

**Objective**: Test search for Switch ROMs with obfuscated indexer names

**Test ROM**: "The Legend of Zelda: Breath of the Wild"
- Expected size: ~14GB
- Category: 101040 (Switch)
- Format: NSP or XCI

**Note**: Switch ROMs often have obfuscated names on indexers. This test validates search strategy.

**Test Steps**:

```bash
# Try exact name
prowlarr_search_rom "Zelda Breath of the Wild" 101040

# Try abbreviated
prowlarr_search_rom "BOTW Switch" 101040

# Try general category fallback
prowlarr_search_rom "Zelda Breath of the Wild" 1000
```

**Validation Criteria**:
- [ ] At least one search variant returns results
- [ ] Results are actually Switch ROMs (not Wii U)
- [ ] Size reasonable for Switch game (10-20GB)

**Note**: Do NOT proceed with download for this test (too large for quick validation).

---

## P3: Torrent Fallback

### Test Case: TC-ROM-006 - Transmission Fallback

**Objective**: Validate torrent fallback when Usenet fails

**Prerequisites**:
- Transmission running at localhost:9091
- A magnet link for small test ROM

**Test Steps**:

```bash
# Get session ID
SESSION_ID=$(curl -s http://localhost:9091/transmission/rpc 2>&1 | grep -oP 'X-Transmission-Session-Id: \K[^<]+')
echo "Session ID length: ${#SESSION_ID}"  # Should be ~50

# Add test torrent (use a small, legal ROM backup)
# This would use actual magnet from research

# Monitor
transmission-remote localhost:9091 -l
```

**Validation Criteria**:
- [ ] Session ID retrieved successfully
- [ ] Torrent add returns success
- [ ] Download completes to staging directory

---

## Negative Test Cases

### Test Case: TC-ROM-N01 - Empty Search Results

**Objective**: Verify graceful handling of no results

```bash
prowlarr_search_rom "xyznonexistentgame123" 101010
# Expected: Empty output, no crash
```

### Test Case: TC-ROM-N02 - Invalid NZB

**Objective**: Verify handling of corrupted/invalid NZB

```bash
# Create fake NZB
echo "not xml" > /tmp/fake.nzb
fetch_rom_nzb "http://invalid.url" /tmp/test.nzb
# Expected: FAIL message with reason
```

### Test Case: TC-ROM-N03 - SABnzbd Unreachable

**Objective**: Verify pre-flight catches service issues

```bash
# Stop SABnzbd (or test with wrong port)
SABNZBD_URL="http://localhost:9999" rom_preflight
# Expected: FAIL: SABnzbd not accessible
```

---

## Test Data: No-Intro Reference Hashes

For verification tests, use these known-good hashes (verify against current DATs):

| ROM | SHA1 | Size |
|-----|------|------|
| New Super Mario Bros (USA, Europe).nds | TBD | ~30MB |
| LocoRoco (USA).iso | TBD | ~40MB |
| Pokemon FireRed (USA).gba | TBD | ~16MB |

**DAT Sources**:
- No-Intro NDS: https://datomatic.no-intro.org/ (requires account)
- Redump PSP: http://redump.org/

---

## Success Metrics

### Phase 1 MVP Complete When:

1. **TC-ROM-001**: NDS ROM downloads via Usenet
2. **TC-ROM-002**: Hash verification passes
3. **TC-ROM-004**: ROM safely replaced in collection

### Phase 2 Complete When:

1. **TC-ROM-003**: PSP ROM downloads successfully
2. **TC-ROM-005**: Switch search returns valid results
3. Gap report generated for one system

### Phase 3 Complete When:

1. **TC-ROM-006**: Torrent fallback works
2. Multi-system gap reports automated
3. Batch acquisition tested

---

## Quick Test Script

```bash
#!/bin/bash
# ROM Pipeline Quick Test
set -e

echo "=== ROM Pipeline Quick Test ==="

# Source skill
source /var/home/deck/.claude/skills/rom-acquisition-agent/SKILL.md 2>/dev/null || {
  echo "Note: Skill file sourced manually (functions defined inline)"
}

# Set environment
export CONFIG_ROOT="/var/mnt/fast8tb/config"
export ROM_ROOT="/var/mnt/fast8tb/Emudeck/Emulation/roms"
export STAGING_ROOT="/var/mnt/fast8tb/Local/downloads/staging/roms"
export PROWLARR_URL="http://localhost:9696"
export SABNZBD_URL="http://localhost:8080"

# Read API keys
export PROWLARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_ROOT/prowlarr/config.xml" 2>/dev/null || echo "")
export SABNZBD_API_KEY=$(grep -oP '(?<=^api_key = ).+' "$CONFIG_ROOT/sabnzbd/sabnzbd.ini" 2>/dev/null || echo "")

echo "1. Checking Prowlarr..."
if curl -sf "$PROWLARR_URL/api/v1/health" -H "X-Api-Key: $PROWLARR_API_KEY" >/dev/null 2>&1; then
  echo "   OK: Prowlarr accessible"
else
  echo "   SKIP: Prowlarr not running"
fi

echo "2. Checking SABnzbd..."
if curl -sf "$SABNZBD_URL/api?mode=version&apikey=$SABNZBD_API_KEY" >/dev/null 2>&1; then
  echo "   OK: SABnzbd accessible"
else
  echo "   SKIP: SABnzbd not running"
fi

echo "3. Checking staging directories..."
mkdir -p "$STAGING_ROOT"/{pending,verified,rejected} 2>/dev/null
echo "   OK: Staging directories ready"

echo "4. Checking ROM root..."
if [[ -d "$ROM_ROOT" ]]; then
  echo "   OK: ROM root exists ($(ls "$ROM_ROOT" | wc -l) systems)"
else
  echo "   FAIL: ROM root not found"
fi

echo ""
echo "=== Quick Test Complete ==="
echo "Services running: Run 'docker compose up -d' to start stack"
echo "Full test: Run 'rom_acquire \"New Super Mario Bros\" 101010 nds'"
```

---

**Last Updated**: 2025-12-18
**Related**: rom-acquisition-agent/SKILL.md
