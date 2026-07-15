---
name: pkim-orient-and-setup
description: Read this at the start of every PKIM session. It tells you what PKIM is (record classes, tag axes, metadata schema, filing rules, cross-database WikiLink constraint), how to use DEVONthink 4.3+'s MCP server to do work, and how to install the canonical configuration if it's missing. This is the base skill every other PKIM skill assumes you've loaded.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. See [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md).

# pkim-orient-and-setup

## Purpose

Two jobs, one skill:

1. **Orient** — establish enough shared vocabulary and rules that the LLM can compose DT MCP tools correctly for any PKIM task. This replaces reading the whole design register.
2. **Set up** — install the canonical PKIM configuration (databases' group trees, custom metadata fields, smart groups, templates) if any of it is missing.

Every other PKIM skill starts with `read pkim-orient-and-setup first`. Don't duplicate its content elsewhere.

## When to use

- At the start of any PKIM session, before touching records.
- When onboarding a new machine or a new database.
- When something looks wrong: unexpected metadata, missing groups, smart groups showing empty when they shouldn't.

## Preflight

```
mcp__devonthink__is_running          # expect {running: true}
mcp__devonthink__get_databases       # expect entries for PKIM-Knowledge, PKIM-Pilot, PKIM-Evidence-*
mcp__devonthink__list_custom_metadata_fields
```

If any of these fail, go to §Setup. If they all pass, you're oriented.

## Core rules (read these; don't skip)

1. **DEVONthink is the system of record.** Never modify files inside a `.dtBase2` package directly. Every mutation goes through DT MCP.
2. **PKIM-Knowledge is indexed against the on-disk knowledge root** (which is iCloud-synced). That's the mirror. Do not build a separate mirror.
3. **DT UUID is identity.** `PKIM_ID` (the `mdpkim_id` custom metadata field) is a human-readable index — filename-compatible, sortable by class+date — not a substitute for the UUID in cross-references.
4. **Cross-database links are item links, not WikiLinks.** `[[Name|Display]]` only resolves inside one database. Any reference from `PKIM-Knowledge` to `PKIM-Evidence-*` (or between evidence databases) uses `x-devonthink-item://<uuid>`.
5. **Every touched record ends up tagged.** Structural + topical axes both. Non-negotiable. See [references/tag-axes.md](references/tag-axes.md).
6. **Write gate is DEVONthink's.** Per-record `Exclude from AI` and per-database `Exclude from Chat & MCP` are the gates. DT MCP honours them. There is no PKIM-owned override.

## Reference material

Read these on demand; don't front-load everything.

| Reference | When to read |
|---|---|
| [references/record-classes.md](references/record-classes.md) | Any time you're deciding what class a record is or authoring a new one — EV / KN / RL / CL definitions, PKIM_ID formats, filing conventions |
| [references/tag-axes.md](references/tag-axes.md) | Any time you're tagging or checking tags — structural + topical axes per class, inheritance rules, vocabulary discipline |
| [references/metadata-schema.md](references/metadata-schema.md) | Any time you're reading or writing custom metadata — canonical field list, types, allowed values |
| [references/wikilink-and-item-link.md](references/wikilink-and-item-link.md) | Any time you're authoring a note body that references other records |
| [references/canonical-config.md](references/canonical-config.md) | Setup / verification — canonical group trees, 10 smart groups with text predicates, 4 note templates |
| [references/dt-mcp-cheatsheet.md](references/dt-mcp-cheatsheet.md) | Reminder of which DT MCP tool to reach for — the ~65 tools grouped by task |
| [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) | The runtime brief. Canonical for tool-name conventions and the retirement trail. |

## Setup — install canonical config

Only run this branch when the preflight fails or you're onboarding a new machine.

### 1. Databases

Databases are created manually in DEVONthink (this skill does not create databases — the on-disk location must be a deliberate choice; only PKIM-Knowledge is indexed against an iCloud-synced folder). Confirm the five canonical databases exist and are open:

- `PKIM-Knowledge`
- `PKIM-Evidence-Personal`
- `PKIM-Evidence-Work`
- `PKIM-Evidence-Server`
- `PKIM-Pilot`

If any are missing, pause and ask the operator to create them.

### 2. Group trees

For each open canonical database, ensure the group tree from [references/canonical-config.md](references/canonical-config.md) exists. Use `mcp__devonthink__create_group_path` — it's idempotent; existing paths are returned rather than duplicated.

Loop:

```
for each database in the five canonical:
    shape = knowledge if name == "PKIM-Knowledge" else evidence
    for each path in canonical_groups[shape]:
        mcp__devonthink__create_group_path(database_uuid=db.uuid, path=path)
```

### 3. Custom metadata fields

Compare `mcp__devonthink__list_custom_metadata_fields` against the canonical field list in [references/metadata-schema.md](references/metadata-schema.md). For any missing field:

1. Create a scratch markdown record in `PKIM-Pilot` via `mcp__devonthink__create_record`.
2. Write a placeholder value for the missing field via `mcp__devonthink__set_record_custom_metadata` with `mode="merge"`. DT auto-registers the field with the type inferred from the value.
3. Trash the scratch record via `mcp__devonthink__trash_record`.

For enum (`set`) fields, use a valid vocabulary value from the schema.

### 4. Smart groups

For each canonical smart group and each database in its scope (see [references/canonical-config.md](references/canonical-config.md)):

1. Look up the smart group by path (`/{name}`) in the database via `mcp__devonthink__lookup_records`.
2. If present, read its predicate via `mcp__devonthink__get_record_properties` and compare to the canonical text predicate.
3. If missing, or predicate stale (binary NSPredicate from the GUI, or wrong text), delete via `mcp__devonthink__trash_record` and recreate via `mcp__devonthink__create_record` with `type: "smart-group"`, `name`, `search predicate`, `destination` = database root UUID.

DT's GUI smart-group picker emits binary predicates that don't match records whose metadata was written via MCP. Text predicates match; that's why we rebuild.

### 5. Templates

`PKIM-Knowledge/Templates/` should hold four templates: `Knowledge Note`, `Relation Note`, `Topic Note`, `Project Note`. For each:

1. Look up under `/Templates/{name}` via `mcp__devonthink__lookup_records`.
2. If missing, read the body from `assets/<slug>.md` and create via `mcp__devonthink__create_record` with `type: markdown`, `content: <body>`, `destination: <templates group uuid>`.

### 6. Verify

Re-run the preflight. All three calls should succeed. Log a summary of what was created vs already-present.

## Stop conditions

- A required database is not open → pause; ask the operator.
- `mcp__devonthink__is_running` returns `{running: false}` → open DT and re-run.
- DT MCP tool returns an error you can't interpret → surface to the operator; do not guess.

## Related skills

- [`dt-intake`](../dt-intake/SKILL.md) — inbox → filed record walk. Assumes this skill has been read.
- [`dt-audit`](../dt-audit/SKILL.md) — graph health audit. Assumes this skill has been read.
