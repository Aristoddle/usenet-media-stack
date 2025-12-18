# Memory KG Specification (hardened)

## Entity types
- project, goal, task, subtask, reference, credential, pointer, todo (index only).

## Naming
- kebab-case, concise, scoped: e.g., `task-transmission-watch`, `subtask-docs-deploy`.

## Observations (use key/value lines + optional free text)
- Required per task/subtask:
  - `status:<open|blocked|partial|done|backlog>`
  - `updated:<TIMESTAMP>`
  - `owner:<handle>`
  - `priority:<high|medium|low>` (optional but encouraged)
- Optional:
  - `blocked-by:<entity-name>`
  - `note:<free text>`
  - `completed:<TIMESTAMP>` (when done)
- Timestamp format (**strict**):
  - `TIMESTAMP = "%d%b%y @ %H:%M:%S %z"`
  - Example: `17Dec25 @ 20:31:45 -0500`
  - Generate with: `date +"%d%b%y @ %H:%M:%S %z"`
  - If a legacy date is month-only (e.g., `2024-12`), normalize to `01Dec24 @ 00:00:00 <local tz>` and add a note if needed.
- Status enum applies anywhere a `status:` observation appears (not just tasks/subtasks).
- Append new observations; avoid overwriting to preserve history. Remove stale/contradictory notes when they no longer apply.
- Credentials: never store secrets; only pointers (file paths, managers).

## Relations (verbs – keep to this set)
- `contains` (hierarchy: project→goal→task→subtask; index→tasks)
- `depends_on` / `blocks` (ordering/dependencies)
- `uses` (task → reference/credential)
- `related_to` (loose link)
- `owner` optional if not in observation (prefer observation)

> Note: legacy `subtask` edges should be normalized to `contains`.

## Parent index pattern
- Single index entity (e.g., `stack-open-items`, type: `todo`) holds only a brief `index:` observation and `contains` edges to active/backlog tasks.

## Task granularity
- Split coarse tasks into actionable subtasks (e.g., secrets → cf-token-rotate, gitleaks-setup, history-scan).
- Mark optional/backlog work with `status:backlog`.

## Status transitions
- On change, add a new `status:` observation with `updated:<TIMESTAMP>`.
- When done, add `status:done` and `completed:<TIMESTAMP>`.

## Dependencies
- Record real order with `depends_on` / `blocks` to surface blockers (e.g., `subtask-docs-deploy depends_on task-git-commit`).

## Pointer entity
- Keep a `pointer` entity (e.g., `focus`) with observations: `current:<entity>`, `next:<entity>`, `blocked:<entity>` for daily guidance.

## Maintenance cadence
- Weekly: `read_graph()` scan for stale `updated:`; touch active items with fresh `updated:` when worked.
- Keep parent index clean; do not duplicate detailed notes there.

## Security
- No secrets in observations. Only references to where secrets live.
- Rotate credentials in their source systems, then update pointers.

## Usage snippets
- Create task: `create_entities([{name:"task-x",entityType:"task",observations:["status:open","updated:17Dec25 @ 20:31:45 -0500","owner:deck","priority:medium","note:..."]}])`
- Link: `create_relations([{from:"stack-open-items",relationType:"contains",to:"task-x"}])`
- Add dependency: `create_relations([{from:"task-x",relationType:"depends_on",to:"task-y"}])`
- Update status: `add_observations([{entityName:"task-x",contents:["status:done","updated:17Dec25 @ 20:31:45 -0500","completed:17Dec25 @ 20:31:45 -0500"]}])`

## Drift protection (enforced)
- Use `codex_tools/mermaid_view/scripts/kg-validate` with `--updated-format "%d%b%y @ %H:%M:%S %z"`.
- Prefer a shared config file (e.g., `codex_tools/mermaid_view/kg-config.json`) to centralize allowed types/relations/status enums.
