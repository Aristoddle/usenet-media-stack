# Manga Collection Remediation Swarm Specification

**Version**: 1.0.0
**Created**: 2025-12-21
**Philosophy**: "Measure many times before you cut once"
**Status**: Design Complete - Awaiting Implementation

---

## Executive Summary

This document specifies a multi-agent swarm to remediate a manga collection of 79 series
(~15,400+ files) plus supporting infrastructure. The swarm prioritizes:

1. **Validation before action**: Every destructive operation has preceding validation
2. **Rollback capability**: Undo scripts generated before any rename/delete
3. **Incremental execution**: Batched operations with verification gates
4. **Parallel where safe**: Maximize speed without risking conflicts
5. **Edge case handling**: Explicit agents for 10 known hazards
6. **Human review gates**: Structured decision points for quality judgments

---

## Collection State (Ground Truth)

| Metric | Value | Notes |
|--------|-------|-------|
| Total Series | 79 | Across 10 worker partitions |
| Total Files | 15,412 (manifest) / ~17,667 (suspected) | Discrepancy to be resolved |
| Files Needing Rename | 14,956 (97%) | Only GTO compliant |
| ComicInfo.xml Files | 0 | Zero metadata coverage |
| __Panels Directories | 311 | Extracted images, not CBZ |
| Corrupt Files | 14 (Blue Box) | Need re-acquisition |
| Resolved Duplicates | Chainsaw Man, Dungeon Meshi, Kagurabachi | JoJo preserved intentionally |
| Remaining Duplicates | Kaiju No. 8 (20) | Medium priority |

### Target Naming Patterns

```
Volumes:  Series Name v## (YYYY) (Digital) (Source).cbz
Chapters: Series Name - Chapter ### (YYYY) (Digital) (Source).cbz
```

---

## Phase Architecture

```
PHASE 0: SECURITY GATE (blocks all other work)
    |
    v
PHASE 1: RECONNAISSANCE (parallel, read-only)
    |
    v
PHASE 2: VALIDATION (parallel, read-only)
    |
    v
PHASE 3: PLANNING (parallel per domain)
    |
    v
PHASE 4: HUMAN REVIEW GATE (blocking)
    |
    v
PHASE 5: EXECUTION (sequential, batched)
    |
    v
PHASE 6: POST-REMEDIATION (verification + automation)
```

---

## Phase 0: Security Gate

### Agent: security-audit-agent

**Purpose**: Scan repository and git history for exposed credentials

