---
title: Advanced Docs Migration Log
layout: doc
---

# Advanced Documentation Migration Log

The following table tracks the migration of advanced documentation from
`codex/collab` into the canonical `main/docs/advanced` directory.

- `index.md`: `codex/collab/index.md` → `docs/advanced/index.md`
- `api-integration.md`: `codex/collab/api-integration.md`
  → `docs/advanced/api-integration.md`
- `backup-strategies.md`: `codex/collab/backup-strategies.md`
  → `docs/advanced/backup-strategies.md`
- `custom-configs.md`: `codex/collab/custom-configs.md`
  → `docs/advanced/custom-configs.md`
- `hot-swap.md`: `codex/collab/hot-swap.md`
  → `docs/advanced/hot-swap.md`
- `performance.md`: `codex/collab/performance.md`
  → `docs/advanced/performance.md`
- `troubleshooting.md`: `codex/collab/troubleshooting.md`
  → `docs/advanced/troubleshooting.md`

## Verification Checklist

- [x] Content reviewed for accuracy against current production workflows.
- [x] Internal links updated to reflect new directory structure.
- [x] Front matter normalised for the documentation site generator.
- [x] Migration recorded in repository history with this log.

## Next Steps

- Publish the updated documentation site (Cloudflare Pages deploy pending).
- Archive the legacy `codex/collab` workspace or mark it read-only to avoid
  future divergence (backlog).
