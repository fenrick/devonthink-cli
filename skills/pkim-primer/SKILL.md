---
name: pkim-primer
description: The PKIM primer — record classes (EV / KN / RL / CL), tag axes, custom metadata schema, filing rules, cross-database WikiLink constraint. Use at the start of any PKIM session and whenever the user mentions PKIM, DEVONthink knowledge notes, evidence records, relation notes, claim records, or is composing DT MCP tools against a PKIM database. Every other PKIM skill assumes this primer has been read.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. See [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md).

# pkim-primer

The base skill. Read this once at the start of a session; every other PKIM skill assumes you know it. It carries no workflow — just the vocabulary + rules the LLM composes DT MCP tools against. If PKIM's configuration is missing or broken, `dt-bootstrap` is the skill that installs it; this primer only tells you when the config *should* be present.

## Preflight

```
mcp__devonthink__is_running          # expect {running: true}
mcp__devonthink__get_databases       # expect PKIM-Knowledge, PKIM-Pilot, PKIM-Evidence-*
mcp__devonthink__list_custom_metadata_fields
```

If any check fails, invoke [`dt-bootstrap`](../dt-bootstrap/SKILL.md).

## Core rules

Six rules the rest of PKIM depends on. Every skill and every ad-hoc DT MCP composition honours them.

1. **DEVONthink is the system of record.** Never modify files inside a `.dtBase2` package through the filesystem. Every mutation goes through DT MCP. Direct filesystem writes corrupt the database — this is warned in the DT MCP tool descriptions and worth taking seriously.
2. **PKIM-Knowledge is indexed against an iCloud-synced on-disk root.** That folder *is* the mirror. Do not build a separate mirror.
3. **DT UUID is identity.** `PKIM_ID` (stored as the `mdpkim_id` custom metadata field) is a human-readable index — filename-compatible, sortable by class-and-date — not a substitute for UUID in cross-references. RL endpoints and CL parents use item links, which are UUID-shaped.
4. **Cross-database links are item links, not WikiLinks.** `[[Name|Display]]` only resolves inside one database. Any reference from `PKIM-Knowledge` to `PKIM-Evidence-*` (or between evidence databases) uses `x-devonthink-item://<uuid>`. Getting this wrong produces dangling references the audit will catch later.
5. **Every touched record ends up tagged.** Structural axes (class, type, state) plus at least one topical axis (`domain/`, `concept/`, `source/`, `year/`, `entity/`, `method/`). Untagged records are invisible to DT's navigation surface.
6. **Write gate is DEVONthink's.** Per-record `Exclude from AI` and per-database `Exclude from Chat & MCP` are the gates. DT MCP honours them automatically. There is no PKIM-side override.

## Reference material — read on demand

Every section below sits in `references/`. Pull them in when the current task touches them, not up front.

| Reference | When to read |
|---|---|
| [references/record-classes.md](references/record-classes.md) | Deciding what class a record is; authoring a new EV / KN / RL / CL; minting a PKIM_ID |
| [references/tag-axes.md](references/tag-axes.md) | Tagging any record; auditing tag completeness; inheriting topical tags |
| [references/metadata-schema.md](references/metadata-schema.md) | Reading or writing custom metadata; picking valid enum values; understanding set-field validation |
| [references/wikilink-and-item-link.md](references/wikilink-and-item-link.md) | Authoring a note body that references other records; converting a dangling WikiLink |
| [references/dt-mcp-cheatsheet.md](references/dt-mcp-cheatsheet.md) | Choosing which DT MCP tool to call; common patterns; things not to do |
| [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) | The runtime brief; the retirement trail |

## Common patterns you'll compose yourself

The DT MCP surface is rich enough that most tasks are one or two tool calls. The three named PKIM skills (`pkim-primer`, `dt-intake`, `dt-audit`) exist because their workflows carry real judgement. Everything else, you compose from the cheatsheet.

Examples:

- **"What's in `/Inbox`?"** → `search_records query: "location:/Inbox/" database_uuid: <X>`
- **"Read this record's body"** → `get_record_text uuid: <X>` (text-native) or `extract_record_content uuid: <X>` (PDF / webarchive / image)
- **"Update this KN's metadata"** → `set_record_custom_metadata uuid: <X> mode: "merge" metadata: {...}`
- **"Find every claim about a topic"** → `search_records query: "mddocrole:claim mdprimarytopic:<topic>"`
- **"Move this to `/Sources/Imported`"** → look up the group's UUID via `lookup_records location: "..."`, then `move_record`.

If you catch yourself sequencing ad-hoc DT MCP calls that overlap `dt-intake` or `dt-audit`'s workflow, invoke the named skill instead. Named skills prevent drift.

## Completion criterion

You have read the primer when you can answer, without looking it up again:

- The four record classes and one distinguishing rule for each.
- What `mode="merge"` does on `set_record_custom_metadata` and why `mode="replace"` is a footgun.
- Which references live where a WikiLink can go, and which need item links instead.
- Where the write gate is (spoiler: DEVONthink, not PKIM).

Anything you can't answer, pull the relevant reference before proceeding.

## Related skills

- [`dt-bootstrap`](../dt-bootstrap/SKILL.md) — install or repair the canonical PKIM configuration when preflight reports a gap.
- [`dt-intake`](../dt-intake/SKILL.md) — sweep an `/Inbox` and file every record.
- [`dt-audit`](../dt-audit/SKILL.md) — audit the graph for broken endpoints, zombies, contradictions, orphans.
