# Purpose And Principles

## Purpose

PKIM is a local knowledge operating system built around DEVONthink. It turns incoming material into a curated, linked, reviewable knowledge corpus: evidence is captured, knowledge notes explain what it means, relation notes wire the graph together, and mirrors keep the whole thing portable.

This document says why the system exists, what it is, and what will not be violated. Everything else in the design register (models, workflows, operating rules, runtime) follows from here.

## What PKIM is

- A document-and-link graph with structured relation notes.
- A single-user tool for a knowledge worker with a serious body of evidence to keep and reason about.
- A supported surface for LLM-assisted operation: skills orchestrate, DEVONthink's MCP server executes, humans review at the gates that matter.

## What PKIM is not

- Not a property-graph database. Edges live in note bodies as WikiLinks, not as scalar metadata pointers.
- Not a multi-user collaboration tool.
- Not a replacement for DEVONthink. DEVONthink is the canonical store; PKIM is the operating layer around it.
- Not a place to run large ingest pipelines. Volume comes second to review.

## Principles

The principles that hold across every workflow, skill, and design decision.

### 1. DEVONthink is the system of record

Native records, native metadata, native item links, native queues via smart groups. Do not build parallel state that competes with DEVONthink's own. The repo owns design, skills, and operational history — not canonical data.

### 2. Separate evidence from knowledge

Evidence records preserve originals, captures, and references. Knowledge notes hold the interpretation. They live in different databases so search context stays dense, filing rules stay clean, and mobile / sync policy can differ.

### 3. Graph edges live in note bodies

`[[PKIM_ID|Name]]` WikiLinks (within a database) and `x-devonthink-item://<uuid>` item links (across databases). Custom metadata describes *properties* of a record — never relationships to other records. See [02 Information Model](02-information-model.md) §Metadata classification for the PROPERTY / INDEX-POINTER / DERIVED discipline.

The narrow exceptions:
- `Source_Item` / `Target_Item` on relation notes — index pointers that duplicate the body's WikiLinks.
- Derived fields written by the export mirror (`Claim_Backed`, evidence counts) — computed, never authored.

### 4. Cross-database references use item links

DEVONthink's markdown renderer resolves `[[Name|Display]]` WikiLinks within one database only. A knowledge note in `PKIM-Knowledge` referring to an evidence record in `PKIM-Evidence-*` uses `x-devonthink-item://<uuid>`. Getting this wrong produces dangling references the audit will catch.

### 5. Stable identity, human-readable

Every record carries two identifiers:
- **DT UUID** — the persistent identifier for cross-references; assigned by DEVONthink on record creation.
- **PKIM_ID** — human-readable index (`<CLASS>-YYYYMMDD-NNNN`) — filename-compatible, sortable by class and date, stored as `mdpkim_id` custom metadata and as an alias.

DT UUID is identity. PKIM_ID is an index.

### 6. Safety over convenience

Read actions can be liberal. Writes are gated by DEVONthink's own controls (`Exclude from AI` per record, `Exclude from Chat & MCP` per database). Every touched record ends up tagged (structural + topical axes). Delete is administrative — DEVONthink's Trash first, human review second, permanent removal only when necessary.

### 7. Native queues, not custom dashboards

DEVONthink smart groups are the primary operational view. The ten canonical smart groups (`Needs Profile`, `Needs OCR`, `Needs Knowledge Note`, `Needs Relation Note`, `Needs Filing`, `Indexed Risk`, `Mirror Drift`, `Automation Error`, `Needs Human Review`, `Ready for Mirror`) live in DEVONthink. Custom UIs and status reports are not part of the system.

### 8. Concentrated context

Multiple focused databases, not one giant everything-store. Search, DEVONthink AI utility, and skill reliability all degrade when context dilutes. The five canonical databases (`PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`) are the shape — see [04 DEVONthink Operating Model](04-devonthink-operating-model.md).

### 9. Named tools, not improvised sequences

The operational surface is four named skills (`pkim-primer`, `dt-bootstrap`, `dt-intake`, `dt-audit`) composing DEVONthink 4.3+'s MCP tools. When the LLM catches itself sequencing ad-hoc DT MCP calls that overlap a skill, it invokes the skill instead. Named tools prevent drift.

### 10. Portable mirror, not portable canon

The on-disk indexed root that `PKIM-Knowledge` references (iCloud-synced) *is* the portability surface. It's a projection of canonical native notes for Git tooling, external editors, and disaster recovery. It is never authoritative — DEVONthink is.

## Ontology control

Do not let tag axes, relation types, note types, review states, or queue names drift into an uncontrolled ontology. Vocabularies are closed sets:

- **Record classes**: `evidence`, `knowledge`, `relation`, `claim` (see [02 Information Model](02-information-model.md)).
- **Note types** (KN sub-class): `literature`, `synthesis`, `topic`, `project`, `decision`, `workflow`.
- **Relation types**: `supports`, `contradicts`, `extends`, `summarizes`, `references`, `exemplifies`, `precedes`, `supersedes`.
- **Claim types**: `fact`, `inference`, `assumption`, `open-question`.
- **Confidence bands**: `low`, `medium`, `high`.
- **Review states**: see [06 Operations And Safety](06-operations-and-safety.md).

Extending a vocabulary requires updating the relevant design brief in the same change.

## Where these principles are enforced

Principle | Enforcement site
---|---
1 — DEVONthink is the system of record | [04 DEVONthink Operating Model](04-devonthink-operating-model.md), [07 Runtime](07-runtime.md)
2 — Evidence vs knowledge separation | [02 Information Model](02-information-model.md), [04 DEVONthink Operating Model](04-devonthink-operating-model.md)
3 — Edges in bodies | [03 Record And Note Specification](03-record-and-note-specification.md), `dt-audit` skill
4 — Cross-DB item links | [03 Record And Note Specification](03-record-and-note-specification.md), `dt-audit` skill
5 — Stable identity | [02 Information Model](02-information-model.md), [03 Record And Note Specification](03-record-and-note-specification.md)
6 — Safety over convenience | [06 Operations And Safety](06-operations-and-safety.md), DEVONthink write-gate settings
7 — Native queues | [04 DEVONthink Operating Model](04-devonthink-operating-model.md) §Smart groups
8 — Concentrated context | [04 DEVONthink Operating Model](04-devonthink-operating-model.md) §Databases
9 — Named tools | [07 Runtime](07-runtime.md), `skills/README.md`
10 — Portable mirror | [05 Workflows](05-workflows.md) §Workflow 5, `dt-intake` mirror-adjacent references