**Input Requirements**:
- Repository root: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack`
- Files to scan: `*.md`, `*.sh`, `*.py`, `*.yml`, `*.yaml`, `*.json`, `.env*`
- Git history: All commits

**Output Format**:
```json
{
  "scan_timestamp": "2025-12-21T00:00:00Z",
  "credentials_found": [
    {
      "type": "cloudflare_api_token",
      "location": "docs/scripts/cloudflare-docs-deploy.sh",
      "commit": "abc123",
      "severity": "critical",
      "in_current_tree": true,
      "in_git_history": true
    }
  ],
  "rotation_required": ["cloudflare_api_token"],
  "scrub_required": true
}
```

**Dependencies**: None (first agent to run)
**Parallelization**: None (must complete before anything else)
**Estimated Duration**: 5-10 minutes
**Human Review**: Yes - approve rotation list before proceeding

---

### Agent: api-rotation-agent

**Purpose**: Rotate exposed API keys and update configurations

**Input Requirements**:
- Output from `security-audit-agent`
- Access to Cloudflare dashboard (manual step)

**Output Format**:
```json
{
  "rotation_timestamp": "2025-12-21T00:00:00Z",
  "rotated_credentials": [
    {
      "type": "cloudflare_api_token",
      "old_token_revoked": true,
      "new_token_configured": true,
      "locations_updated": [".env", "GitHub Secrets"]
    }
  ],
  "git_history_scrubbed": false,
  "scrub_command": "git filter-branch --force ..."
}
```

**Dependencies**: `security-audit-agent`
**Parallelization**: None (blocks reconnaissance)
**Estimated Duration**: 15-30 minutes (includes manual steps)
**Human Review**: Yes - confirm each rotation step

---

### Agent: git-history-scrub-agent

**Purpose**: Remove exposed credentials from git history

**Input Requirements**:
- List of files/patterns to scrub from `security-audit-agent`
- Backup of current repository state

**Output Format**:
```json
{
  "scrub_timestamp": "2025-12-21T00:00:00Z",
  "files_scrubbed": ["CREDENTIALS_INVENTORY.md"],
  "commits_rewritten": 15,
  "backup_location": "/path/to/backup.tar.gz",
  "force_push_required": true
}
```

**Dependencies**: `api-rotation-agent`
**Parallelization**: None (modifies git history)
**Estimated Duration**: 10-20 minutes
**Human Review**: Yes - approve force push
**Rollback**: Restore from backup tarball

---

## Phase 1: Reconnaissance Agents

All reconnaissance agents are **read-only** and can run in **parallel**.

### Agent: file-inventory-agent

**Purpose**: Create complete inventory of all files in collection

**Input Requirements**:
- Collection path: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- Include patterns: `*.cbz`, `*.cbr`, `*.pdf`, `*.zip`

**Output Format**:
```json
{
  "inventory_timestamp": "2025-12-21T00:00:00Z",
  "collection_path": "/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics",
  "total_files": 17667,
  "total_size_bytes": 765432109876,
  "by_extension": {
    "cbz": 17200,
    "cbr": 300,
    "pdf": 167
  },
  "by_series": [
    {
      "name": "One Piece",
      "path": "One Piece (Viz) [EN]",
      "file_count": 1098,
      "size_bytes": 45678901234
    }
  ],
  "panels_directories": [
    {
      "path": "Series/__Panels",
      "file_count": 234,
      "size_bytes": 123456789
    }
  ],
  "manifest_discrepancy": {
    "manifest_count": 15412,
    "actual_count": 17667,
    "difference": 2255,
    "likely_cause": "__Panels directories not in manifest"
  }
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 15-30 minutes (depends on OneDrive sync state)

---

### Agent: naming-analysis-agent

**Purpose**: Analyze current file naming patterns and map to target pattern

**Input Requirements**:
- Output from `file-inventory-agent` (or direct filesystem access)
- Target patterns from `manga-audit-manifest.json`

**Output Format**:
```json
{
  "analysis_timestamp": "2025-12-21T00:00:00Z",
  "patterns_detected": [
    {
      "pattern": "Series Name vXX.cbz",
      "count": 5234,
      "example": "One Piece v01.cbz",
      "compliant": false,
      "missing_components": ["year", "digital_tag", "source"]
    },
    {
      "pattern": "Series Name - Chapter XXX.cbz",
      "count": 3421,
      "example": "Chainsaw Man - Chapter 001.cbz",
      "compliant": false,
      "missing_components": ["year", "digital_tag", "source"]
    }
  ],
  "fully_compliant": {
    "count": 456,
    "series": ["GTO"]
  },
  "edge_cases": {
    "multi_part_chapters": ["Chapter 007-1.cbz", "Chapter 007.5.cbz"],
    "special_characters": ["Haikyu!!.cbz", "Spy x Family.cbz"],
    "subseries": ["JoJo Part 1", "Dragon Ball Z"]
  },
  "rename_map_draft": [
    {
      "current": "One Piece v01.cbz",
      "target": "One Piece v01 (1997) (Digital) (Viz).cbz",
      "transformations": ["add_year", "add_digital", "add_source"]
    }
  ]
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 20-40 minutes

---

### Agent: metadata-audit-agent

**Purpose**: Audit ComicInfo.xml presence and content in CBZ files

**Input Requirements**:
- Collection path
- Sample size: All files (or statistical sample for initial audit)

**Output Format**:
```json
{
  "audit_timestamp": "2025-12-21T00:00:00Z",
  "total_files_checked": 17200,
  "comicinfo_present": 0,
  "comicinfo_absent": 17200,
  "coverage_percentage": 0.0,
  "series_metadata_sources": {
    "anilist": "available",
    "mangaupdates": "available",
    "myanimelist": "available"
  },
  "enrichment_candidates": [
    {
      "series": "One Piece",
      "files": 1098,
      "anilist_id": 13,
      "mangaupdates_id": 12345
    }
  ]
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 30-60 minutes (reading inside CBZ files)

---

### Agent: duplicate-detector-agent

**Purpose**: Detect duplicate files using multiple strategies

**Input Requirements**:
- File inventory
- Detection strategies: filename similarity, file size, content hash

**Output Format**:
```json
{
  "detection_timestamp": "2025-12-21T00:00:00Z",
  "strategies_used": ["filename", "size", "md5_hash"],
  "duplicates_found": [
    {
      "series": "Kaiju No. 8",
      "type": "chapter_duplicates",
      "count": 20,
      "files": [
        {
          "path": "Kaiju No. 8/Chapter 001.cbz",
          "size": 12345678,
          "hash": "abc123"
        },
        {
          "path": "Kaiju No. 8/Kaiju No. 8 - Chapter 001 (2020) (Digital).cbz",
          "size": 12345678,
          "hash": "abc123"
        }
      ],
      "recommendation": "keep_properly_named",
      "confidence": "high"
    }
  ],
  "intentional_duplicates": [
    {
      "series": "JoJo's Bizarre Adventure",
      "type": "volume_chapter_overlap",
      "count": 89,
      "status": "EVALUATED_ACCEPTABLE",
      "rationale": "User prefers both formats available"
    }
  ]
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 45-90 minutes (includes hashing)

---

### Agent: corrupt-scanner-agent

**Purpose**: Detect corrupt CBZ files that need re-acquisition

**Input Requirements**:
- File inventory
- Validation method: `zipfile.testzip()` or equivalent

**Output Format**:
```json
{
  "scan_timestamp": "2025-12-21T00:00:00Z",
  "total_files_scanned": 17200,
  "corrupt_files": [
    {
      "path": "Blue Box/Blue Box v01.cbz",
      "error_type": "bad_crc",
      "error_detail": "CRC check failed for page_045.jpg",
      "file_size": 45678901,
      "acquisition_source": "unknown",
      "priority": "high"
    }
  ],
  "summary": {
    "corrupt_count": 14,
    "series_affected": ["Blue Box"],
    "total_size_corrupt": 567890123
  },
  "acquisition_manifest": [
    {
      "series": "Blue Box",
      "volumes_needed": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
      "preferred_source": "usenet",
      "fallback_source": "torrent"
    }
  ]
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 60-120 minutes (reading all CBZ files)

---

### Agent: edge-case-detector-agent

**Purpose**: Detect all 10 known edge cases in the collection

**Input Requirements**:
- File inventory
- Edge case definitions

**Output Format**:
```json
{
  "detection_timestamp": "2025-12-21T00:00:00Z",
  "edge_cases": {
    "onedrive_sync": {
      "collection_size_gb": 712,
      "files_cloud_only": 0,
      "files_locally_available": 17200,
      "sync_status": "healthy"
    },
    "special_characters": {
      "count": 234,
      "files": ["Haikyu!!/Haikyu!! v01.cbz", "SPY x FAMILY/..."],
      "characters_found": ["!", "x", "(", ")", "[", "]"]
    },
    "multi_part_chapters": {
      "count": 45,
      "patterns": ["Chapter 007-1", "Chapter 007.5", "Chapter 007a"],
      "series_affected": ["One Piece", "Naruto"]
    },
    "colored_vs_bw": {
      "count": 12,
      "pairs": [
        {
          "bw": "Series/v01.cbz",
          "colored": "Series/v01 (Colored).cbz",
          "user_preference_needed": true
        }
      ]
    },
    "subseries": {
      "count": 5,
      "mappings": [
        {
          "parent": "JoJo's Bizarre Adventure",
          "parts": ["Part 1 - Phantom Blood", "Part 2 - Battle Tendency", "..."]
        },
        {
          "parent": "Dragon Ball",
          "parts": ["Dragon Ball", "Dragon Ball Z", "Dragon Ball Super"]
        }
      ]
    },
    "oneshots_extras": {
      "count": 67,
      "locations": ["One-Shots/", "Series/Extras/"],
      "naming_strategy": "preserve_separate"
    },
    "panels_directories": {
      "count": 311,
      "total_files_inside": 45678,
      "total_size_gb": 23.4,
      "recommendation": "delete_after_verification"
    },
    "hardlinks_symlinks": {
      "hardlinks": 0,
      "symlinks": 0,
      "status": "none_detected"
    },
    "locked_files": {
      "count": 0,
      "status": "none_locked"
    },
    "unicode_normalization": {
      "nfc_count": 17200,
      "nfd_count": 0,
      "mixed": false,
      "status": "consistent_nfc"
    }
  }
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with all Phase 1 agents)
**Estimated Duration**: 20-40 minutes

---

## Phase 2: Validation Agents

Validation agents verify assumptions before planning.

### Agent: naming-validator-agent

**Purpose**: Validate proposed rename mappings before execution

**Input Requirements**:
- Output from `naming-analysis-agent`
- Target pattern rules

**Output Format**:
```json
{
  "validation_timestamp": "2025-12-21T00:00:00Z",
  "total_renames_proposed": 14956,
  "validation_results": {
    "valid": 14800,
    "invalid": 156,
    "warnings": 234
  },
  "invalid_renames": [
    {
      "current": "Series [Special].cbz",
      "proposed": "Series [Special] (2020) (Digital) (Viz).cbz",
      "error": "target_path_too_long",
      "path_length": 267,
      "max_allowed": 255
    }
  ],
  "warnings": [
    {
      "current": "Series v01.cbz",
      "proposed": "Series v01 (2020) (Digital) (Viz).cbz",
      "warning": "year_uncertain",
      "confidence": "medium",
      "source": "filename_inference"
    }
  ],
  "collision_check": {
    "collisions_detected": 0,
    "unique_targets": 14956
  }
}
```

**Dependencies**: `naming-analysis-agent`
**Parallelization**: Yes (with other Phase 2 agents)
**Estimated Duration**: 10-20 minutes

---

### Agent: duplicate-validator-agent

**Purpose**: Validate duplicate detection accuracy and recommendations

**Input Requirements**:
- Output from `duplicate-detector-agent`
- Quality assessment rules

**Output Format**:
```json
{
  "validation_timestamp": "2025-12-21T00:00:00Z",
  "duplicates_validated": 20,
  "recommendations_confirmed": 18,
  "recommendations_overridden": 2,
  "human_review_required": [
    {
      "series": "Kaiju No. 8",
      "files": ["v2020 release", "v2021 release"],
      "reason": "quality_difference_uncertain",
      "options": ["keep_2020", "keep_2021", "keep_both"]
    }
  ]
}
```

**Dependencies**: `duplicate-detector-agent`
**Parallelization**: Yes (with other Phase 2 agents)
**Estimated Duration**: 10-15 minutes

---

### Agent: path-safety-validator-agent

**Purpose**: Validate all file paths are safe for operations

**Input Requirements**:
- File inventory
- Path safety rules (length, characters, reserved names)

**Output Format**:
```json
{
  "validation_timestamp": "2025-12-21T00:00:00Z",
  "total_paths_checked": 17200,
  "safe_paths": 17195,
  "unsafe_paths": 5,
  "issues": [
    {
      "path": "/very/long/path/.../file.cbz",
      "issue": "path_exceeds_255_chars",
      "length": 267,
      "recommendation": "shorten_parent_directory"
    }
  ],
  "onedrive_compatibility": {
    "all_paths_compatible": true,
    "reserved_names_found": 0,
    "invalid_characters_found": 0
  }
}
```

**Dependencies**: `file-inventory-agent`
**Parallelization**: Yes (with other Phase 2 agents)
**Estimated Duration**: 5-10 minutes

---

### Agent: onedrive-sync-validator-agent

**Purpose**: Validate OneDrive sync status before operations

**Input Requirements**:
- OneDrive status command access
- Collection path

**Output Format**:
```json
{
  "validation_timestamp": "2025-12-21T00:00:00Z",
  "sync_status": "healthy",
  "files_syncing": 0,
  "files_pending": 0,
  "files_error": 0,
  "disk_space_available_gb": 234.5,
  "estimated_resync_time_hours": 0,
  "safe_to_proceed": true,
  "warnings": []
}
```

**Dependencies**: `file-inventory-agent`
**Parallelization**: Yes (with other Phase 2 agents)
**Estimated Duration**: 2-5 minutes

---

## Phase 3: Planning Agents

Planning agents generate executable action plans with rollback scripts.

### Agent: rename-plan-generator-agent

**Purpose**: Generate batched rename plan with rollback scripts

**Input Requirements**:
- Output from `naming-validator-agent`
- Batch size configuration (default: 50 files)
- OneDrive cooldown configuration (default: 5 minutes)

**Output Format**:
```json
{
  "plan_timestamp": "2025-12-21T00:00:00Z",
  "total_renames": 14800,
  "batch_size": 50,
  "total_batches": 296,
  "cooldown_minutes": 5,
  "estimated_duration_hours": 24.7,
  "batches": [
    {
      "batch_id": "batch_001",
      "series": "20th Century Boys",
      "operations": [
        {
          "operation_id": "op_001",
          "type": "rename",
          "source": "/path/to/old.cbz",
          "target": "/path/to/new.cbz",
          "rollback_command": "mv '/path/to/new.cbz' '/path/to/old.cbz'"
        }
      ],
      "rollback_script_path": ".rollback/batch_001_undo.sh"
    }
  ],
  "execution_order": ["batch_001", "batch_002", "..."],
  "verification_gates": {
    "after_each_batch": true,
    "halt_on_failure": true,
    "max_failures_before_halt": 1
  }
}
```

**Dependencies**: `naming-validator-agent`, `onedrive-sync-validator-agent`
**Parallelization**: Yes (with other domain planning agents)
**Estimated Duration**: 15-30 minutes

---

### Agent: dedup-plan-generator-agent

**Purpose**: Generate deduplication plan with rollback (move to trash, not delete)

**Input Requirements**:
- Output from `duplicate-validator-agent`
- Human decisions on ambiguous duplicates

**Output Format**:
```json
{
  "plan_timestamp": "2025-12-21T00:00:00Z",
  "total_duplicates_to_remove": 18,
  "trash_location": "/var/mnt/fast8tb/Cloud/OneDrive/Books/.manga_trash",
  "operations": [
    {
      "operation_id": "dedup_001",
      "type": "move_to_trash",
      "source": "/path/to/duplicate.cbz",
      "target": "/.manga_trash/duplicate.cbz",
      "keep_file": "/path/to/original.cbz",
      "reason": "same_hash_properly_named_version_exists",
      "rollback_command": "mv '/.manga_trash/duplicate.cbz' '/path/to/duplicate.cbz'"
    }
  ],
  "retention_policy": {
    "trash_retention_days": 30,
    "auto_delete_after": false
  }
}
```

**Dependencies**: `duplicate-validator-agent`
**Parallelization**: Yes (with other domain planning agents)
**Estimated Duration**: 5-10 minutes

---

### Agent: acquisition-plan-generator-agent

**Purpose**: Generate re-acquisition plan for corrupt files

**Input Requirements**:
- Output from `corrupt-scanner-agent`
- Available sources (Usenet, torrent)

**Output Format**:
```json
{
  "plan_timestamp": "2025-12-21T00:00:00Z",
  "total_acquisitions_needed": 14,
  "series_affected": 1,
  "acquisitions": [
    {
      "series": "Blue Box",
      "item": "v01",
      "current_file": "/path/to/corrupt.cbz",
      "corruption_type": "bad_crc",
      "search_queries": [
        "Blue Box v01 Digital Viz",
        "Blue Box Volume 1"
      ],
      "preferred_source": "usenet",
      "fallback_source": "torrent",
      "priority": "high"
    }
  ],
  "staging_location": "/var/mnt/fast8tb/Cloud/OneDrive/Books/.manga_staging",
  "verification_required_before_replace": true
}
```

**Dependencies**: `corrupt-scanner-agent`
**Parallelization**: Yes (with other domain planning agents)
**Estimated Duration**: 5-10 minutes

---

### Agent: metadata-plan-generator-agent

**Purpose**: Generate metadata enrichment plan

**Input Requirements**:
- Output from `metadata-audit-agent`
- External metadata sources (AniList, MangaUpdates)

**Output Format**:
```json
{
  "plan_timestamp": "2025-12-21T00:00:00Z",
  "total_files_to_enrich": 17200,
  "enrichment_tool": "komf",
  "series_mappings": [
    {
      "series": "One Piece",
      "anilist_id": 13,
      "mangaupdates_id": 12345,
      "files_to_enrich": 1098
    }
  ],
  "batch_size": 100,
  "total_batches": 172,
  "estimated_duration_hours": 8.6,
  "execution_order": "after_renames_complete"
}
```

**Dependencies**: `metadata-audit-agent`, `rename-plan-generator-agent`
**Parallelization**: Yes (with other domain planning agents)
**Estimated Duration**: 10-20 minutes

---

### Agent: panels-cleanup-plan-generator-agent

**Purpose**: Generate cleanup plan for __Panels directories

**Input Requirements**:
- Output from `edge-case-detector-agent`

**Output Format**:
```json
{
  "plan_timestamp": "2025-12-21T00:00:00Z",
  "total_directories": 311,
  "total_files_inside": 45678,
  "total_size_gb": 23.4,
  "operations": [
    {
      "operation_id": "panels_001",
      "type": "delete_directory",
      "path": "/path/to/Series/__Panels",
      "file_count": 234,
      "size_bytes": 123456789,
      "verification": "parent_cbz_exists",
      "rollback": "not_recoverable_document_only"
    }
  ],
  "pre_deletion_verification": {
    "verify_parent_cbz_valid": true,
    "export_file_list": true
  },
  "human_approval_required": true
}
```

**Dependencies**: `edge-case-detector-agent`
**Parallelization**: Yes (with other domain planning agents)
**Estimated Duration**: 5-10 minutes

---

## Phase 4: Human Review Gate

### Agent: plan-review-reporter-agent

**Purpose**: Consolidate all plans into human-reviewable format

**Input Requirements**:
- All Phase 3 planning agent outputs

**Output Format**: Markdown report (see below)

```markdown
# Manga Remediation Plan Review

## Summary

| Domain | Operations | Estimated Time | Risk Level |
|--------|------------|----------------|------------|
| Renames | 14,800 | 24.7 hours | Medium |
| Deduplication | 18 | 5 minutes | Low |
| Acquisition | 14 | Manual | Low |
| Metadata | 17,200 | 8.6 hours | Low |
| Panels Cleanup | 311 dirs | 30 minutes | High |

**Total Estimated Time**: ~34 hours of automated operations

## Decisions Required

### 1. Duplicate Resolution (2 items)

| Series | Files | Options | Recommendation |
|--------|-------|---------|----------------|
| Kaiju No. 8 ch001 | 2 | keep_2020, keep_2021 | keep_2021 (better quality) |

**Your Decision**: [ ] Accept recommendations [ ] Override (specify)

### 2. Panels Cleanup Approval

Deleting 311 __Panels directories (23.4 GB) is **not recoverable**.

Pre-deletion verification will confirm each parent CBZ is valid.

**Your Decision**: [ ] Approve deletion [ ] Skip panels cleanup

### 3. Batch Execution Parameters

- Batch size: 50 files (adjustable: 25-100)
- Cooldown: 5 minutes between batches
- Verification: After each batch

**Your Decision**: [ ] Accept defaults [ ] Modify (specify)

## Approval

[ ] **APPROVE**: Begin execution with above decisions
[ ] **REJECT**: Re-plan with feedback (specify below)

Feedback: _______________________________________________
```

**Dependencies**: All Phase 3 agents
**Parallelization**: None (consolidation step)
**Estimated Duration**: 5 minutes (generation), variable (human review)
**Human Review**: Yes - this IS the human review gate

---

## Phase 5: Execution Agents

All execution agents are **sequential** and **batched** with verification gates.

### Agent: batch-renamer-agent

**Purpose**: Execute file renames in batches with verification

**Input Requirements**:
- Approved rename plan from Phase 3
- Human approval from Phase 4

**Output Format** (per batch):
```json
{
  "execution_timestamp": "2025-12-21T10:30:00Z",
  "batch_id": "batch_001",
  "operations_attempted": 50,
  "operations_succeeded": 50,
  "operations_failed": 0,
  "rollback_script": ".rollback/batch_001_undo.sh",
  "verification_required": true
}
```

**Dependencies**: Human approval, previous batch verification
**Parallelization**: None (sequential batches)
**Estimated Duration**: 5-10 minutes per batch + 5 minute cooldown
**Rollback**: Execute rollback script for failed batch

---

### Agent: batch-verifier-agent

**Purpose**: Verify batch completion before next batch

**Input Requirements**:
- Batch execution output
- File system access

**Output Format**:
```json
{
  "verification_timestamp": "2025-12-21T10:35:00Z",
  "batch_id": "batch_001",
  "checks_performed": {
    "file_existence": {"passed": 50, "failed": 0},
    "file_integrity": {"passed": 50, "failed": 0},
    "file_size_match": {"passed": 50, "failed": 0},
    "onedrive_sync_status": {"status": "healthy"}
  },
  "overall_status": "PASS",
  "proceed_to_next_batch": true
}
```

**Dependencies**: `batch-renamer-agent` (for current batch)
**Parallelization**: None (sequential with execution)
**Estimated Duration**: 2-5 minutes per batch
**Trigger**: If `overall_status` != "PASS", halt and alert human

---

### Agent: dedup-executor-agent

**Purpose**: Execute deduplication (move to trash)

**Input Requirements**:
- Approved dedup plan from Phase 3
- Human approval from Phase 4

**Output Format**:
```json
{
  "execution_timestamp": "2025-12-21T00:00:00Z",
  "operations_attempted": 18,
  "operations_succeeded": 18,
  "operations_failed": 0,
  "files_moved_to_trash": [
    {
      "source": "/path/to/duplicate.cbz",
      "trash_location": "/.manga_trash/duplicate.cbz"
    }
  ],
  "space_reclaimed_gb": 1.2
}
```

**Dependencies**: Human approval, rename execution complete
**Parallelization**: None (after renames)
**Estimated Duration**: 5-10 minutes
**Rollback**: Move files back from trash

---

### Agent: panels-cleanup-executor-agent

**Purpose**: Delete __Panels directories after verification

**Input Requirements**:
- Approved panels cleanup plan
- Human approval

**Output Format**:
```json
{
  "execution_timestamp": "2025-12-21T00:00:00Z",
  "directories_deleted": 311,
  "files_deleted": 45678,
  "space_reclaimed_gb": 23.4,
  "deletion_manifest": ".rollback/panels_deletion_manifest.json"
}
```

**Dependencies**: Human approval, renames complete
**Parallelization**: None (after renames)
**Estimated Duration**: 30-60 minutes
**Rollback**: Not recoverable - manifest preserved for documentation only

---

## Phase 6: Post-Remediation Agents

### Agent: collection-integrity-verifier-agent

**Purpose**: Final verification of entire collection

**Input Requirements**:
- Original inventory
- Expected final state

**Output Format**:
```json
{
  "verification_timestamp": "2025-12-21T00:00:00Z",
  "original_file_count": 17200,
  "final_file_count": 17182,
  "expected_reduction": 18,
  "actual_reduction": 18,
  "naming_compliance": {
    "compliant": 17182,
    "non_compliant": 0,
    "percentage": 100.0
  },
  "integrity_check": {
    "files_checked": 17182,
    "valid": 17168,
    "corrupt": 14,
    "corrupt_note": "Blue Box awaiting re-acquisition"
  },
  "overall_status": "SUCCESS"
}
```

**Dependencies**: All execution complete
**Parallelization**: None (final step)
**Estimated Duration**: 60-120 minutes

---

### Agent: komga-rescan-agent

**Purpose**: Trigger Komga library rescan

**Input Requirements**:
- Komga API access
- Library ID

**Output Format**:
```json
{
  "rescan_timestamp": "2025-12-21T00:00:00Z",
  "library_id": "abc123",
  "rescan_triggered": true,
  "estimated_duration_minutes": 30,
  "verification": "manual_check_recommended"
}
```

**Dependencies**: `collection-integrity-verifier-agent`
**Parallelization**: None
**Estimated Duration**: 30-60 minutes (Komga processing)

---

### Agent: automation-setup-agent

**Purpose**: Configure automation for new file ingestion

**Input Requirements**:
- Stable collection state
- Target naming patterns

**Output Format**:
```json
{
  "setup_timestamp": "2025-12-21T00:00:00Z",
  "automation_configured": {
    "file_watcher": true,
    "rename_on_arrival": true,
    "metadata_enrichment": true,
    "komga_rescan_trigger": true
  },
  "configuration_files": [
    "config/manga-automation.yml"
  ],
  "test_status": "passed"
}
```

**Dependencies**: All remediation complete
**Parallelization**: None (final setup)
**Estimated Duration**: 30-60 minutes

---

## Infrastructure Agents (Parallel with Collection Work)

### Agent: doc-consolidation-agent

**Purpose**: Consolidate redundant documentation

**Input Requirements**:
- Documentation inventory
- Consolidation rules

**Output Format**:
```json
{
  "consolidation_timestamp": "2025-12-21T00:00:00Z",
  "pairs_consolidated": 4,
  "actions": [
    {
      "kept": "docs/SERVICES.md",
      "removed": "README.md services section",
      "type": "dedup_to_canonical"
    }
  ],
  "documentation_structure": {
    "canonical_files": ["docs/SERVICES.md", "docs/SECURITY.md"],
    "removed_files": [],
    "updated_files": ["README.md"]
  }
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with collection work)
**Estimated Duration**: 30-60 minutes

---

### Agent: legacy-script-archiver-agent

**Purpose**: Archive legacy scripts to archive/ directory

**Input Requirements**:
- Script inventory
- Archive criteria

**Output Format**:
```json
{
  "archive_timestamp": "2025-12-21T00:00:00Z",
  "scripts_archived": 5,
  "archive_location": "archive/scripts/",
  "archived": [
    {
      "original": "scripts/old-deploy.sh",
      "archived": "archive/scripts/old-deploy.sh",
      "reason": "superseded_by_stack-up.sh"
    }
  ]
}
```

**Dependencies**: Phase 0 complete
**Parallelization**: Yes (with collection work)
**Estimated Duration**: 15-30 minutes

---

## Execution Order and Parallelization Map

```
Timeline (not to scale):
================================================================================

PHASE 0 (BLOCKING - Security)
--------------------------------------------------------------------------------
Hour 0    [security-audit]--->[api-rotation]--->[git-scrub]
                                                     |
                                                     v
PHASE 1 (PARALLEL - Reconnaissance)
--------------------------------------------------------------------------------
Hour 1    [file-inventory    ]
          [naming-analysis   ]
          [metadata-audit    ]    ALL PARALLEL
          [duplicate-detector]
          [corrupt-scanner   ]
          [edge-case-detector]
                              |
                              v
PHASE 2 (PARALLEL - Validation)
--------------------------------------------------------------------------------
Hour 2    [naming-validator       ]
          [duplicate-validator    ]    ALL PARALLEL
          [path-safety-validator  ]
          [onedrive-sync-validator]
                                  |
                                  v
PHASE 3 (PARALLEL - Planning)
--------------------------------------------------------------------------------
Hour 3    [rename-plan-generator     ]
          [dedup-plan-generator      ]
          [acquisition-plan-generator]    ALL PARALLEL
          [metadata-plan-generator   ]
          [panels-cleanup-plan       ]
                                     |
                                     v
PHASE 4 (BLOCKING - Human Review)
--------------------------------------------------------------------------------
Hour 4    [plan-review-reporter]--->[HUMAN REVIEW]
                                          |
                                          v
PHASE 5 (SEQUENTIAL - Execution)
--------------------------------------------------------------------------------
Hour 5-29 [batch_001]-->[verify]-->[batch_002]-->[verify]-->...-->[batch_296]
                                                                       |
Hour 30   [dedup-executor]-->[panels-cleanup]                          |
                                                                       v
PHASE 6 (SEQUENTIAL - Post-Remediation)
--------------------------------------------------------------------------------
Hour 31   [collection-integrity-verifier]
Hour 32   [komga-rescan]
Hour 33   [automation-setup]

INFRASTRUCTURE (PARALLEL with Phases 1-5)
--------------------------------------------------------------------------------
          [doc-consolidation]
          [legacy-script-archiver]

================================================================================
TOTAL ESTIMATED TIME: 33-35 hours (with 5-minute cooldowns between batches)
================================================================================
```

---

## Rollback Procedures

### Per-Batch Rollback

```bash
# If batch_042 fails:
cd /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics

# Review what will be undone
cat .rollback/batch_042_undo.sh

# Execute rollback
bash .rollback/batch_042_undo.sh

# Verify rollback
# Re-run batch-verifier-agent on previous state
```

### Full Rollback (Nuclear Option)

```bash
# Rollback ALL batches in reverse order
for script in $(ls -r .rollback/batch_*_undo.sh); do
  echo "Rolling back: $script"
  bash "$script"
  sleep 60  # Cooldown for OneDrive
done
```

### Dedup Rollback

```bash
# Move files back from trash
mv /.manga_trash/* /original/locations/
# (Locations recorded in dedup execution output)
```

### Panels Cleanup Rollback

**NOT POSSIBLE** - Deletion is permanent. Only the manifest is preserved.

```bash
# View what was deleted
cat .rollback/panels_deletion_manifest.json
```

---

## Human Decision Points Summary

| Gate | Decisions | Blocking? | Estimated Time |
|------|-----------|-----------|----------------|
| Security Approval | Rotation list, scrub approval | Yes | 15 min |
| Duplicate Resolution | Which versions to keep | Yes | 10 min |
| Panels Cleanup | Approve 23.4 GB deletion | Yes | 5 min |
| Batch Parameters | Size, cooldown, verification | Yes | 5 min |
| Each Batch Failure | Continue or halt | Yes | Variable |
| Final Verification | Accept remediation | No | 10 min |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OneDrive sync conflict | Medium | High | Batching, cooldowns, sync monitoring |
| File corruption during rename | Low | High | Verification after each batch |
| Wrong duplicate kept | Low | Medium | Human review, trash retention |
| Path too long after rename | Low | Low | Pre-validation, path shortening |
| Komga library broken | Low | Medium | Rescan agent, backup library DB |
| API key exposure continues | Low | Critical | Phase 0 security gate |

---

## Success Criteria

1. **Naming Compliance**: 100% of files match target pattern
2. **Metadata Coverage**: >90% of files have ComicInfo.xml
3. **No Corrupt Files**: 0 (or documented pending acquisition)
4. **No Duplicates**: 0 (except intentional like JoJo)
5. **No __Panels**: 0 directories remaining
6. **Security**: No credentials in git history
7. **Documentation**: Single source of truth per topic
8. **Automation**: New files auto-processed

---

## Appendix A: Agent Implementation Checklist

For each agent implementation:

- [ ] Create agent script in `scripts/swarm/`
- [ ] Define input schema (JSON)
- [ ] Define output schema (JSON)
- [ ] Implement core logic
- [ ] Add error handling
- [ ] Add rollback generation (if applicable)
- [ ] Add logging
- [ ] Test on sample data
- [ ] Document in this spec

---

## Appendix B: File Structure

```
usenet-media-stack/
  scripts/
    swarm/
      phase0/
        security-audit-agent.sh
        api-rotation-agent.sh
        git-history-scrub-agent.sh
      phase1/
        file-inventory-agent.py
        naming-analysis-agent.py
        metadata-audit-agent.py
        duplicate-detector-agent.py
        corrupt-scanner-agent.py
        edge-case-detector-agent.py
      phase2/
        naming-validator-agent.py
        duplicate-validator-agent.py
        path-safety-validator-agent.py
        onedrive-sync-validator-agent.sh
      phase3/
        rename-plan-generator-agent.py
        dedup-plan-generator-agent.py
        acquisition-plan-generator-agent.py
        metadata-plan-generator-agent.py
        panels-cleanup-plan-generator-agent.py
      phase4/
        plan-review-reporter-agent.py
      phase5/
        batch-renamer-agent.py
        batch-verifier-agent.py
        dedup-executor-agent.py
        panels-cleanup-executor-agent.py
      phase6/
        collection-integrity-verifier-agent.py
        komga-rescan-agent.sh
        automation-setup-agent.sh
      infrastructure/
        doc-consolidation-agent.py
        legacy-script-archiver-agent.sh
  .rollback/
    (generated rollback scripts)
  docs/
    MANGA_REMEDIATION_SWARM.md (this file)
```

---

## Appendix C: Configuration

```yaml
# config/swarm-config.yml

collection:
  path: /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
  trash_path: /var/mnt/fast8tb/Cloud/OneDrive/Books/.manga_trash
  staging_path: /var/mnt/fast8tb/Cloud/OneDrive/Books/.manga_staging

naming:
  volume_pattern: "{series} v{volume:02d} ({year}) (Digital) ({source}).cbz"
  chapter_pattern: "{series} - Chapter {chapter:03d} ({year}) (Digital) ({source}).cbz"

batching:
  default_batch_size: 50
  min_batch_size: 25
  max_batch_size: 100
  cooldown_minutes: 5
  max_failures_before_halt: 1

onedrive:
  sync_check_enabled: true
  sync_timeout_minutes: 30

metadata:
  enrichment_tool: komf
  sources:
    - anilist
    - mangaupdates

komga:
  api_url: http://localhost:25600
  library_id: abc123

security:
  scrub_patterns:
    - "*.md"
    - "*.sh"
    - "*.py"
  rotation_required:
    - cloudflare_api_token
```

---

**Document Status**: Complete specification ready for implementation review.

**Next Steps**:
1. Human review of this specification
2. Implement Phase 0 agents (security-critical)
3. Implement Phase 1 agents (reconnaissance)
4. Iterate through remaining phases
