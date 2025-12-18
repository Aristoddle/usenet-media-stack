# FAQ

## Do I need Docker or Podman?
- Full stack requires **Docker Engine + Compose v2**. Podman is only supported for scoped/light services (e.g., Komga/reading stack) when explicitly noted.

## Can I reboot right now?
- Not while long transfers (e.g., `rsync-comics`) are running. Finish them first, then reboot to activate Docker.

## Where are my files and configs?
- Video media: `${MEDIA_ROOT}/<movies|tv>` (example: `/var/mnt/fast8tb/Local/media/<movies|tv>`)
- Books: `${BOOKS_ROOT}/<Comics|Ebooks|Audiobooks>`
- Configs: `${CONFIG_ROOT}` (plus `${AUDIOBOOKSHELF_CONFIG}`/`${KOMETA_CONFIG}` if used)
- OneDrive comics source (GVFS): `/run/user/1000/gvfs/onedrive:.../Books/Comics/`

## How do I add comics to Komga?
- Let `rsync-comics` finish, then in Komga add a library pointing to `/comics` (container path). OPDS: `http://<host>:8081/opds/v1.2`.

## How do I set up ebooks/audiobooks?
- Ebooks are served via Kavita (main compose). Audiobooks use Audiobookshelf: `docker compose -f docker-compose.reading.yml up -d`. See `reading-stack.md`.

## What Plex clients should I use?
- **Plexamp** for music/audio.
- **Plex HTPC** for TV/console setups.
- Native Plex apps on Smart TVs and mobile devices for everything else.

## Where do secrets live?
- `.env` (gitignored) for indexer/API keys; Kometa token in `${KOMETA_CONFIG}/config.yml`. See `secrets.md`.

## My downloads won’t import
- Check path mappings: SAB writes to `/downloads` (container) → host downloads path; Arr import paths must match (`/tv`, `/movies`, etc.).
- Verify Prowlarr → Apps sync; wrong categories or API keys cause “no releases.”

## How do I check service health?
- `podman ps` (now) or `docker ps` (post-reboot). Healthchecks should be present for Bazarr/Overseerr/Plex/Tdarr.

## What’s the legal stance?
- Use SSL, keep keys private, respect copyrights. Prefer public-domain/CC/open content; support creators for works you keep.

## Where can I learn Usenet basics?
- Read [Usenet Primer](/usenet-primer) and [Usenet Onboarding](/usenet-onboarding) for provider/indexer/client flow.
