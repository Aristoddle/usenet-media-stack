# FAQ

## Do I need Docker or Podman?
- On Bazzite/Deck: Podman is built-in; Docker (moby-engine) is staged and becomes available after a reboot. Use Podman now; switch to Docker when you need Swarm/Compose v2.

## Can I reboot right now?
- Not while long transfers (e.g., `rsync-comics`) are running. Finish them first, then reboot to activate Docker.

## Where are my files and configs?
- Media: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/<Movies|TV|Comics|Books|Audiobooks>`
- Configs: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/*Config`
- OneDrive comics source (GVFS): `/run/user/1000/gvfs/onedrive:.../Books/Comics/`

## How do I add comics to Komga?
- Let `rsync-comics` finish, then in Komga add a library pointing to `/comics` (container path). OPDS: `http://<host>:8081/opds/v1.2`.

## How do I set up ebooks/audiobooks?
- After Docker is enabled, run `docker compose -f docker-compose.reading.yml up -d` for Calibre, Calibre-Web, Audiobookshelf. See `reading-stack.md`.

## Where do secrets live?
- `.env.local` (gitignored) for indexer/API keys; Kometa token in `KometaConfig/config.yml`. See `secrets.md`.

## My downloads won’t import
- Check path mappings: SAB writes to `/downloads` (container) → host downloads path; Arr import paths must match (`/tv`, `/movies`, etc.).
- Verify Prowlarr → Apps sync; wrong categories or API keys cause “no releases.”

## How do I check service health?
- `podman ps` (now) or `docker ps` (post-reboot). Healthchecks should be present for Bazarr/Overseerr/Jellyfin/Tdarr.

## What’s the legal stance?
- Use SSL, keep keys private, respect copyrights. Prefer public-domain/CC/open content; support creators for works you keep.

## Where can I learn Usenet basics?
- Read [Usenet Primer](/usenet-primer) and [Usenet Onboarding](/usenet-onboarding) for provider/indexer/client flow.
