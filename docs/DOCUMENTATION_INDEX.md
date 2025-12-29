# Documentation Index

Comprehensive table of contents for the Usenet Media Stack documentation.

**Last Updated**: 2025-12-29 (Post-Audit)

---

## Getting Started

New to the stack? Start here.

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started/index.md) | Overview and quick orientation |
| [Installation](getting-started/installation.md) | Step-by-step installation guide |
| [First Deployment](getting-started/first-deployment.md) | Bazzite-focused deployment walkthrough |
| [System Requirements](requirements.md) | Hardware and software prerequisites |
| [FAQ](faq.md) | Frequently asked questions |

---

## Architecture

Understand how the stack is designed.

| Document | Description |
|----------|-------------|
| [How It Actually Works](architecture/index.md) | Core architecture overview |
| [Design Philosophy](architecture/design-philosophy.md) | Principles behind the stack design |
| [Media Library Architecture](LIBRARY_ARCHITECTURE.md) | Library structure and organization |
| [Media Acquisition Architecture](MEDIA_ACQUISITION_ARCHITECTURE.md) | How media flows through the system |
| [Volume Safety Model](architecture/volume-safety.md) | Docker volume design for safety |
| [Docker Networking Solution](networking.md) | Network + Tailscale configuration |

---

## Storage

Storage architecture and management.

| Document | Description |
|----------|-------------|
| [Storage Management](storage/index.md) | Storage overview and CLI commands |
| [Storage Architecture](storage/architecture.md) | mergerfs + btrfs for travel-ready server |
| [Storage Quick Reference](STORAGE_AND_REMOTE_ACCESS.md) | Pool paths and remote access summary |
| [btrfs Migration Plan](storage/BTRFS_MIGRATION_PLAN.md) | 10-drive architecture migration |

---

## Operations

Day-to-day operational guides.

| Document | Description |
|----------|-------------|
| [Operations Runbook](ops-runbook.md) | Daily checks and maintenance |
| [Stack Usage Guide](STACK_USAGE_GUIDE.md) | How to use the running stack |
| [Deployment Guide](deployment.md) | Deploying to beppesarrstack.net |
| [Service Logs Reference](SERVICE_LOGS.md) | Logs and status monitoring |
| [Audit Methodology](AUDIT_METHODOLOGY.md) | How to audit the stack |
| [Stack Optimization Audit](STACK_OPTIMIZATION_AUDIT.md) | Performance audit checklist |
| [Strategic Roadmap](STRATEGIC_ROADMAP.md) | 5-tier action plan and priorities |

---

## Services

Individual service configuration and guides.

| Document | Description |
|----------|-------------|
| [Working Services](SERVICES.md) | Core working services documentation |
| [arr Stack Wiring Guide](ARR_STACK_WIRING.md) | Sonarr/Radarr/etc wiring configuration |
| [Downloaders](downloaders.md) | Download client setup (SABnzbd, etc.) |
| [Local Endpoints](local-endpoints.md) | Loopback and LAN endpoints |
| [Downloader Endpoints](COMPATIBILITY.md) | Compose file compatibility matrix |

### Video Processing

| Document | Description |
|----------|-------------|
| [Tdarr Guide](TDARR.md) | Transcoding configuration and troubleshooting |
| [ISO Re-encoding Workflow](ISO_REENCODING_WORKFLOW.md) | Disc image processing |

### Reading Stack

| Document | Description |
|----------|-------------|
| [Reading Stack](reading-stack.md) | Comics, ebooks, and audiobooks |
| [Komga + Komf Quickstart](komga.md) | Comics and OPDS setup |
| [Komga Corrupt CBZ](komga-corrupt-cbz.md) | Handling corrupt CBZ files |
| [Suwayomi Setup](suwayomi-setup.md) | Tachidesk manga server |

### Manga Acquisition

| Document | Description |
|----------|-------------|
| [Manga Acquisition Pipeline](MANGA_ACQUISITION_PIPELINE.md) | Two-track manga acquisition system |
| [Manga Collection Topology](MANGA_COLLECTION_TOPOLOGY.md) | Folder structure and organization |
| [Manga Integration Status](MANGA_INTEGRATION_STATUS.md) | Current gaps and next steps |
| [Collection Gap-Fill Strategy](COLLECTION_GAP_FILL_STRATEGY.md) | Filling collection gaps |

---

## Advanced

Power user documentation.

| Document | Description |
|----------|-------------|
| [Advanced Operations](advanced/index.md) | Advanced operations library |
| [API Integration](advanced/api-integration.md) | Integrating with service APIs |
| [Backup Strategies](advanced/backup-strategies.md) | Data backup approaches |
| [Custom Configurations](advanced/custom-configs.md) | Custom configuration patterns |
| [Hot-Swap Procedures](advanced/hot-swap.md) | Drive hot-swap operations |
| [Performance Optimisation](advanced/performance.md) | SVT-AV1 and system tuning |
| [Troubleshooting Playbook](advanced/troubleshooting.md) | Debugging common issues |
| [Migration Log](advanced/migration-log.md) | Advanced docs migration history |

