# Comics Gap Plan (Bazzite / Komga)

Context
- Host: Bazzite (Ryzen 7 7840HS, 96 GB RAM), rootless Podman.
- Komga: http://192.168.6.167:8081 (creds: j3lanzone@gmail.com / fishing123), library Steambox_Comics -> `/comics_mirror` (symlink mirror of OneDrive comics).
- Komf: http://192.168.6.167:8085, config at `/var/home/deck/komf-config/application.yml` with ComicVine/AniList/MangaUpdates/MangaDex keys enabled.
- Latest gap report: `/tmp/komga_gap_report.md` (generated 2025-12-11 19:38 local).

Scan summary
- Series scanned: 51
- Series with gaps: 20
- Top gap counts (missing issues/chapters):
  - Bug Ego (Viz) [EN]: 2009
  - Choujin X (Viz) [EN]: 1997
  - Frieren (Viz) [EN]: 1997
  - Jujutsu Kaisen (Viz) [EN]: 1969
  - Blue Box (Viz) [EN]: 1946
  - Deadpool (Marvel) [EN]: 1936
  - Kagurabachi (Viz) [EN]: 1920
  - JoJo’s Bizarre Adventure (Viz) [EN]: 1835
  - Chainsaw Man (Viz) [EN]: 1802
  - Dragon Ball (Viz) [EN]: 1493
(Full per-series details: see `/tmp/komga_gap_report.md`.)

Immediate actions (next agent loop)
1) Acquire prioritized gaps (top 10 above) via Nyaa/MangaDex/other sources from dotfiles “manga tools”; download to staging, then move into `/run/media/deck/Fast_8TB_Ser7/Cloud/OneDrive/Comics`, rescan Komga, rerun gap report.
2) After each acquisition batch, sync outward to OneDrive (rclone) to keep cloud copy aligned.
3) If Komga series count stays low, verify mirror completeness and exclusions; repeat deep scan.

Operational commands
- Deep scan: `curl -u 'j3lanzone@gmail.com:fishing123' -X POST 'http://localhost:8081/api/v1/libraries/0NV2WQE6RM4BP/scan?deep=true'`
- Gap report: `cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack && KOMGA_URL=http://localhost:8081 KOMGA_USER='j3lanzone@gmail.com' KOMGA_PASS='fishing123' python3 scripts/komga-gap-report.py > /tmp/komga_gap_report.md`
- Komf restart (after config edits): `podman restart komf`

Notes / TODO
- Series count (51) is below the ~83 series dirs on disk; check exclusion patterns and mirror completeness during next loop.
- Keep secrets out of git: provider keys live in `usenet-media-stack/.env.local` (ignored) and `/var/home/deck/komf-config/application.yml`.
