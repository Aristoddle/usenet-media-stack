# Recommended Manga Acquisitions

**Generated:** 2025-12-29
**Based On:** Collection analysis + taste profile mining
**Philosophy:** Hook-first recommendations (per manga-pitch-philosophy skill)

---

## Taste Profile Summary

Based on your collection of 78+ series, your preferences cluster around:

| Affinity | Examples | Strength |
|----------|----------|----------|
| **Dark Action/Seinen** | Berserk, Chainsaw Man, Gantz, Tokyo Ghoul | Very High |
| **Battle Shounen** | JoJo, Baki, Dragon Ball, Naruto, Bleach | Very High |
| **Sports Drama** | Blue Lock, Haikyu!!, Slam Dunk, Hajime no Ippo | High |
| **Psychological/Thriller** | Monster, Liar Game, Kaiji, Death Note | High |
| **Quirky Comedy** | One-Punch Man, Mob Psycho 100, GTO, Dorohedoro | High |
| **Fantasy Adventure** | Made in Abyss, Dungeon Meshi, Frieren | High |

**Author Affinities:**
- Tatsuki Fujimoto (complete: Chainsaw Man, Fire Punch, Look Back, Goodbye Eri)
- Naoki Urasawa (have: Monster, 20th Century Boys, Pluto; missing: Billy Bat scans)
- ONE (complete: OPM, Mob Psycho 100)
- Sui Ishida (complete: Tokyo Ghoul; ongoing: Choujin X)

---

## Priority 1: Complete Ongoing Series

These are series you already follow that have new content:

### High Priority (Weekly/Active)

| Series | Current | Latest | Gap | Acquisition Notes |
|--------|---------|--------|-----|-------------------|
| **Kagurabachi** | v1-v9 | Ch104+ | Ch after v9 | Hot shounen - Rillant releases weekly |
| **Sakamoto Days** | ? | Ch240/v25 | Check volumes | Spinoff "Sakamoto Holidays" coming |
| **One Piece** | v109? | Ch1133 | Weekly chapters | 1r0n for volumes, Rillant for chapters |
| **Dandadan** | ? | Ch185+ | Check | aKraa packs or Rillant weekly |
| **Blue Lock** | ? | Ch296+ | Check volumes | Episode Nagi complete (v1-v8) |

### Medium Priority (Caught Up but Verify)

| Series | Status | Action |
|--------|--------|--------|
| Hunter x Hunter | Hiatus ended, Ch410+ | v38 EN releasing Jan 2026 |
| Jujutsu Kaisen | COMPLETE (Sep 2024) | Verify v29-v30 in collection |
| Chainsaw Man | Part 2 ongoing | Verify Chapter coverage |

---

## Priority 2: Fill Collection Gaps

### Quarantined Files (Re-acquire)

Per `docs/komga-corrupt-cbz.md`, these were quarantined as corrupt:

| Series | Volumes | Source to Re-acquire |
|--------|---------|---------------------|
| **Blue Box** | v01-v18 | 1r0n releases on usenet |
| **Sand Land** | (2003) | Alternative release group |

### Missing Volumes (Known Gaps)

| Series | Missing | Notes |
|--------|---------|-------|
| Blue Lock Episode Nagi | v06-v08 | Series complete, need final 3 |
| Spy x Family | Verify v16+ | Biweekly release schedule |
| Frieren | Verify latest | v13+ in JP |

---

## Priority 3: New Series Recommendations

### "You'd Love This" - High Confidence

These match your taste profile strongly:

#### **Undead Unluck** (Viz)
*Yoshifumi Tozuka doing unhinged battle shounen*

- Status: Complete (20 volumes, ended Dec 2024)
- Why: JoJo-level creativity in power systems, rapid escalation, satisfying conclusion
- Acquisition: 1r0n volumes on usenet

#### **Kaiju No. 8 Side Stories**
*Matsumoto expanding the kaiju-verse*

- Status: Ongoing (B-Side started 2024)
- Why: You have the main series; completionist value
- Acquisition: Rillant chapters

#### **Gachiakuta** (Kodansha)
*Kei Urana doing trash-punk battle manga*

- Status: Ongoing (~80 chapters)
- Why: Incredible art, underdog story, Dorohedoro energy
- Note: Already in collection as `GACHIAKUTA (Kodansha) [EN]` - verify completeness

#### **Witch Hat Atelier** (Kodansha)
*Kamome Shirahama doing fantasy with unreal art*

- Status: Ongoing (13 volumes)
- Why: If you like Made in Abyss world-building + Frieren atmosphere
- Art quality: TIER 0 - absolutely stunning linework

### "Expand Your Horizons" - Medium Confidence

#### **Real** (Viz)
*Inoue (Slam Dunk) doing wheelchair basketball*

- Status: Ongoing (hiatus-prone, 15 volumes)
- Why: Same creator as Slam Dunk/Vagabond, most mature work
- Risk: Perpetual hiatus

#### **Holyland** (Fan Translation)
*Mori doing street fighting realism*

