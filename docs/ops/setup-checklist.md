# DEVONthink Pilot Setup Checklist

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/07-runtime.md](../design/07-runtime.md) for how skills compose DT MCP.

## Purpose

This checklist gets the local DEVONthink pilot surface into a state where PKIM commands and skills can operate safely.

Use it when building or repairing the DEVONthink baseline: databases, group structure, custom metadata, smart groups, and local version evidence.

It is an execution checklist, not the canonical schema contract. If this checklist ever conflicts with [../design/03-record-and-note-specification.md](../design/03-record-and-note-specification.md), the design spec wins and this checklist should be corrected.

## How To Use

Repo scripts do the group creation automatically once the databases exist.
Everything else on this list requires the DEVONthink UI.

Work through this in order. Tick each item as you go.

---

## Part 1 — Create the databases

Open DEVONthink Pro. For each database below:

**`File > New Database…`** → set the name exactly as shown → choose a save location that is NOT inside iCloud Drive, Dropbox, OneDrive, or any other cloud-sync folder (e.g. `~/Databases/` is fine).

| # | Database name | Role |
|---|---|---|
| 1 | `PKIM-Knowledge` | Canonical knowledge graph |
| 2 | `PKIM-Evidence-Personal` | Personal captures and mobile-important content |
| 3 | `PKIM-Evidence-Work` | Work evidence (can be left mostly empty at pilot stage) |
| 4 | `PKIM-Evidence-Server` | NAS / mounted-share evidence (skip if no server available yet) |
| 5 | `PKIM-Pilot` | Scratch database for safe automation testing |

**Confirm after each:**
- The database appears in the DEVONthink sidebar.
- The save path does not contain a sync-service directory name.

**PKIM-Pilot hard check:** open Finder, navigate to where you saved it, confirm the path. If it is inside `~/Library/Mobile Documents/` or similar, move it before continuing.

---

## Part 2 — Create the group structure

With all databases open in DEVONthink, invoke the [`dt-bootstrap`](../../skills/dt-bootstrap/SKILL.md) skill. It:

- Creates the canonical group tree in every open canonical database (idempotent — existing groups are reported as `already-present`).
- Auto-registers any missing custom metadata fields against a scratch record in `PKIM-Pilot`.
- Installs the ten canonical text-predicate smart groups.
- Installs the four note templates under `PKIM-Knowledge/Templates`.

Review the report. Every database should show `groups <N/N>` with no `error` entries. Any missing entry usually means the database was not open in DEVONthink — open it and re-run (the skill is idempotent).

---

## Part 3 — Define custom metadata fields

Open: **DEVONthink > Settings… (or Preferences…) > Data > Custom Metadata**

Click `+` to add each field below. Name and type must be exact.

### Core fields (required for all record classes)

| Field name | Type | Notes |
|---|---|---|
| `PKIM_ID` | Text | Stable local identifier; mint once |
| `DocRole` | Selection | Record class; see vocabulary below |
| `Review_State` | Selection | Review state; see vocabulary below |
| `Origin_URI` | Text | Upstream source URI or path |
| `Origin_Last_Path` | Text | Last known filesystem path (indexed items only) |
| `Source_Item` | Text | Source item link for relation notes |
| `Target_Item` | Text | Target item link for relation notes |
| `Relation_Type` | Selection | Relation type; see vocabulary below |
| `Mirror_Path` | Text | Export mirror target path |
| `Content_SHA256` | Text | Integrity / change detection |

### Operational fields

| Field name | Type | Notes |
|---|---|---|
| `CreatedByMode` | Selection | `human`, `automation`, or `mixed` |
| native `kind` property | Native | DEVONthink-native file kind; do not create a custom `SourceType` field |
| `PrimaryTopic` | Text | Topical anchor |
| `LastProfiledAt` | Date | Timestamp of last profiling run |
| `LastMirroredAt` | Date | Timestamp of last mirror export |
| `LastRunID` | Text | Most recent automation run ID touching this record |

