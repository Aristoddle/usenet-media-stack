# Usenet Primer: How It Actually Works

> An orientation to the network, its separation of roles (providers vs indexers vs download clients), and how binaries/NZBs exist alongside the original message-board heritage.

## What Usenet is (and is not)
- A 1980s-era distributed discussion system (NNTP) where servers sync articles across peers. Originally text-only; later added binaries via yEnc/MIME splits.
- There is no single “Usenet company.” Each **provider** runs servers and retention; **indexers** watch groups and build searchable catalogs; **clients** (SABnzbd/NZBGet) fetch articles and reassemble files.
- It is not BitTorrent: there is no swarm/peer upload; downloads come from provider servers you pay for.

## Role separation (the “pachinko” model)
- **Providers** (e.g., Newshosting, Eweka, UsenetExpress) store articles and honor takedowns; retention and completion vary.
- **Indexers** (e.g., NZBGeek, DogNZB) watch binary groups, de-dup releases, and expose APIs/search; they usually require an invite/fee.
- **Clients** (SABnzbd, NZBGet) download via NNTP using provider creds; automation tools (Sonarr/Radarr/Readarr/Whisparr/Lidarr) talk to indexers through Prowlarr and hand NZBs to the client.
- **Why this matters:** keeping these roles separate reduces legal coupling—indexers list, providers serve, clients fetch.

## Binaries, NZBs, and retention
- Binaries are split into many articles across `alt.binaries.*` groups; NZB files are just XML pointers to those article IDs.
- **Retention** = how many days a provider keeps articles. Higher retention improves old releases; completion depends on peering/takedowns.
- **Obfuscation**: filenames often scrambled; indexers supply meaningful names and metadata.

## Text Usenet still exists
- Classic discussion groups remain (mirrored in Google Groups and text-only feeds). They’re part of cultural history: old FAQs, source code drops, and conversations remain valuable reference material.

## Safety & etiquette
- Use SSL NNTP ports (563/443) with auth; do not share provider or indexer keys.
- Mind automation limits: API hit caps on indexers and connection limits on providers.
- Respect local laws and copyrights; many groups host public-domain or permissively shared content—support creators when you can.

## How this stack uses Usenet
- **Prowlarr** centralizes indexers and feeds them to Sonarr/Radarr/Readarr/Whisparr/Lidarr.
- **SABnzbd** (or NZBGet) downloads from your paid provider using NZB instructions.
- **Arr apps** monitor your libraries, request from indexers, and hand NZBs to SABnzbd automatically.

## Finding and joining indexers
- Public/paid: NZBGeek, DrunkenSlug (invite), DogNZB (invite). Each has APIs for Prowlarr.
- Community reference threads often list current indexers and mirrors; expect churn and invites.
- Keep `.env.local` up to date with API keys before running the stack.

## Further reading
- [Usenet (Wikipedia)](https://en.wikipedia.org/wiki/Usenet)
- [NNTP / RFC 977](https://www.rfc-editor.org/rfc/rfc977)
- [NZB file format spec](https://docs.newznab.com/nzb/)
- [List of Usenet providers](https://en.wikipedia.org/wiki/Comparison_of_Usenet_newsreaders#Usenet_services)
- [Usenet history and culture overview](https://www.five-ten-sg.com/mapper/usenet-history.html)

## High-value public archives
- [Anna's Archive](https://annas-archive.org/) — open-access meta-archive for books/papers/comics.
- [Emulation General Wiki](https://emulation.gametechwiki.com/) — emu/ROM knowledge base.
- [FMHY](https://fmhy.pages.dev/) — free-media meta list.
- [Vimm's Lair](https://vimm.net/) — classic console manuals/ROM preservation info.

Use these for learning and preservation; follow the laws in your jurisdiction and respect creator rights.
