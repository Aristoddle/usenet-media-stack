# Usenet Onboarding (Providers → Indexers → Automation)

> A pragmatic walkthrough for new users: pick a provider, wire an indexer, point Prowlarr/Sonarr/Radarr to SABnzbd, and verify downloads end up in the right folders.

## 1) Pick a provider (and why it matters)
- Look for: high **retention** (4000–5000+ days), good **completion**, SSL (563/443), and connection limits that match your automation.
- Common choices: Newshosting, Eweka, UsenetExpress, Frugal. Consider a backup block account if you hit takedowns.
- Enter provider creds in SABnzbd (Servers) and enable SSL.

## 2) Pick an indexer
- Indexers observe binary groups and publish NZBs. They are separate from providers.
- Examples: NZBGeek (paid/public), DogNZB/DrunkenSlug (invite). Import into Prowlarr so all Arr apps share one place for indexers.
- In Prowlarr: add the indexer → set API key → Sync to Sonarr/Radarr/Readarr/Whisparr/Lidarr with “Sync Level: Full Sync”.

## 3) Configure the download client
- Use SABnzbd (default in this stack). Set host/port/API key in Prowlarr and Arr apps.
- Paths: set SAB “Completed Download Folder” to `/downloads/completed` (maps to host downloads path).
- Enable SSL and set connection count to your provider’s allowed max.

## 4) Wire the Arr apps
- In each Arr app, add your media root: Movies → `/movies`, TV → `/tv`, Books → `/books`, Comics → `/comics` (adjust to your host mapping).
- Quality/Profiles: pick TRaSH guides or your own; keep them consistent across Arr apps for fewer mismatches.
- Connect Download Client: SABnzbd via API key.
- Connect Indexer: use Prowlarr “Sync App” to push configs automatically.

## 5) Verify end-to-end
1. In Sonarr/Radarr, search for a test item → should show releases.
2. Grab → Prowlarr hands NZB to SAB → SAB downloads to `/downloads` → Arr imports to `/tv` or `/movies`.
3. Check logs if it stalls: SAB history, Arr “Activity” for import failures, Prowlarr API errors.

## 6) Folder mappings (this stack)
- Host downloads: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Downloads` (adjust per your `.env.local`).
- Media roots: `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Movies`, `/tv`, `/books`, `/comics`.
- Containers see these as `/downloads`, `/movies`, `/tv`, `/books`, `/comics` via compose volume mappings.

## 7) Security & hygiene
- Always use SSL NNTP ports (563/443). Do not share provider or indexer keys.
- Respect indexer API limits; keep Prowlarr as the single sync point to avoid duplicating hits.
- Back up configs: Arr apps, Prowlarr, SABnzbd configs live under your `*Config` directories on the OneDrive-backed disk.

## 8) Troubleshooting quick hits
- “No releases”: indexer key wrong, VIP tier required, or categories not mapped → re-check Prowlarr → Apps mappings.
- “Import failed”: path mismatch between SAB and Arr; verify container paths align (`/downloads` ↔ host downloads path).
- “Slow/failed downloads”: switch to alternate provider or add block account; verify SSL and connections.

## 9) Learn more
- [Usenet Primer](/usenet-primer)
- [Usenet (Wikipedia)](https://en.wikipedia.org/wiki/Usenet)
- [NZB format](https://docs.newznab.com/nzb/)