### Evidence-specific fields

| Field name | Type | Notes |
|---|---|---|
| `EvidenceStatus` | Selection | `raw`, `ocrd`, `reviewed`, `linked`, `archived` |
| `CaptureType` | Selection | `imported`, `indexed`, `bookmark`, `snapshot`, `scan` |
| `CanonicalSourceURL` | Text | Upstream source URL where meaningful |

### Knowledge-specific fields

| Field name | Type | Notes |
|---|---|---|
| `NoteType` | Selection | `literature`, `synthesis`, `topic`, `project`, `decision`, `workflow` |
| `KnowledgeStatus` | Selection | `seed`, `active`, `reviewed`, `published`, `archived` |
| `EvidenceCount` | Integer Number | Optional dashboard hint |

### Relation-specific fields

| Field name | Type | Notes |
|---|---|---|
| `RelationConfidence` | Text | Optional confidence indicator |
| `RelationStatus` | Selection | `proposed`, `reviewed`, `accepted`, `retired` |

### Queue signal fields

| Field name | Type | Notes |
|---|---|---|
| `Needs_OCR` | Boolean | OCR required but not complete |
| `Knowledge_Link_State` | Text | Evidence-to-knowledge linkage status |
| `Relation_Gap_State` | Text | Relation-note coverage status |
| `Indexed_Risk_State` | Text | Indexed item path or refresh risk status |
| `Mirror_State` | Text | Mirror freshness relative to canonical note state |
| `Automation_Last_Run_State` | Selection | `ok` or `error` from last automation run |

**Total: 30 fields.**

After entry, scroll through the list and confirm every field name is spelled exactly as shown — the automation scripts use these names as literal strings.

---

## Part 4 — Confirm metadata fields are accessible

Select any record in DEVONthink. Open the inspector panel (`⌘4` or View > Inspectors > Generic). Scroll to the custom metadata section. You should see all 30 fields listed (empty, but present).

If any fields are missing, add them now.

---

## Part 5 — Record versions and update the compatibility matrix

Open **DEVONthink > About DEVONthink** and note the exact version number.

Open a terminal and check:
```bash
sw_vers -productVersion   # macOS version
uv --version              # runtime wrapper used for pkim commands
```

Open `docs/ops/compatibility-matrix.md` and fill in:
- macOS version
- DEVONthink version
- The 30 metadata field names (confirming they match this list)
- Date validated

---

## Part 6 — Run the health check

```bash
cp .env.example .env
# Edit .env — confirm PKIM_DEVONTHINK_SCRATCH_DATABASE=PKIM-Pilot
# and PKIM_DEVONTHINK_KNOWLEDGE_DATABASE=PKIM-Knowledge

uv run --project . pkim health-check --format json
```

Expected output: `"result": "ok"` with the correct database names shown.

---

## Vocabulary reference

### `DocRole` values
`evidence` · `knowledge` · `relation` · `annotation` · `project` · `topic` · `operation`

### `Review_State` values
`inbox` · `profiled` · `needs-human` · `approved` · `blocked` · `filed` · `mirrored` · `archived` · `error`

### `Relation_Type` values
`supports` · `contradicts` · `extends` · `summarizes` · `references` · `exemplifies` · `precedes` · `supersedes`

---

## Done condition

All of the following are true:
- [ ] All 5 databases exist and are open in DEVONthink.
- [ ] `PKIM-Pilot` path does not contain any cloud-sync directory.
- [ ] `dt-bootstrap` completes without any `error` entries in its report.
- [ ] All canonical metadata fields appear in `mcp__devonthink__list_custom_metadata_fields`.
- [ ] `mcp__devonthink__is_running` returns `{running: true}` and `get_databases` shows all five canonical names.
- [ ] `docs/ops/compatibility-matrix.md` is filled in with current version numbers.
