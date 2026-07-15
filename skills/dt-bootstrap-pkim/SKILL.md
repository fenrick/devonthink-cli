---
name: dt-bootstrap-pkim
description: Install the canonical PKIM configuration into DEVONthink — canonical databases, group trees, custom metadata fields, smart groups, and note templates. Use this once per new machine, or after opening a database that was created outside PKIM's conventions. Idempotent; safe to re-run.
compatibility: Requires DEVONthink 4.3+ running with its in-app MCP server registered against the caller's AI client (see docs/ops/local-environment.md). All mutation is via DT MCP tools; no PKIM-owned runtime.
---

# dt-bootstrap-pkim

Replaces the five AppleScript setup helpers and the briefly-lived `pkim setup-database` / `pkim verify-database` / `pkim verify-smart-groups` / `pkim fix-smart-groups` / `pkim install-templates` verbs. Everything now composes DT MCP tools.

## What this skill does

For each canonical database (`PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`) it ensures:

1. The database is open (skipped with a warning if not; the human opens it, then re-runs).
2. The canonical group tree exists (`/Inbox`, `/Notes/...` for knowledge, `/Sources/...` and `/Captures/...` for evidence).
3. The canonical custom metadata fields exist with the correct types.
4. The 10 canonical smart groups exist with text predicates (not the GUI's binary predicates — those don't match records whose metadata is written via MCP).
5. For `PKIM-Knowledge` only: the four note templates (`Knowledge Note`, `Relation Note`, `Topic Note`, `Project Note`) exist under `/Templates`.

## Preconditions

- DEVONthink 4.3+ is running.
- DT MCP server is registered with the caller's AI client (`mcp__devonthink__is_running` returns `{running: true}`).
- The five canonical databases have been created in DEVONthink (this skill does not create databases — that is a manual DEVONthink step because the on-disk location must not be cloud-synced).

## Postconditions

- Every canonical group path resolves via `mcp__devonthink__lookup_records` (by `location`) for the databases that were open at the start.
- Every canonical smart group resolves and carries the expected text predicate.
- The four templates exist under `PKIM-Knowledge/Templates/`.
- Emits a summary: `{database → {groups_created, groups_existed, smart_groups_created, smart_groups_replaced, templates_created, templates_existed}}`.

## Canonical configuration

### Databases and group shape

| Database | Group tree |
|---|---|
| `PKIM-Knowledge` | `/Inbox`, `/Notes`, `/Notes/Literature`, `/Notes/Synthesis`, `/Notes/Relations`, `/Notes/Topics`, `/Notes/Projects`, `/Notes/Claims`, `/Templates`, `/Operations`, `/Archive` |
| `PKIM-Evidence-Personal` / `-Work` / `-Server`, `PKIM-Pilot` | `/Inbox`, `/Sources`, `/Sources/Imported`, `/Sources/Indexed`, `/Captures`, `/Captures/Web`, `/Captures/Bookmarks`, `/Captures/Scans`, `/Working`, `/Review`, `/Archive` |

Group creation goes through `mcp__devonthink__create_group_path`, which is idempotent — passing an existing path returns the existing group.

### Smart groups (text-predicate; not GUI-built)

DEVONthink's GUI smart-group picker emits binary NSPredicates that query the internal field index. MCP writes go to the raw custom-metadata dictionary. Text predicates (created via the "Enter predicate" path or via `create_record type="smart-group"` with `search predicate`) query the raw dict, so they match MCP-written metadata.

