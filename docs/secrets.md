# Secrets & Environment Layout

## Files
- `.env` (gitignored):
  - `PROWLARR_API_KEY`
  - NZB provider creds (e.g., `NZBGEK_API_KEY`, `SABNZBD_API_KEY`)
  - Domain overrides if needed (`DOMAIN`, `TZ`, etc.)
- `config/recyclarr/secrets.yml` (gitignored):
  - `sonarr_api_key`
  - `radarr_api_key`
- `/var/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml`: Plex token/URL for Kometa.
- Audiobookshelf config lives under its `*Config` dir on OneDrive-backed disk.

## Guidance
- Keep `.env` out of git; copy from `.env.example` and fill in locally.
- For CI: do **not** store real keys; the Cloudflare deploy only needs `CF_API_TOKEN`.
- For local scripting: use `op run -- env` or `direnv` if you prefer, but `.env` is the source of truth for compose.

## Secret scanning
- Pre-commit: use gitleaks to block accidental commits (`.pre-commit-config.yaml`).
- CI: enable GitHub secret scanning + run gitleaks in CI if desired.

## After reboot (Docker)
- Ensure `.env` is present in repo root before `docker compose up -d`.
- Verify Kometa config exists if you enable Kometa service.
