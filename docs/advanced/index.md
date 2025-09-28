---
title: Advanced Operations Index
layout: doc
---

# Advanced Operations Library

Welcome to the consolidated reference for power users migrating from the
former `codex/collab` workspace. Each guide was verified during migration
and updated to reflect the current production state of the Usenet Media
Stack.

## How to Use This Section

- Start with **Prerequisites** to confirm your deployment matches the
  production baseline referenced throughout these guides.
- Jump directly to the topic that matches your task. The documents are
  written to stand on their own, but cross-links are included for shared
  workflows.
- Track any local customisations in your own overlay repository. The
  examples here assume you are working inside `main/docs/advanced`.

## Document Map

- [API Integration](./api-integration.md)
- [Backup Strategies](./backup-strategies.md)
- [Custom Configurations](./custom-configs.md)
- [Hot-Swap Procedures](./hot-swap.md)
- [Performance Optimisation](./performance.md)
- [Troubleshooting Playbook](./troubleshooting.md)
- [Migration Log](./migration-log.md)

## Prerequisites

- Production deployment completed with `./usenet deploy --auto`.
- Access to the `backups/` directory with recent configuration exports.
- Administrative access to Docker, ZFS/Btrfs, and systemd where relevant.

## Change Tracking

Every advanced document now lives under version control in this main
repository. Use `git blame` and pull requests to audit future edits.