| Smart group | Predicate | Databases |
|---|---|---|
| `Needs Profile` | `mdreview_state!="approved" && mdreview_state!="filed"` — records still in triage | all five |
| `Needs OCR` | `mdneeds_ocr==true` | four evidence DBs |
| `Needs Knowledge Note` | `mdreview_state=="approved" && mdknowledge_link_state!="linked"` | four evidence DBs |
| `Needs Relation Note` | `mdrelation_gap_state=="open"` | `PKIM-Knowledge` |
| `Needs Filing` | `mdreview_state=="approved"` | all five |
| `Indexed Risk` | `mdindexed_risk_state!=""` | four evidence DBs |
| `Mirror Drift` | `mdmirror_state=="stale"` | `PKIM-Knowledge` |
| `Automation Error` | `mdautomation_last_run_state=="error"` | all five |
| `Needs Human Review` | `mdreview_state=="needs-human"` | all five |
| `Ready for Mirror` | `mdreview_state=="approved" && mdknowledgestatus=="active"` | `PKIM-Knowledge` |

Smart-group creation: `mcp__devonthink__create_record` with `type: "smart-group"`, `name`, `search predicate`, and `destination` set to the database's root UUID. If a smart group with the target name already exists but its predicate is stale (binary from the GUI), `dt-bootstrap-pkim` deletes it via `mcp__devonthink__trash_record` and recreates it with the correct text predicate.

### Note templates

Four templates under `PKIM-Knowledge/Templates/`. Creation is via `mcp__devonthink__create_record` type `markdown` with the destination set to the Templates group UUID.

Template bodies live in this skill's `assets/` subdirectory (one `.md` per template). The skill reads them at runtime and passes each body as `content` to `create_record`.

## Workflow

1. **Preflight.**
   Call `mcp__devonthink__is_running`, then `mcp__devonthink__get_databases`. Note which of the five canonical databases are open. If any are missing, print a warning naming them and continue with what's open.

2. **Groups.**
   For each open canonical database:
   - Pick the group tree (`knowledge` or `evidence`) based on the database name.
   - For each path in the tree, call `mcp__devonthink__create_group_path` with `path` and `database_uuid`. Record whether it was created or already existed.

3. **Custom metadata fields.**
   Call `mcp__devonthink__list_custom_metadata_fields`. Compare against the canonical field list (see [../../docs/ops/compatibility-matrix.md](../../docs/ops/compatibility-matrix.md) §Custom Metadata Fields). For any missing field, write a placeholder value against a scratch record in `PKIM-Pilot` via `mcp__devonthink__set_record_custom_metadata` — DT auto-registers the field with the type inferred from the value. Trash the scratch record afterwards.

4. **Smart groups.**
   For each canonical smart group and each database in its scope:
   - Look up the current smart group by name at `/{name}` in the database via `mcp__devonthink__lookup_records`.
   - If it doesn't exist, create it via `mcp__devonthink__create_record` with the text predicate.
   - If it exists but its `searchPredicates` differ from the canonical text predicate (read via `mcp__devonthink__get_record_properties`), delete it via `mcp__devonthink__trash_record` and recreate.

5. **Templates (PKIM-Knowledge only).**
   For each template name, look up under `/Templates/{name}`. If missing, read the body from `assets/<name>.md` and call `mcp__devonthink__create_record` with `type: markdown`, `content`, and `destination` set to the Templates group UUID.

6. **Report.**
   Emit the per-database summary.

## Failure modes

- **`database-closed`** — one or more canonical databases is not open. The skill continues with what's open and reports the missing databases in the summary. Human opens them and re-runs.
- **`predicate-conflict`** — a smart group exists with the correct name but the current predicate is a binary NSPredicate the skill can't read as a string. The skill logs a warning and re-creates it anyway (the delete + create sequence is safe).
- **`template-body-missing`** — the `assets/*.md` template body is missing from this skill's directory. The skill fails the templates step for that entry and continues.

## Related skills

- `dt-health-check` — read-only version of the preflight; use it in-session.
- Ops doc [compatibility-matrix.md](../../docs/ops/compatibility-matrix.md) — the canonical custom-metadata field schema.
- Ops doc [smart-groups-setup.md](../../docs/ops/smart-groups-setup.md) — human-facing setup guide; this skill automates most of it.