- Status: Complete (18 volumes)
- Why: Hajime no Ippo energy, grounded martial arts
- Acquisition: aKraa or Empire packs (unlicensed)

#### **Oyasumi Punpun** (Viz)
*Asano doing coming-of-age depression*

- Status: Complete (13 volumes)
- Why: Monster/20th Century Boys psychological depth
- Warning: Emotionally brutal

#### **Innocent / Innocent Rouge** (Fan Translation)
*Sakamoto doing French Revolution hyperviolence*

- Status: Complete (9 + 12 volumes)
- Why: Berserk-tier art, historical seinen
- Acquisition: Unlicensed, fan scans only

### "Hidden Gems" - Author Deep Cuts

#### **Tatsuki Fujimoto One-Shots**
*Pre-Chainsaw Man experimentation*

- "Just Listen to the Song of Lady Vengeance"
- "Nayuta of the Prophecy"
- "17-21" (short story collection)
- Why: You already have Look Back + Goodbye Eri; complete the catalog

#### **Mob Psycho 100 Reigen Spinoff**
*ONE's Reigen-focused side story*

- Status: Complete (1 volume)
- Note: Folder exists as `Mob Psycho 100 Reigen - The Man With Level 131 Max Spirit Power (2020)`
- Action: Verify CBZ files present

---

## Priority 4: Quality Upgrades

### Fan Scans to Official Releases

| Series | Current | Upgrade Available |
|--------|---------|-------------------|
| Billy Bat | Fan scans | None (unlicensed) |
| Holyland | Fan scans | None (unlicensed) |
| Kingdom | Fan scans | None (EN license unclear) |
| Hajime no Ippo | Mixed | Kodansha ongoing release |

### Resolution Upgrades

| Series | Current Source | Better Source |
|--------|---------------|---------------|
| Older Viz titles | 720p scans | 1r0n x1350+ rips |
| Pre-2015 releases | Mixed quality | danke-Empire repacks |

---

## Acquisition Strategy

### Usenet-First (Prowlarr -> SABnzbd)

Best for:
- Complete volume packs (1r0n, danke-Empire, aKraa)
- Category: 7030 (Comics)
- Search: `{series name} cbz` or `{series name} {release group}`

```bash
# Example Prowlarr search
curl -sL "$PROWLARR_URL/api/v1/search?query=undead+unluck+1r0n&categories=7030" \
  -H "X-Api-Key: $PROWLARR_API_KEY"
```

### Torrent Fallback (Nyaa/AniDex)

Best for:
- Weekly chapter releases
- Unlicensed series
- Search: Nyaa `{series name} {chapter}` filter: English-translated

### Tracker Priority

1. **Usenet** (fastest, best quality)
2. **Nyaa** (most complete manga selection)
3. **AniDex** (backup tracker)
4. **TokyoTosho** (legacy releases)

---

## Release Group Quality Guide

| Group | Specialty | Quality |
|-------|-----------|---------|
| **1r0n** | Official digital rips | Excellent (x1350+) |
| **danke-Empire** | Volume repacks | High |
| **Rillant** | Weekly chapters | Good |
| **aKraa** | Complete archives | Good |
| **TCB/Viz Scans** | Same-day chapters | Variable |

---

## Tracking Checklist

### Immediate Actions

- [ ] Re-acquire Blue Box v01-v18 (quarantined)
- [ ] Verify Jujutsu Kaisen v29-v30 complete
- [ ] Check Kagurabachi chapter coverage
- [ ] Verify Blue Lock Episode Nagi v06-v08

### Week 1 Targets

- [ ] Search Undead Unluck complete series (20v)
- [ ] Check Witch Hat Atelier availability
- [ ] Verify Gachiakuta chapter completeness
- [ ] Search Fujimoto one-shot collection

### Month 1 Targets

- [ ] Complete all "Priority 1" gaps
- [ ] Add 2-3 new series from recommendations
- [ ] Run `manga-naming-enforcer.sh --cleanup` on stubs

---

## Reading Order Guides

### For New Additions

**Undead Unluck**: Straight read v01-v20 (no spin-offs)

**Witch Hat Atelier**:
- Main series v01-v13
- Side stories in "Kitchen of Witch Hat" (optional)

**Real**:
- No spin-offs
- Works standalone from Slam Dunk (same universe, different cast)

### Complex Series Already in Collection

**JoJo's Bizarre Adventure**: Parts 1-9 in order (numbered in your collection)

**Tokyo Ghoul**:
1. Tokyo Ghoul (main)
2. Tokyo Ghoul JACK (prequel)
3. Tokyo Ghoul :re (sequel)

**Baki**: Parts 1-6 in numbered order (your collection is properly structured)

---

## Version History

| Date | Updates |
|------|---------|
| 2025-12-29 | Initial recommendations based on collection analysis |

---

**Related Documents:**
- `docs/MANGA_ECOSYSTEM_ANALYSIS.md` - Collection audit
- `docs/komga-corrupt-cbz.md` - Quarantined files
- `~/.claude/skills/manga-pitch-philosophy/SKILL.md` - Recommendation style guide
