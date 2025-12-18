# Secrets & Environment Layout

## Files
- `.env` (gitignored):
  - `PROWLARR_API_KEY`
  - NZB provider creds (e.g., `NZBGEK_API_KEY`, `SABNZBD_API_KEY`)
  - `PLEX_CLAIM` (first-time Plex setup)
  - Domain overrides if needed (`DOMAIN`, `TZ`, etc.)
- `config/recyclarr/secrets.yml` (gitignored):
  - `sonarr_api_key`
  - `radarr_api_key`
- `${KOMETA_CONFIG}/config.yml`: Plex token/URL for Kometa (if enabled).
- Audiobookshelf config lives under `${AUDIOBOOKSHELF_CONFIG}`.

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
