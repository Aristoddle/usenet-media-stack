# TV Reorganization - Executive Summary

**Date:** 2025-01-25
**Status:** Analysis Complete - Awaiting Approval
**Priority:** Medium (Backup in progress)

---

## The Problem

Your TV library at `/run/media/deck/Fast_4TB_5/TV` has **2,326 folders** that are individual episodes instead of being organized by series and season. This breaks Plex/Sonarr's expected structure and makes the library unmanageable.

### Current Structure (Broken)
```
TV/
  One.Piece.S12E44.1080p.H.265-G/
    One.Piece.S12E44.mkv
  Seinfeld.S09E16.1080p-NTb/
    Seinfeld.S09E16.mkv
  ... (2,324 more folders like this)
```

### Required Structure (Plex/Sonarr Compatible)
```
TV/
  One Piece (1999)/
    Season 12/
      One Piece - S12E44 - Episode Title.mkv
  Seinfeld (1989)/
    Season 09/
      Seinfeld - S09E16 - The Burning.mkv
```

---

## Key Findings

- **Total Episodes:** ~5,876 video files
- **Total Size:** 3.5 TB
- **Unique Series:** ~179 shows
- **Top Series:** One Piece (713+ episodes), Doctor Who (198+ episodes)
- **Properly Organized:** Only ~1% (Atlanta is the only correct one)
- **Episode-Named Folders:** 87% (2,021 folders)

---

## Recommended Solution

**Hybrid Approach: FileBot + Sonarr Verification**

### Why FileBot?
- Industry-standard tool for TV reorganization
- 95%+ success rate on standard releases
- Handles complex naming patterns automatically
- Cost: $48 one-time license (lifetime)
- Time: 12-20 hours vs 44-86 hours manual

### Three-Phase Plan

#### Phase 1: Testing (Day 1)
- Install FileBot
- Test on 50-episode subset
- Verify accuracy
- **Decision point:** Proceed only if >90% success

#### Phase 2: Execution (Days 2-3)
- Run FileBot on full TV directory
- Process in batches by series
- Monitor for errors
- Review match logs

#### Phase 3: Sonarr Integration (Days 4-5)
- Import reorganized files into Sonarr
- Fix any unmatched episodes manually
- Configure ongoing monitoring
- Update Plex library

---

## Effort Comparison

| Approach | Time | Cost | Risk | Success Rate |
|----------|------|------|------|--------------|
| **Recommended: FileBot** | **12-20 hrs** | **$48** | **Low** | **~95%** |
| Manual (Sonarr) | 44-86 hrs | $0 | Low | 100% |
| Custom Script | 28-42 hrs | $0 | Medium | ~85% |
| Re-Download All | Weeks | High Data | Very High | Unknown |

---

## Special Cases Identified

### High-Risk Series (Need Manual Attention)
1. **Doctor Who** - Classic (1963) vs Modern (2005), multi-part episodes
2. **One Piece** - 713+ episodes, multiple naming variants
3. **Monogatari Series** - Complex airing order, sub-series
4. **Legend of the Galactic Heroes** - Absolute vs seasonal numbering

### Easy Series (FileBot Will Handle Automatically)
- Seinfeld
- Gravity Falls
- Futurama
- Naruto
- Attack on Titan
- The Wire
- Most western TV shows

---

## Risk Mitigation

### Safety Measures
1. ✅ **Backup in progress** to swap_drive (3.5 TB)
2. **Dry-run testing** before any file moves
3. **Incremental execution** (process series-by-series)
4. **Verification points** after each batch
5. **Rollback plan** using backup

### Rollback Plan
If anything goes wrong:
1. Stop FileBot immediately
2. Restore affected series from swap_drive backup
3. Reprocess manually or with adjusted settings

---

## Cost-Benefit Analysis

### Current State Cost
- **Manual Effort:** 5-10 minutes per episode to manually organize
- **Total:** 2,021 episodes × 5 min = **168 hours of work**
- **Or:** Leave disorganized, Plex/Sonarr can't manage properly

### Recommended Approach Cost
- **FileBot License:** $48 one-time
- **Your Time:** 12-20 hours
- **Value at $50/hr:** $600-1,000
- **Total:** $648-1,048

### Savings vs Manual
- **Time Saved:** 148-168 hours
- **Value Saved:** $7,400-8,400 @ $50/hr
- **ROI:** 700-800% return on investment

---

## Timeline

### Week 1
- **Day 1:** Install FileBot, run test subset, verify results
- **Day 2-3:** Execute FileBot on full library (batches)
- **Day 4-5:** Sonarr integration and verification
- **Day 6:** Cleanup and documentation

### Week 2+
- Sonarr manages library going forward
- Plex scans and matches properly
- Future downloads auto-organized

---

## Next Steps

### Immediate (Today)
1. ✅ Review this analysis
2. ⏳ Wait for backup to complete
3. 🔲 Approve recommended approach

### If Approved
1. Purchase FileBot license
2. Run Phase 1 testing
3. Report test results
4. Proceed to Phase 2 if successful

### If Not Approved
- Provide alternative approach preference
- Adjust plan accordingly

---

## Questions to Answer

Before proceeding, please confirm:

1. **Backup Status:** Is the swap_drive copy complete?
2. **Approval:** Proceed with FileBot + Sonarr approach?
3. **Budget:** Approve $48 for FileBot license?
4. **Timeline:** Is 1 week acceptable for completion?
5. **Risk Tolerance:** Comfortable with 95% automatic + 5% manual?

---

## Documents Generated

All analysis documents are available at:
```
/var/home/deck/Documents/Code/media-automation/usenet-media-stack/
```

1. **TV_REORGANIZATION_PLAN.md** - Full detailed plan (this document)
2. **TV_SAMPLE_ANALYSIS.txt** - Raw data from 100-folder sample
3. **FILEBOT_TEST_PLAN.sh** - Executable testing script
4. **TV_REORG_EXECUTIVE_SUMMARY.md** - This summary

---

## Recommendation

**Proceed with FileBot + Sonarr hybrid approach once backup is verified complete.**

This provides the best balance of:
- ✅ Time efficiency (12-20 hours vs 44-86)
- ✅ Cost effectiveness ($48 vs weeks of work)
- ✅ Success rate (~95% automatic)
- ✅ Safety (dry-run testing, incremental execution)
- ✅ Future-proofing (Sonarr manages ongoing)

The $48 investment in FileBot pays for itself immediately and will be useful for future media management tasks.

---

**Awaiting your decision to proceed.**
