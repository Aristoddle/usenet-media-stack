---
title: Custom Configuration Patterns
layout: doc
---

# Custom Configuration Patterns

This reference preserves the original `codex/collab/custom-configs.md`
while aligning examples with the latest configuration layout in `config/`.

## Configuration Philosophy

- Keep vendor defaults intact. Layer overrides through environment files
  or bind-mounted directories instead of editing upstream templates.
- Document every override in version control; prefer one configuration
  file per feature flag.
- Test changes with `./usenet validate --fix` before rolling them into
  production deployments.

## Overlay Structure

```
config/
├── overrides/
│   ├── jellyfin/
│   ├── sonarr/
│   └── radarr/
├── profiles/
│   ├── gpu-accelerated.yml
│   └── low-power.yml
└── templates/
    └── docker-compose.partial.yml
```

- `overrides/` contains per-service config fragments that mount into the
  running containers via the CLI.
- `profiles/` defines hardware-specific toggles consumed by the storage
  and hardware commands.
- `templates/` stores Compose fragments that can be merged during deploys.

## Creating a New Override

1. Duplicate a template from `config/examples` into
   `config/overrides/<service>`.
2. Document the change inside the directory using `README.override.md`.
3. Register the override via `./usenet services enable <service> --override`.
4. Run `./usenet deploy --validate-only` to confirm the override merges.

## Environment Variables

- Store secrets in `.env` using the `usenet env` helper. Never commit the
  file to the repository.
- Use `USENET_PROFILE` to select hardware profiles dynamically.
- Reference environment variables inside Compose overrides using the
  `${VARIABLE:?message}` syntax so missing values fail fast.

## Configuration Promotion Workflow

1. Prototype locally and commit changes to a feature branch.
2. Run targeted service tests using the scripts in `lib/test/integration`.
3. Submit a pull request documenting the behaviour change and rollback
   plan.
4. After merge, tag the repository so you can map deployments to commits.

## Rollback Strategy

- Maintain previous overrides in `config/archive/<date>`. The CLI can use
  archived directories as drop-in replacements if a regression appears.
- Use `docker compose logs <service>` to confirm the restored override
  resolves the issue before resuming automation.
