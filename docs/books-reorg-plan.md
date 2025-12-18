# Books Reorg Plan (Non-Comics)

Goal: consolidate non-comics content into a clear, canonical layout so Kavita/Audiobookshelf (and optional Plex/Kometa) can index reliably.

## Canonical layout target
- `/Books/Comics` (already in place)
- `/Books/Audiobooks`
- `/Books/Ebooks`
- `/Books/Podcasts` (optional; only create if we commit to podcasts)

## Current state (inventory snapshot)
- `Audiobooks` (~20G, mostly mp3/m4b)
- `Default` (~5G, mp3)
- `Real Books` (~4.5G, mix of mp3/epub/pdf)
- `Calibre` (~462M, opf/jpg/cbz)
- `Readarr` (~104M, epub + nfo)
- `Spoken` (empty)
- `eBooks` (empty)

## Policy
- **Drop Calibre + Readarr** going forward (stop adding content there).
- **Do not delete** until we verify content is fully moved.
- Merge **Default** + audio from **Real Books** into `/Books/Audiobooks`.
- Merge ebooks from **Real Books** + **Readarr** into `/Books/Ebooks`.

## Suggested move strategy (safe, reversible)
1) Create canonical folders:
   - `/Books/Audiobooks`, `/Books/Ebooks` (if not already present).
2) Dry-run counts:
   - Run `scripts/books-inventory.sh` and save output.
3) Move audio:
   - Copy mp3/m4b/flac from `Default` + `Real Books` into `/Books/Audiobooks` preserving subfolders.
4) Move ebooks:
   - Copy epub/pdf/mobi/azw3 from `Real Books` + `Readarr` into `/Books/Ebooks`.
5) Verify:
   - Re-run inventory and compare file counts.
6) Cleanup:
   - Archive or remove legacy folders once confirmed as subsets.

## Tooling impact
- **Kavita** should point to `/Books/Ebooks`.
- **Audiobookshelf** should point to `/Books/Audiobooks`.
- **Podcasts**: if we decide on podcasts, mount `/Books/Podcasts` in Audiobookshelf.

## Notes
- Keep comics in `/Books/Comics` (already stable).
- If the other agent handles moves, ask them to record before/after counts in KG.
