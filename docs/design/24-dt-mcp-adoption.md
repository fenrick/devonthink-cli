# DT MCP adoption — retire the `pkim` binary

## Purpose

Record the pivot back from a custom Swift runtime to DEVONthink 4.3 Herschel's official MCP server. This doc supersedes [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md) and [23 Swift pkim Binary](23-swift-pkim-binary.md).

Doc 22 argued: "The MCP server's reason for existing has evaporated" — so retire our PyObjC+MCP stack for a Swift CLI. Doc 24 argues: DEVONthink 4.3 shipping its own MCP server settles the same concern from the other side. The right runtime for skills to compose is DT's MCP, not our binary. The Swift work retires.

## Why the reversal

DEVONthink 4.3 Herschel (released 2026) ships an in-app MCP server of ~65 tools. Every unique capability the `pkim` binary provided is now covered — usually better — by that server:

| pkim binary concern | DT MCP resolution |
|---|---|
| **Whole-dict customMetaData writes drift NSDate fields.** Drove the per-key `addCustomMetaData` architecture. | `set_record_custom_metadata mode="merge"` preserves untouched fields verbatim. Auto-registration of unknown keys, per-key validation feedback (`dropped_fields` + `rejection_reasons`), automatic post-write read-back. Probed live 2026-07-15. |
| **Indexed markdown records need file-as-truth writes** so the on-disk `.md` stays canonical. | `update_record_content` writes the on-disk file directly for both indexed and imported records (probed 2026-07-15: indexed file at `/tmp/pkim-probe/indexed-scratch.md` had mtime + content rewritten by DT MCP's `patch` mode). DT owns file consistency; the file-as-truth workaround dissolves. |
| **PyObjC introspection tax on corpus walks.** Millions of bridge crossings per read. | DT MCP is Apple-signed, IPC-bounded, and returns rich structured JSON per call. Batch mode via `uuids: [...]` collapses N calls into one. |
| **Apple Events are the wrong read plane; use `.dt` cache.** | Moot — DT MCP is the read plane. Offline reads via `.dt` cache were a hypothetical; the actual workflows all run with DT running. |
| **`addCustomMetaData` Bool return lies.** Drove verify-read on every write. | DT MCP reads back automatically and reports validation results in the response. Verify-read is the tool's job, not ours. |
| **PKIM-side write gate + dry-run + run manifests.** Trust infrastructure for our own bridge. | DT MCP is the trusted layer (Apple-signed, privacy-aware, honours `Exclude from AI` per-record, redacts PII on AI-facing tools). The trust infrastructure was for a bridge that no longer exists. |
| **PKIM_ID minted via mdfind against `.dt` cache.** Custom identifier for DT records. | PKIM_ID retains its role as a *metadata field* (`mdpkim_id`) — human-readable, filename-compatible, sortable by class+date. It stops being a runtime concern; DT UUIDs are the persistent record identifier for cross-references (see below). |

## What retires

- `pkim-binary/` — the entire Swift package, ~5.7k lines of Swift + tests. Deleted.
- `docs/design/22-cli-first-atomic-primitives.md` — supersession banner points here; retained for historical reasoning.
- `docs/design/23-swift-pkim-binary.md` — same.
- `.github/workflows/swift.yml` — no Swift to build.
- `.mcp.json`'s xcode bridge entry — was for developing the Swift package.
- `skills/RETIREMENT-MAP.md` — was the skills-to-verbs map; obsoleted by the retirement.

## What the runtime becomes

```
┌─────────────────────────────────────────────────────────┐
│  Skills (markdown workflows)                            │
│    ├─ policy                                            │
│    ├─ orchestration                                     │
│    └─ compose DT MCP tools directly                     │
├─────────────────────────────────────────────────────────┤
│  DEVONthink 4.3+ MCP server                             │
│    ~65 tools: reads, writes, batch, search, AI,         │
│    extraction, capture, bibliographic, per-record       │
│    exclusion, PII redaction                             │
├─────────────────────────────────────────────────────────┤
│  Persistence                                            │
│    ├─ DEVONthink databases (system of record)           │
│    └─ (optional) mirror / exports skill-produced        │
└─────────────────────────────────────────────────────────┘
```

Skills call DT MCP tools by name (`mcp__devonthink__get_record_properties`, `set_record_custom_metadata`, etc.). There is no PKIM-owned runtime layer between the skill and DEVONthink.

## Layer rules (binding)

1. **Skills own policy and orchestration.** They decide what to do, in what order, with what checkpoints. They call DT MCP tools for mechanism.
2. **DT MCP owns mechanism.** All reads, writes, searches, extractions, and AI operations go through DT MCP tools. No PKIM-side wrappers.
3. **PKIM_ID stays as metadata, not identity.** DT UUID is the persistent identifier for cross-record references (RL endpoints, CL parents, EV citations). `PKIM_ID` (`mdpkim_id` custom metadata field) is a human-readable index for filenames, search, and human recognition — not a substitute for DT UUID.
4. **The write gate lives in DEVONthink.** `Exclude from AI` per-record and per-database flags are respected by DT MCP. Skills don't need PKIM-side gating; they inherit DT's.

## Preserved constraint: cross-database WikiLinks don't resolve

DEVONthink 4.3's new Markdown renderer improves callouts, citations, and CriticMarkup, but `[[Name|Display]]` WikiLinks still resolve only within a single database. A KN in `PKIM-Knowledge` cannot WikiLink an EV in `PKIM-Evidence-*` by name or alias — the link renders as text, not a navigable jump.

Consequences for the note model:

- **Within one database** (KN ↔ CL ↔ RL inside `PKIM-Knowledge`): use `[[Name|Display]]` freely. The renderer resolves them.
- **Across databases** (any reference to `PKIM-Evidence-*` from `PKIM-Knowledge`, or between evidence databases): use `x-devonthink-item://<uuid>` item links.

Skills that author or repair relation records (RLs) must apply the boundary. Doc 08 (record-and-note-specification) is the source of truth for the note templates; skills reference it.

## Setup / bootstrap

The five ports that briefly lived as `pkim setup-database`, `pkim verify-database`, `pkim verify-smart-groups`, `pkim fix-smart-groups`, and `pkim install-templates` become a small set of structured skill workflows composing DT MCP tools:

- `dt-bootstrap-pkim` — creates the canonical group trees, installs templates, creates the 10 smart groups with text predicates. Composes `create_group_path`, `create_record type="group"/smart-group`, `search_records` for verification.
- `dt-verify-pkim` — read-only checklist over the canonical config; composes `get_group_tree`, `search_records`.

These are workflow markdown, not runtime code. The canonical config (database names, group paths, smart-group predicates, template bodies) lives in one place inside the skill.

## Skill runbook impact

Every skill under `skills/dt-*/SKILL.md` that referenced `pkim <verb>` invocations updates to reference DT MCP tool names. The mapping is 1:1 or better in every case (see the coexistence table below). Skill *bodies* don't change semantically; only the tool names.

Coexistence / replacement table:

| Old pkim verb | Replaces with |
|---|---|
| `pkim get`, `resolve`, `list`, `tags`, `aliases`, `file-path` | `get_record_properties`, `lookup_records`, `get_record_children`, `get_record_tags`, `get_imported_record_path` |
| `pkim body` | `get_record_text` |
| `pkim search` | `search_records` (query syntax is a strict superset of pkim's mdfind wrapper) |
| `pkim set-metadata` | `set_record_custom_metadata mode="merge"` |
| `pkim set-body` | `update_record_content` (append / insert / replace / patch) |
| `pkim set-tags` | `set_record_tags` |
| `pkim set-name`, `move`, `create-note`, `create-group` | `update_record`, `move_record`, `create_record`, `create_group_path` |
| `pkim mint-id` | Skill-side generator when a human-readable `mdpkim_id` is wanted; DT UUID otherwise |
| `pkim extract-text` | `extract_record_content` |
| `pkim probe-capabilities`, `health-check` | `is_running`, `get_databases`, `list_custom_metadata_fields` |
| `pkim mirror-of` | Skill-side path computation over `get_imported_record_path` |
| `pkim setup-*`, `verify-*`, `install-templates` | `dt-bootstrap-pkim`, `dt-verify-pkim` skills |

## What doesn't change

- The information model: KN / EV / RL / CL records, custom metadata schema, tag vocabulary, WikiLink discipline, mirror rules — all unchanged.
- The safety model: writes are gated by DT's own settings + per-record `Exclude from AI`.
- The operating rhythm: same skill flow, same review states, same audit cadence.
- The design register: all docs numbered ≤ 21 remain the contract for what the corpus IS. Doc 24 changes only *how the mechanics are executed*.

## Anti-patterns doc 24 forbids

- Reintroducing a PKIM-owned runtime layer between skills and DT MCP.
- Wrapping DT MCP tools in "safer" helpers that add opinion. DT MCP is the trusted layer.
- Recreating PKIM_ID as a runtime identity. It is a metadata field. DT UUID is identity.
- Using `[[Name|Display]]` for cross-database references. Item links or nothing.
