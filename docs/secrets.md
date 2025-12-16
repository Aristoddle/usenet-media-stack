# Secrets & Environment Layout

## Files
- `.env.local` (gitignored):
  - `PROWLARR_API_KEY`
  - NZB provider creds (e.g., `NZBGEK_API_KEY`, `SABNZBD_API_KEY`)
  - Domain overrides if needed (`DOMAIN`, `TZ`, etc.)
- `/mnt/fast8tb/Cloud/OneDrive/KometaConfig/config.yml`: Plex token/URL for Kometa.
- Calibre/Audiobookshelf configs live under their `*Config` dirs on OneDrive-backed disk.

## Guidance
- Keep `.env.local` out of git; copy from `.env.example` and fill in locally.
- For CI: do **not** store real keys; the Cloudflare deploy only needs `CF_API_TOKEN`.
- For local scripting: use `op run -- env` or `direnv` if you prefer, but `.env.local` is the source of truth for compose.

## After reboot (Docker)
- Ensure `.env.local` is present in repo root before `docker compose up -d`.
- Verify Kometa config exists if you enable Kometa service.
