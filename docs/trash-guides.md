# TRaSH Guides Alignment (Sonarr/Radarr)

Use TRaSH Guides to keep Sonarr/Radarr quality profiles and custom formats consistent across the stack. This doc captures our local preferences and how to apply them.

## Local preferences (this stack)
- Target: **high-bitrate 4K**, prefer **HDR**.
- Codec preference: **best supported** (favor HEVC/x265 for 2160p where available).
- Long-term: re-encode non-optimal releases with HandBrake (policy tracked in KG).

## Why TRaSH Guides
TRaSH Guides provide a community‑maintained baseline for:
- Quality profiles (upgrade logic + cutoff behavior).
- Custom formats (HDR/DV, x265, scene groups, unwanted tags).
- Quality definitions (file size ranges).

Keep these aligned across Sonarr + Radarr to reduce mismatches and improve upgrade logic.

## Implementation options
1) **Manual setup** in Sonarr/Radarr (UI)
   - Create/adjust quality profiles.
   - Import custom formats and set scores.
   - Set minimum custom format score to enforce requirements.

2) **Recyclarr sync (recommended)**
   - Define Sonarr/Radarr instances in `recyclarr.yml`.
   - Reference TRaSH templates via `include`.
   - Keep API keys out of git using `secrets.yml`.

Example template file: `config/examples/recyclarr/recyclarr.yml`
Secrets template: `config/examples/recyclarr/secrets.yml`

## Recyclarr file layout (Docker-friendly)
- Recyclarr reads `recyclarr.yml` from its app data directory (e.g., `/config/recyclarr.yml` in Docker).
- You can also place multiple YAML files in `/config/configs/` and Recyclarr will load them all.
- Keep secrets in `secrets.yml` in the same app data directory and reference with `!secret` in YAML.

## Recyclarr Docker notes
- We standardize on Docker-only tooling in this repo (no host binaries).
- The Docker image uses `/config` as the app data directory.
- Configure `CRON_SCHEDULE` and `TZ` in the container if you want automated syncs.

### Compose usage (recommended)
Bring Recyclarr up on the same Compose project so it can reach `sonarr`/`radarr` by service name:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.recyclarr.yml \
  up -d recyclarr
```

We do not support running Recyclarr outside Docker in this stack.

### Run checklist
1) Copy templates to local config:
   - `config/examples/recyclarr/recyclarr.yml` → `config/recyclarr/recyclarr.yml`
   - `config/examples/recyclarr/secrets.yml` → `config/recyclarr/secrets.yml`
2) Fill API keys in `config/recyclarr/secrets.yml`.
3) Start Recyclarr:
   - `docker compose -f docker-compose.yml -f docker-compose.recyclarr.yml up -d recyclarr`
4) Validate in Sonarr/Radarr UI (quality profiles + custom formats applied).

## 4K HDR policy mapping
When selecting TRaSH templates or manual CF scoring:
- Prefer HDR (HDR10/10+ / Dolby Vision) CFs over SDR.
- Use x265/HEVC CFs for 2160p content; avoid x265 for 1080p unless explicitly desired.
- Set minimum CF score so "must-have" formats gate upgrades.

## Concrete profile choices (draft)
- **Sonarr**: WEB-2160p (v4) profile + matching custom formats.
- **Radarr**: UHD Bluray + WEB profile + matching custom formats.

These are the TRaSH baseline profiles for high-quality 4K workflows; we can tune scores after sync.

## Suggested workflow
1) Review TRaSH Guides for Sonarr/Radarr profiles + custom formats.
2) Choose 4K HDR templates and/or define a custom profile.
3) Apply via Recyclarr and validate in the UI.
4) Revisit quality definitions to align with high‑bitrate targets.

## References
- TRaSH Guides: https://trash-guides.info/
- Recyclarr: https://recyclarr.dev/