### CLI Reference

| Document | Description |
|----------|-------------|
| [CLI Reference](cli/index.md) | Command-line interface guide |
| [Storage CLI](cli/storage.md) | Storage management commands |

### Networking & Security

| Document | Description |
|----------|-------------|
| [Docker Networking](networking.md) | Network config + Tailscale remote access |
| [Security Guide](SECURITY.md) | Security best practices |
| [Secrets Layout](secrets.md) | Environment and secrets management |

---

## Reference

Supplementary and reference documentation.

| Document | Description |
|----------|-------------|
| [Usenet Primer](usenet-primer.md) | How Usenet actually works |
| [Usenet Onboarding](usenet-onboarding.md) | Providers, indexers, and automation |
| [TRaSH Guides Alignment](trash-guides.md) | Sonarr/Radarr optimization |
| [Free Media Resources](free-media.md) | Community and legal media sources |
| [Hardware Optimization](hardware/index.md) | Hardware-specific tuning |
| [Memory KG Spec](memory-spec.md) | Hardened memory specification |
| [Agents Guide](agents.md) | Agent states and priorities |
| [User Taste Profile](USER_TASTE_PROFILE.md) | Personal collection context |
| [Personal Collection Context](PERSONAL_COLLECTION_CONTEXT.md) | Collection preferences |
| [Visualizations](visualizations.md) | Advanced system visualizations |
| [USB Content Inventory](USB_CONTENT_INVENTORY.md) | USB drive content for import |

### Future Planning

| Document | Description |
|----------|-------------|
| [vNext Cluster Plan](vnext-cluster-plan.md) | **ASPIRATIONAL** - Future 13-node cluster architecture |

### Runbook

| Document | Description |
|----------|-------------|
| [Developer Environment](runbook/dev-environment.md) | Development setup reference |
| [Wiring Notes](runbook/WIRING_NOTES.md) | Service wiring notes (2025-12-16) |

### Decisions

Architecture decision records.

| Document | Description |
|----------|-------------|
| [Stack Health Audit](decisions/2025-12-29-stack-health-audit.md) | Readarr retirement, service status |
| [Manga Topology Review](decisions/2025-12-29-manga-topology-adversarial-review.md) | Manga folder structure decision |
| [ROM Acquisition Pipeline](decisions/2025-12-18-rom-acquisition-pipeline.md) | ROM pipeline architecture decision |
| [ROM Pipeline Test Cases](decisions/2025-12-18-rom-pipeline-test-cases.md) | ROM pipeline E2E test cases |

---

## Testing

| Document | Description |
|----------|-------------|
| [Testing Guide](testing.md) | CLI testing and stability |
| [Test Report](test-report.md) | Local stack validation results |

---

## Project Tracking

| Document | Description |
|----------|-------------|
| [TODO](TODO.md) | Active task list (check STRATEGIC_ROADMAP.md for current priorities) |

---

## Audits

| Document | Description |
|----------|-------------|
| [Audit Results 2025-12-29](AUDIT_RESULTS_2025-12-29.md) | Documentation audit and cleanup |

---

## Archive

Historical and completed project documentation.

### Audits

| Document | Description |
|----------|-------------|
| [Library Contamination Audit](archive/audits/LIBRARY_CONTAMINATION_AUDIT_2025-12-27.md) | 2025-12-27 contamination audit |
| [Media Pool Duplicates Report](archive/audits/MEDIA_POOL_DUPLICATES_REPORT_2025-12-27.md) | 2025-12-27 duplicates analysis |

### Completed Projects

| Document | Description |
|----------|-------------|
| [Manga Remediation Swarm](archive/projects/MANGA_REMEDIATION_SWARM.md) | Multi-agent manga collection remediation |
| [Post-Migration Plan](archive/projects/POST_MIGRATION_PLAN.md) | mergerfs migration (completed) |

### Session Notes

| Document | Description |
|----------|-------------|
| [Overnight Session 2025-12-29](archive/sessions/OVERNIGHT_SESSION_2025-12-29.md) | USB inventory and tools session |

---

## Quick Links

**Most Used**:
- [Stack Usage Guide](STACK_USAGE_GUIDE.md) - Daily usage
- [Working Services](SERVICES.md) - All service URLs and ports
- [Tdarr Guide](TDARR.md) - Transcoding
- [Strategic Roadmap](STRATEGIC_ROADMAP.md) - Current priorities

**Troubleshooting**:
- [Troubleshooting Playbook](advanced/troubleshooting.md)
- [Tdarr Guide](TDARR.md) (recovery procedures)
- [Komga Corrupt CBZ](komga-corrupt-cbz.md)

---

*Last audit: 2025-12-29 - See [AUDIT_RESULTS_2025-12-29.md](AUDIT_RESULTS_2025-12-29.md) for details*
