# MCP Memory Server — LLM Interface Specification

> **Project override**: See `MEMORY_SPEC.md` for the authoritative, project-specific rules. This doc is kept in sync.

> This document is optimized for inclusion in an LLM system prompt to teach correct usage of the `@modelcontextprotocol/server-memory` MCP server.

## Overview

You have access to a **Knowledge Graph Memory System** that persists information across conversations. The memory is structured as a graph with three primitive types:

1. **Entities** — nodes representing people, organizations, concepts, events, or things
2. **Relations** — directed edges connecting entities (always in active voice)
3. **Observations** — atomic facts attached to a specific entity

All data persists to a local JSONL file between sessions.

---

## Quick Rules (TL;DR)
- Use **kebab-case** names; create the entity before adding observations.
- Observations are **atomic key:value** (no paragraphs, no secrets).
- Relations are directed, active-voice verbs (`contains`, `depends_on`, `blocks`, `uses`, `related_to`, `enables`).
- Store **credential pointers only** (locations, not values).
- Optional **focus** entity tracks `current`, `next`, `blocked` items.

---

## Data Model

### Entity
```typescript
interface Entity {
  name: string;        // Unique identifier (use kebab-case, e.g., "john-smith")
  entityType: string;  // Category: "person", "organization", "project", "event", "concept", etc.
  observations: string[];  // List of facts about this entity
}
```

### Relation
```typescript
interface Relation {
  from: string;         // Source entity name
  to: string;           // Target entity name  
  relationType: string; // Verb phrase in ACTIVE VOICE (e.g., "works_at", "manages")
}
```

### Observation
- Stored as strings
- Attached to exactly one entity
- **Atomic, key:value** facts (avoid paragraphs)

Recommended keys: `type`, `status`, `priority`, `blocked-by`, `completed`, `owner`, `note`, `port`, `category`, `service`, `location`, `current`, `next`, `blocked`.

Examples:
- `status:open`
- `priority:high`
- `blocked-by:subtask-plex-container`
- `completed:2024-12-17`
- `note:Comics library scan pending`

---

## Tools
- `create_entities` — add nodes (requires name, type, observations)
- `create_relations` — connect nodes (from, to, relationType)
- `add_observations` — add facts to an existing node (fails if node missing)
- `delete_entities` — remove nodes (cascades relations)
- `delete_observations` — remove exact facts
- `delete_relations` — remove specific edges
- `read_graph` — dump entire graph
- `search_nodes` — substring search across names/types/observations
- `open_nodes` — fetch specific nodes

---

## Best Practices
- Use `kebab-case` entity names.
- Observations: one fact each, `key:value` (e.g., `status:open`, `priority:high`, `blocked-by:subtask-plex-container`).
- Relations: active voice; use structured types: `contains`, `depends_on`, `blocks`, `related_to`, `uses`, `enables`.
- Credentials: store **pointers only** (`type:credential`, `service:<svc>`, `location:<path or env>`, `note:<rotate etc>`). No secrets.
- Focus pointer: optional `focus` entity (type:pointer) with `current:`, `next:`, `blocked:` to mark the frontier.

### Relation Type Guide
| Relation      | Meaning                              |
|---------------|--------------------------------------|
| contains      | parent → child grouping              |
| subtask       | task decomposition                   |
| depends_on    | soft prerequisite (do A before B)    |
| blocks        | hard prerequisite (B cannot start)   |
| uses          | task references a tool/credential    |
| related_to    | informational cross-link             |
| enables       | finishing A enables B                |

### Credential Pointer Example
```
name: cred-kavita
entityType: credential
observations:
- type:credential
- service:kavita
- user:j3lanzone
- api-key-location:.env
- note:rotate if shared; do not store key here
```

### Focus Pointer Example
```
name: focus
entityType: pointer
observations:
- type:pointer
- current:subtask-kavita-libraries
- next:subtask-docs-deploy
- blocked:subtask-plex-libraries
```

---

## Operational Pattern
1) Load context: `read_graph` or `search_nodes`.
2) Decompose work: create subtasks + `subtask` relations; add `blocks/depends_on` where needed.
3) Track status: add/replace `status:<state>` observations; add `completed:YYYY-MM-DD` when done.
4) Keep observations atomic; avoid prose.
5) Use `delete_observations` to prune stale facts; keep graph clean.

---

## Error Handling (behavior of server)
- `create_entities`: skips if name exists.
- `add_observations`: fails if entity missing.
- `create_relations`: skips if either entity missing.
- `delete_*`: skips silently if target missing.
- `open_nodes`: skips missing names.

---

## Quick Reference
| Tool | Purpose | Key Input |
|------|---------|-----------|
| create_entities | Add nodes | entities[] name/type/observations |
| create_relations | Connect | relations[] from/to/relationType |
| add_observations | Add facts | observations[] entityName/contents |
| delete_entities | Remove nodes | entityNames[] |
| delete_observations | Remove facts | deletions[] |
| delete_relations | Remove edges | relations[] |
| read_graph | Full dump | {} |
| search_nodes | Substring search | {query} |
| open_nodes | Fetch by name | {names[]} |

Remember: entities first, then observations; use active-voice relations; keep facts atomic; never store secrets (use pointers). EOF
