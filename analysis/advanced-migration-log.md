# Advanced Documentation Migration Log

This log tracks the migration of legacy static HTML pages under `/advanced/` into the new VitePress content that lives in `docs/advanced`. It also records whether each migrated topic is currently surfaced in the "Advanced" sidebar configuration.

| Legacy HTML Source | Migrated Markdown | Migration Status | Navigation Status | Notes |
| --- | --- | --- | --- | --- |
| `advanced/index.html` | `docs/advanced/index.md` | ✅ Migrated | Linked via `Overview` entry (`/advanced/`) in `docs/.vitepress/config.js` | Entry appears at the top of the Advanced sidebar group. |
| `advanced/custom-configs.html` | `docs/advanced/custom-configs.md` | ✅ Migrated | Linked via `Custom Configurations` entry (`/advanced/custom-configs`) in `docs/.vitepress/config.js` | — |
| `advanced/performance.html` | `docs/advanced/performance.md` | ✅ Migrated | Linked via `Performance Tuning` entry (`/advanced/performance`) in `docs/.vitepress/config.js` | — |
| `advanced/backup-strategies.html` | `docs/advanced/backup-strategies.md` | ✅ Migrated | Linked via `Backup Strategies` entry (`/advanced/backup-strategies`) in `docs/.vitepress/config.js` | — |
| `advanced/hot-swap.html` | `docs/advanced/hot-swap.md` | ✅ Migrated | Linked via `Hot-Swap Workflows` entry (`/advanced/hot-swap`) in `docs/.vitepress/config.js` | — |
| `advanced/api-integration.html` | `docs/advanced/api-integration.md` | ✅ Migrated | Linked via `API Integration` entry (`/advanced/api-integration`) in `docs/.vitepress/config.js` | — |
| `advanced/troubleshooting.html` | `docs/advanced/troubleshooting.md` | ✅ Migrated | Linked via `Troubleshooting` entry (`/advanced/troubleshooting`) in `docs/.vitepress/config.js` | — |

## Navigation audit summary

All migrated Advanced topics are currently listed in the Advanced sidebar group defined in `docs/.vitepress/config.js`. No discrepancies were found between the migrated markdown files and the navigation configuration.
