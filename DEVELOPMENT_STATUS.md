# 🚀 Development Status Report (2025-12-18)

## ✅ **Current State (Truthful)**

- **Plex-first stack**: Plex is the primary media server; Overseerr is the request manager.
- **Comics stack online**: Komga + Komf + Kavita are running and healthy.
- **Download clients/indexers**: SABnzbd, Prowlarr, Sonarr, Radarr, Lidarr, Whisparr, Bazarr up.
- **TRaSH + Recyclarr**: Guidance reviewed; Recyclarr scaffolded but sync not yet run.
- **Docs**: Updated for Plex-first, but path normalization for “one-line deploy” is still pending.

## 🔧 **Open Issues / Gaps**

1) **Plex not yet claimed**
   - Requires `PLEX_CLAIM` + first-run login; Plex API token not yet captured.

2) **Audiobookshelf not running**
   - Optional stack uses `docker-compose.reading.yml`; paths still need normalization.

3) **One-line deploy not guaranteed**
   - Some compose files use hard-coded paths (/mnt vs /var/mnt).
   - `.env` contract needs explicit validation + doc alignment.

## 🎯 **Next Priorities**

1) **One-line deploy** (highest priority)
   - Normalize compose paths
   - Define `.env` contract + validation
   - Document required human inputs
   - Cold reboot acceptance test

2) **Plex bring-up**
   - Claim token + first-run login
   - Libraries + hardware transcode
   - Overseerr ↔ Plex integration

3) **Recyclarr sync**
   - Add API keys, verify includes, run sync for Sonarr/Radarr

4) **Comics integrity**
   - Repair/re-download corrupt CBZs flagged by Komga

## 🧪 **Validation Snapshot**

- Latest HTTP probe: all core services 200/OK except **Plex** and **Audiobookshelf** (down).
- UI automation requires Playwright if `validate-services.js` is used.

---

**Status**: 🟡 **Close** — core services are online, but Plex claim + path normalization are required for true one-line deploy.
