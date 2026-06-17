# Record And Note Specification

## Purpose

This document defines the precise structural contract for records, metadata, native notes, relation notes, export mirrors, and run-linked artifacts.

The design has to survive four different pressures:

- native DEVONthink use
- automation through MCP and local helpers
- external Git-based portability
- mixed-agent execution by Claude Code and Codex CLI

Two structural rules govern every contract in this document:

- **Graph edges live in note bodies as `[[PKIM_ID|Name]]` WikiLinks.** Custom metadata describes properties of the record, not relationships to other records. The only allowed exceptions are identity pointers on relation notes and derived-property fields written back by the export mirror. See [01 Principles And Decisions — Graph edges live in note bodies](01-principles-and-decisions.md#decision-2026-05-16--graph-edges-live-in-note-bodies) and [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md).
- **Every field must be classified** at design time as PROPERTY, INDEX-POINTER, or DERIVED. Fields that do not fit one of these classifications are not added to the schema.

## Record Taxonomy

| Class | Code | Canonical location | Notes |
| --- | --- | --- | --- |
| Evidence | `evidence` | Evidence databases | Original source object or stable capture |
| Knowledge note | `knowledge` | `PKIM-Knowledge` | Durable interpretation or synthesis |
| Relation note | `relation` | `PKIM-Knowledge` | Explicit attributed edge |
| Annotation note | `annotation` | Usually `PKIM-Knowledge` | Reading notes attached to evidence |
| Project note | `project` | `PKIM-Knowledge` | Working context for a bounded effort |
| Topic note | `topic` | `PKIM-Knowledge` | Curated topical anchor |
| Operational record | `operation` | Repo or `PKIM-Knowledge/Operations` | Diagnostics, runs, queue outputs |

## Identifier Contract

### `PKIM_ID`

This is the stable local identifier used everywhere outside DEVONthink’s own hidden state.

Rules:

- minted once
- never reassigned
- never overloaded with path semantics
- human-readable enough for operators to reason about
- short enough to survive filenames and mirrors

Canonical format:

`<class-prefix>-<YYYYMMDD>-<NNNN>`

Where `NNNN` is a zero-padded 4-digit sequence counter scoped to the date and class prefix. The counter resets each calendar day per prefix.

Examples:

- `EV-20260417-0007`
- `KN-20260417-0021`
- `RL-20260417-0004`

Canonical class prefixes: `EV` (evidence), `KN` (knowledge), `RL` (relation).

If ULIDs or UUIDs are adopted later, keep the displayed short identifier anyway. Operators need something they can read without hating you.

### `DT_UUID`

The DEVONthink UUID is the authoritative native pointer for the record. It should be stored in mirrors and logs, but not invented or edited outside DEVONthink.

### `DT_ItemLink`

This is the canonical clickable reference for:

- repo mirrors
- run artifacts
- exported notes
- local dashboards

It should be present anywhere a record is referenced outside DEVONthink.

## Metadata Schema

### Field discipline

Every custom metadata field has exactly one classification, recorded at design time:

- **PROPERTY** — a quality of the record itself. Passes the test: *if every other record disappeared, would this field still be meaningful?*
- **INDEX-POINTER** — a pointer to another record's identity that duplicates a WikiLink already present in this record's body. Allowed only on relation notes (`Source_Item`, `Target_Item`).
- **DERIVED** — a value computed by automation (typically the export mirror) from corpus state. Never authored by humans. Not authoritative.

Any field that does not fit one of these classifications is not added to the schema. Fields whose value is another record's `PKIM_ID` and whose intent is to express a relationship are banned (edge-in-metadata). See [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md) and the audit at [19 Synthesis Uplift Plan — Appendix A](19-synthesis-uplift-plan.md#appendix-a--field-audit-table-wp02).

### Canonical field set

The following field names are canonical and must not drift casually:

| Field | Role |
| --- | --- |
| `PKIM_ID` | stable local identifier |
| `DocRole` | canonical record class |
| `Review_State` | bounded review-state vocabulary |
| `Origin_URI` | upstream source URI or path |
| `Origin_Last_Path` | last known path for indexed evidence only |
| `Source_Item` | source item link |
| `Target_Item` | target item link |
| `Relation_Type` | relation type |
| `Mirror_Path` | export location pointer |
| `Content_SHA256` | integrity field, never primary identity |

No ad hoc field drift without an explicit schema change.

### Core fields

These should exist for all meaningful records:

| Field | Required | Meaning |
| --- | --- | --- |
| `PKIM_ID` | yes | Stable local ID |
| `DocRole` | yes | Taxonomy class |
| `Review_State` | yes | Operational review status |
| `CreatedByMode` | no | `human`, `automation`, or `mixed` |
| `Origin_URI` | conditional | Original file path, URL, or source URI |
| native `kind` property | yes | DEVONthink-native file kind; use this instead of a custom `SourceType` field |
| `LastProfiledAt` | no | Last profiling timestamp |
| `LastMirroredAt` | no | Last export timestamp |
| `LastRunID` | no | Most recent automation run touching the record |

### Evidence-specific fields

| Field | Meaning |
| --- | --- |
| `EvidenceStatus` | `raw`, `ocrd`, `reviewed`, `linked`, `archived` |
| `Origin_Last_Path` | Most recent local filesystem path for indexed items |
| `Content_SHA256` | Change detection and integrity |
| `CaptureType` | `imported`, `indexed`, `bookmark`, `snapshot`, `scan` |
| `CanonicalSourceURL` | Upstream source link when meaningful |

### Knowledge-specific fields

| Field | Meaning |
| --- | --- |
| `NoteType` | `literature`, `synthesis`, `topic`, `project`, `decision`, `workflow` |
| `KnowledgeStatus` | `seed`, `active`, `reviewed`, `published`, `archived`, `needs-review` |
| `KnowledgeConfidence` | `low`, `medium`, `high` — worst-case claim confidence on the note (see §Knowledge confidence) |
| `Mirror_Path` | Export mirror target path |
| `EvidenceCount` *(DERIVED)* | Count of `[[EV-…]]` WikiLinks under `## Evidence links`. Computed by the export mirror, never authored by humans. Not authoritative graph data. |
| `Claim_Backed` *(DERIVED)* | `yes`/`partial`/`no` — whether all `fact`/`inference` claims have resolved evidence WikiLinks. Computed by mirror. |

### Relation-specific fields

| Field | Meaning |
| --- | --- |
| `Relation_Type` | Type of edge expressed |
| `Source_Item` | Native item link to source |
| `Target_Item` | Native item link to target |
| `RelationConfidence` | Optional confidence indicator |
| `RelationStatus` | `proposed`, `reviewed`, `accepted`, `retired` |

### `Relation_Type` vocabulary

The canonical relation type vocabulary is closed. Add types only through an explicit schema change recorded in `docs/design/00-source-reconciliation.md`.

| Type | Meaning |
| --- | --- |
| `supports` | source provides reasoning, evidence, or grounding for target |
| `contradicts` | source challenges, refutes, or conflicts with target |
| `extends` | source builds on, elaborates, or deepens target |
| `summarizes` | source is a synthesis or compression of target content |
| `references` | source cites or links to target (weakest structural relation; use sparingly) |
| `exemplifies` | source is a concrete case, example, or instance of target |
| `precedes` | source is logically or temporally prior to target |
| `supersedes` | source replaces or significantly updates target |

If no type fits cleanly, use `references` and explain the real relationship in the rationale body.

### Operational queue signals

These bounded operational fields or signals govern native queues. Do not invent parallel queue signals casually.

| Field or signal | Meaning |
| --- | --- |
| `Needs_OCR` | OCR is required but not yet complete |
| `Knowledge_Link_State` *(DERIVED)* | Evidence-to-knowledge linkage status, computed by mirror analysis of body WikiLinks. Never authored. |
| `Relation_Gap_State` *(DERIVED)* | Relation-note coverage status, computed by mirror analysis. Never authored. |
| `Indexed_Risk_State` | indexed item is at path or refresh risk |
| `Mirror_State` | mirror freshness relative to canonical note state |
| `Automation_Last_Run_State` | last automation run left an error or clean state |

## `PKIM_ID` Behaviour

- mint once
- never recycle
- store on every canonical record
- mirror into exported note metadata
- include as an alias on knowledge notes

## Review State Model

Keep this tight. Too many states and nobody knows what anything means.

Canonical values:

- `inbox`
- `profiled`
- `needs-human`
- `approved`
- `blocked`
- `filed`
- `mirrored`
- `archived`
- `error`

Interpretation:

- `inbox`: no useful operator meaning yet
- `profiled`: basic machine and metadata pass complete
- `needs-human`: human decision required; **automation must not progress this record's state until it is cleared**

  Routes that flip a record into `needs-human` automatically:
  - mirror-side `dt-detect-contradictions` finds an unresolved corpus-level contradiction involving this record (per [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) §Contradiction handling)
  - `dt-audit-claim-evidence` returns `verdict: degraded` against a `published` KN
  - the `pkim sweep-inbox` skill cannot resolve a record's intended classification

  Clearing the flag requires the human reviewer to either revise the record (then explicitly set `Review_State` to the next normal state) or to retire it. Automated workflows skip `needs-human` records — they are visible in queues but excluded from auto-processing — until cleared.
- `approved`: safe for the next bounded automation step
- `blocked`: cannot proceed without intervention
- `filed`: in accepted long-term location
- `mirrored`: mirror export completed and verified for this note
- `archived`: intentionally inactive
- `error`: automation run left inconsistent state; requires review before proceeding

`error` is an interrupt state. It can be set from any state when automation fails. It does not imply a fixed recovery path; the specific error determines what is done next.

## Native Knowledge Note Spec

### Canonical form

Knowledge notes are DEVONthink Markdown documents with **MultiMarkdown metadata headers** at the top of the file. DEVONthink parses these headers natively and maps the standard keys (`Title`, `Aliases`, `Tags`, `Author`, `Keywords`, `URL`, `Date`) into its corresponding native properties. PKIM-specific custom metadata fields (`PKIM_ID`, `DocRole`, `Review_State`, `KnowledgeStatus`, `NoteType`) continue to be set on the DT record via JXA; the MMD header carries them as human-readable lines for portability but is not the authoritative store. See [01 Principles And Decisions — MultiMarkdown headers are the canonical native note format](01-principles-and-decisions.md#decision-2026-05-16--multimarkdown-headers-are-the-canonical-native-note-format).

Mirror files use YAML frontmatter for portability; see §Export Mirror Spec. The two formats are semantically equivalent.

Example:

```markdown
Title: Problem framing in local second-brain systems
Aliases: problem framing; local second-brain; KN-20260417-0021
Tags: pkim, design, knowledge
PKIM_ID: KN-20260417-0021
DocRole: knowledge
NoteType: synthesis
Review_State: approved
KnowledgeStatus: active
KnowledgeConfidence: medium

# Problem framing in local second-brain systems

## Summary

Short overview of the note's purpose.

## Claims

```yaml
- claim: "Local-first systems reduce sync overhead for personal knowledge work"
  type: inference
  confidence: medium
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
  contradicted_by: []
  note: "Inferred from primary source; consistent framing."
```

## Evidence Links

- [Primary source title](x-devonthink-item://EV-UUID)

## Related Notes

- [[KN-20260417-0009|DEVONthink operating model]]
```

### Structural rules

- title should describe the thought, not the filing destination
- `PKIM_ID` appears as an MMD header line *and* in the `Aliases` header (so DT discovery finds it)
- the MMD header block is separated from the body by a single blank line
- **`## Evidence Links`** cites cross-database EV records using `[Name](x-devonthink-item://UUID)` item-links — EV records live in PKIM-Pilot / PKIM-Evidence-*, which are separate databases from PKIM-Knowledge; WikiLinks do not resolve across databases and must not be used here
- **`## Related Notes`** links to same-database KN/CL records using `[[PKIM_ID|Name]]` WikiLinks
- claims live in a fenced YAML block under `## Claims` per [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) — replacing the legacy free-prose `## Key points` list
- the note body should remain human-readable without hidden automation state
- claims live in a fenced YAML block under `## Claims` per [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) — replacing the legacy free-prose `## Key points` list
- the note body should remain human-readable without hidden automation state

### Knowledge confidence

The `KnowledgeConfidence` field is a PROPERTY-classified custom metadata field summarising the worst-case claim confidence on the note:

| `KnowledgeConfidence` | Meaning |
| --- | --- |
| `high` | All claims of type `fact` or `inference` have `confidence: high`. No claims sit at `low`. |
| `medium` | At least one supported claim is `medium`; no `low` claims. |
| `low` | At least one claim of type `fact` or `inference` sits at `low` confidence. |

Computed by the export mirror as a DERIVED helper but stored as a PROPERTY on the record so DT smart groups can filter by it. `KnowledgeStatus=published` notes must not carry `KnowledgeConfidence=low`; the audit flags violations.

### Claims block (required for reviewed and published KNs)

Knowledge notes with `KnowledgeStatus ∈ {reviewed, published}` must include a `## Claims` section containing at least one structured claim block. The full schema (claim, type, confidence, evidence, contradicted_by, optional note), confidence ladder, and contradiction-handling rules live in [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md). The audit detector `missing-claims` enforces this requirement at the corpus level.

### Migration of legacy `## Key points` notes

Existing knowledge notes authored before WP1.2 carry free-prose `## Key points` lists rather than structured claims. The migration approach is **refactor on touch**, not a single big-bang rewrite:

1. On WP1.2 land, every existing KN is flipped from its current `KnowledgeStatus` to `needs-review` via a one-shot mirror-driven write. The legacy `## Key points` section is preserved as the source material for the eventual rewrite.
2. As each KN is touched in normal operations, the operator (or `dt-build-claim-ledger`) converts the prose points into structured claim blocks under a new `## Claims` section, then advances the lifecycle from `needs-review` to `active` / `reviewed` / `published`.
3. The audit reports `needs-review` count over time so the migration backlog is visible.

`## Key points` remains a permitted section name on `KnowledgeStatus ∈ {seed, active}` notes as a transitional shape; it is not permitted on `reviewed` or `published`.

## Relation Note Spec

### Purpose

A relation note is a first-class record representing a meaningful edge in the graph.

### When to create one

Create a relation note when:

- the link has explanatory value
- the edge is not obvious from proximity alone
- the edge may need review or retirement later
- the relationship carries directionality or semantics
- tags alone would flatten too much meaning

### Canonical template

Relation notes use the same MultiMarkdown header format as knowledge notes. `Source_Item` and `Target_Item` remain as `x-devonthink-item://` links in the header because they survive renames and are the stable native pointer; the body independently carries the two endpoints as `[[PKIM_ID|Name]]` WikiLinks so DEVONthink's See Also, back-references, and graph traversal see the edge.

```markdown
Title: Relation - problem framing supports local-first PKIM
PKIM_ID: RL-20260417-0004
DocRole: relation
Relation_Type: supports
Source_Item: x-devonthink-item://SOURCE-UUID
Target_Item: x-devonthink-item://TARGET-UUID
Review_State: approved
RelationStatus: accepted

# Why this relation exists

This relation note records that the source note provides the reasoning basis for the target operating principle.

## Endpoints

- Source: [[KN-20260417-0021|Problem framing in local second-brain systems]]
- Target: [[KN-20260417-0050|Local-first PKIM operating principle]]

## Evidence

- [[EV-20260417-0007|Primary source title]]

## Interpretation

The source note frames the trade-off explicitly, while the target note converts that into a durable design decision.
```

### Non-negotiable relation-note contract

- its own `PKIM_ID`
- `DocRole=relation`
- exactly one `Source_Item` (as `x-devonthink-item://` link in the MMD header)
- exactly one `Target_Item` (as `x-devonthink-item://` link in the MMD header)
- exactly one `Relation_Type` from the canonical vocabulary
- a required `## Endpoints` body section containing two `[[PKIM_ID|Name]]` WikiLinks — one for the source, one for the target — that resolve to the same records as `Source_Item` and `Target_Item`
- mandatory short human-readable rationale (minimum one sentence)
- optional `RelationConfidence`

Without the explanation, it is just metadata pretending to be knowledge. A relation note with no rationale is invalid and must not be created or accepted by automation. A relation note whose body lacks the `## Endpoints` WikiLinks is also invalid: the metadata pointers alone do not make the edge visible to DEVONthink's graph features.

### Evidence requirement for restricted relation types

For relation types where the claim of the relation depends on substantive grounding, a body `## Evidence` section is **required** and must contain at least one `[[EV-…|Name]]` or `[[KN-…|Name]]` WikiLink:

- `supports`
- `contradicts`
- `supersedes`

An unsupported `contradicts` or `supports` is the assertion-pretending-to-be-knowledge antipattern the synthesis uplift exists to prevent. Validation rejects RL records of these types if the `## Evidence` section is missing or empty. Other relation types (`extends`, `summarizes`, `references`, `exemplifies`, `precedes`) may include `## Evidence` but it is not required.

## Annotation And Knowledge Hygiene

- annotations are source-adjacent working notes
- literature or knowledge notes are canonical synthesis objects
- relation notes are canonical edge objects
- final synthesis must not live in both annotations and knowledge notes

## Canonical Note Metadata Templates

### Knowledge note

Use the native knowledge note template above as the canonical pattern.

### Relation note

Use the relation note template above as the canonical pattern.

### Annotation-note export

If annotations are exported, preserve:

- `PKIM_ID` if one exists
- source reference
- annotation role
- no claim that the export is the canonical synthesis object

### Topic or project note

Minimum metadata:

- `PKIM_ID`
- `DocRole`
- `NoteType`
- `Review_State`

Topical grouping is expressed through tags, body WikiLinks to a topic note, or `Aliases`, not through a scalar metadata pointer field. Do not create competing note metadata conventions.

## Graph Semantics

### What counts as an edge

- explicit item link
- relation note
- annotation backlink
- WikiLink
- mention
- compare or classify suggestion

### Edge ranking

Authoritative edges:

- explicit item links used as maintained references
- reviewed relation notes

Reviewable inferred edges:

- annotation backlinks
- compare and classify suggestions

Non-authoritative discovery edges:

- WikiLinks
- mentions
- graph-view neighbourhoods

## Topic Note Spec

Topic notes should act as local semantic anchors, not taxonomy bureaucrats.

They are useful for:

- grouping related notes without over-tagging
- collecting canonical links
- explaining what a topic means in this system
- giving operators a stable landing page

Suggested sections:

- what the topic means
- what it excludes
- key notes
- key evidence
- open questions

## Export Mirror Spec

### Purpose

The export mirror exists for:

- Git history
- external LLM access
- bulk analysis
- disaster recovery
- publication and transformation pipelines

It does not exist to replace native authoring.

### Mirror contract

Define all of the following explicitly:

- what gets mirrored: knowledge notes and relation notes where `Review_State=approved`
- when it gets mirrored: when `Review_State=approved` AND (`Mirror_State` is absent or stale OR note content has changed since last mirror); also on scheduled refresh or explicit operator request
- how drift is detected: note state changes without a corresponding mirror refresh
- what metadata is preserved: stable IDs, item links, role, review state, export timestamp
- what is regenerated on export: frontmatter, export manifests, derived path placement
- what must never be edited in the mirror: canonical note meaning or in-app state

### Output rules

Every mirrored note should preserve:

- `PKIM_ID`
- title
- `DT_UUID`
- `DT_ItemLink`
- `DocRole`
- last export timestamp
- source and relation links
- enough metadata to rebuild context without DEVONthink open

### Mirror frontmatter (YAML)

Mirror files use YAML frontmatter for portability with external tooling. The mirror exporter translates the native MMD header into this YAML block; the two are semantically equivalent and round-trip-testable.

```yaml
---
pkim_id: KN-20260417-0021
dt_uuid: 03CF4017-1689-4112-9213-E96C1EA37FD0
dt_item_link: x-devonthink-item://03CF4017-1689-4112-9213-E96C1EA37FD0
doc_role: knowledge
note_type: synthesis
review_state: approved
knowledge_status: active
aliases:
  - problem framing
  - local second-brain
  - KN-20260417-0021
mirrored_at: 2026-04-17T14:10:00Z
mirror_path: knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md
---
```

Relation notes additionally include:

```yaml
source_item: x-devonthink-item://SOURCE-UUID
target_item: x-devonthink-item://TARGET-UUID
relation_type: supports
```

WikiLinks in the body are preserved verbatim in the mirror; they are PKIM_ID-anchored (`[[PKIM_ID|Name]]`) so they remain resolvable in any markdown viewer that can look up by ID.

### Mirror naming

Do not depend on titles alone. Include the stable ID in the filename or path.

Recommended patterns:

- `knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md`
- `relations/RL-20260417-0004-problem-framing-supports-local-first-pkim.md`

## Export Manifest Spec

Each export run should produce a manifest describing what changed.

Suggested manifest shape:

```json
{
  "run_id": "RUN-2026-04-17T14-10-00Z",
  "database": "PKIM-Knowledge",
  "mirrored_at": "2026-04-17T14:10:00Z",
  "records": [
    {
      "pkim_id": "KN-20260417-0021",
      "dt_uuid": "03CF4017-1689-4112-9213-E96C1EA37FD0",
      "doc_role": "knowledge",
      "export_path": "knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md",
      "content_hash": "sha256:...",
      "status": "updated"
    }
  ]
}
```

## Run Manifest Contract

Every export or automation run should produce a machine-readable manifest with:

- run ID
- timestamp
- tool versions
- database name
- record IDs touched
- actions proposed
- actions applied
- errors
- mirror paths generated

## Citation And Provenance Rule

Any canonical synthesis note must contain:

- a source link or `Source_Item` reference
- quoted or paraphrased provenance where relevant
- an explicit indication of whether a statement is extracted, inferred, or operator-authored

## Run Artifact Spec

Every automation run that touches state should emit:

- run ID
- runtime name
- start and end time
- target database
- action set
- dry-run or live mode
- records touched
- before and after summaries
- errors
- rollback action if any

This is the same whether the caller is Claude Code or Codex CLI.

## Validation Rules

### For native notes

- the file begins with a MultiMarkdown header block separated from the body by a single blank line
- `PKIM_ID` exists
- `Title` header exists
- `DocRole` header exists
- `Aliases` header includes the `PKIM_ID` value
- body is not empty
- every metadata field present on the record has a documented classification (PROPERTY, INDEX-POINTER, or DERIVED) — no unclassified fields

### For knowledge notes

- all native-note rules above
- when `KnowledgeStatus ∈ {reviewed, published}` a `## Claims` section exists and contains at least one well-formed claim block per [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md)
- every claim of type `fact` or `inference` has at least one resolvable `evidence` WikiLink
- when `KnowledgeStatus=published`, `KnowledgeConfidence` is not `low`
- when `KnowledgeStatus=published`, no claim in the note carries an empty `claim` text or duplicates another claim's text within the same note

### For relation notes

- all native-note rules above
- `Source_Item` and `Target_Item` both exist as `x-devonthink-item://` links in the MMD header
- exactly one `Relation_Type` from the canonical vocabulary
- a `## Endpoints` body section exists and contains two `[[PKIM_ID|Name]]` WikiLinks resolving to the same records as `Source_Item` and `Target_Item`
- a short rationale (≥ 1 sentence) exists in the body
- for `Relation_Type ∈ {supports, contradicts, supersedes}`: a `## Evidence` body section exists and contains at least one `[[EV-…|Name]]` or `[[KN-…|Name]]` WikiLink

### For mirrors

- native item link is present
- export path matches the naming convention
- frontmatter is parseable YAML and is semantically equivalent to the MMD header of the source record

### For the corpus (graph integrity)

- no scalar custom metadata field on any record has a value that is another record's `PKIM_ID` unless the field is an INDEX-POINTER documented as such (currently only `Source_Item` and `Target_Item` on relation notes)
- every WikiLink in a note body resolves to an existing PKIM record, or the link is reported as a dangling-link finding

## Alias and Link Policy

### Alias policy

- Every canonical knowledge note must include `PKIM_ID` in the DEVONthink `Aliases` field.
- The `Aliases` MultiMarkdown header line must include both a human-readable title alias and the `PKIM_ID`, separated by `;`.
- Example: `Aliases: local second brain; problem framing; KN-20260417-0021`
- Relation notes do not use aliases (they are not discovery targets in the same way).

### Link policy

- Stable authoritative references must use `x-devonthink-item://` links.
- `Source_Item` and `Target_Item` fields on relation notes must be `x-devonthink-item://` links. WikiLinks are prohibited for these fields.
- Evidence links in knowledge note bodies must be `x-devonthink-item://` links for the primary evidence reference.
- WikiLinks may appear in the **Related notes** section of knowledge notes for discovery, but not as authoritative references in mirrors or manifests.
- Never mint or invent a DEVONthink item link outside DEVONthink; always read `DT_ItemLink` from the live record.

## Anti-Patterns

Avoid:

- YAML frontmatter as the canonical native-note header format (DEVONthink does not parse it into native properties). Use MultiMarkdown headers in native notes; YAML stays in the mirror.
- giant metadata schemas where half the fields are always blank
- encoding graph meaning in filenames
- building relation semantics purely through tags
- mirror files with no stable native pointer back to DEVONthink
- scalar metadata fields whose value is another record's `PKIM_ID` and whose intent is to express a relationship (edge-in-metadata). Graph edges live in note bodies as WikiLinks. See [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md).
- relation notes whose body lacks `## Endpoints` WikiLinks — the metadata pointers alone do not produce a DEVONthink-visible edge
- `contradicts`, `supports`, or `supersedes` relation notes without an `## Evidence` body section
