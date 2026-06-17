# Information Model

## Purpose

This document defines the conceptual information model only.

It answers:

What kinds of records exist, what identities matter, and what high-level rules govern their structure?

It does not define the concrete field-by-field schema, note templates, relation-note templates, or mirror frontmatter. Those live in [08 Record And Note Specification](08-record-and-note-specification.md).

This is a document-and-link graph with structured relation notes. It is not a native property-graph database.

Graph edges live in note bodies as `[[PKIM_ID|Name]]` WikiLinks. Custom metadata describes properties of the record, not relationships to other records. See [01 Principles And Decisions — Graph edges live in note bodies](01-principles-and-decisions.md#decision-2026-05-16--graph-edges-live-in-note-bodies) and [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md) for the full rule and its narrow exceptions.

## Record Classes

| Class | Purpose | Canonical home |
| --- | --- | --- |
| Evidence record | Original source material, captures, bookmarks, scans, PDFs, snapshots | Evidence databases |
| Knowledge note | Summary, synthesis, interpretation, or durable note | `PKIM-Knowledge` |
| Relation note | Explicit attributed edge between records or concepts | `PKIM-Knowledge` |
| Annotation note | Structured commentary tied to an evidence record | Usually `PKIM-Knowledge`; sometimes colocated in evidence libraries |
| Export mirror item | Portable markdown or manifest generated from native content | Filesystem / repo |

## Identity Model

| Field | Meaning | Notes |
| --- | --- | --- |
| `PKIM_ID` | Stable PKIM identifier | Mint once and never reuse |
| `DT_UUID` | Native DEVONthink UUID | Read from DEVONthink; do not invent |
| `DT_ItemLink` | Native item link | Primary clickable reference outside DEVONthink |
| `DocRole` | Record class | Keep values constrained and searchable |
| `Review_State` | Operational review status | Used for queues and write gating |
| `Origin_URI` | Upstream file or source reference | Especially useful for indexed and captured material |
| `Content_SHA256` | Change detection | Useful in mirrors and export manifests |

## Metadata Rules

- Keep the DEVONthink custom metadata schema small and durable.
- Use native fields where they already exist instead of duplicating them in custom fields.
- Custom metadata describes properties of the record, not relationships to other records. Graph-like structures live in note bodies as `[[PKIM_ID|Name]]` WikiLinks. See [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md).
- Identity pointers on relation notes (`Source_Item`, `Target_Item`) and derived-property fields written back by the mirror are narrow allowed exceptions and must be documented as such.
- Re-read properties after any write and treat the refreshed state as authoritative.

## Structural Rules

- Knowledge is represented as native notes, not as loose metadata blobs on evidence records.
- Relations are first-class objects when they need meaning, review, or lifecycle.
- Mirrors are projections of canonical records, not alternate authoring surfaces.

## Record Lifecycle Model

### Evidence lifecycle

- `evidence -> profiled -> filed`
- `evidence -> profiled -> literature or knowledge note created`
- `evidence <-> annotation linked`

### Knowledge lifecycle

- `knowledge note -> approved -> versioned -> mirrored`

### Relation lifecycle

- `relation note -> approved -> active`

### Mirror lifecycle

- `mirror item -> generated only`

Mirror items are never edited as the source of truth.

## Canonical State Machine

The review-state model is canonical. Do not add free-text variants.

### Canonical review-state vocabulary

- `inbox`
- `profiled`
- `needs-human`
- `approved`
- `blocked`
- `filed`
- `mirrored`
- `archived`
- `error`

### Allowed transitions

| From | To | Trigger | Cleared by |
| --- | --- | --- | --- |
| `inbox` | `profiled` | minimum identity and metadata set | agent or human |
| `profiled` | `needs-human` | uncertainty, ambiguity, or policy stop | agent or human |
| `needs-human` | `approved` | explicit human approval | human |
| `needs-human` | `blocked` | explicit human block or policy denial | human |
| `approved` | `filed` | filing completed | agent or human |
| `approved` | `mirrored` | mirror export completed and verified | agent |
| `filed` | `archived` | retention or lifecycle decision | human |
| `blocked` | `profiled` | issue resolved and item returned to working flow | human |
| `mirrored` | `approved` | canonical note changed and mirror is stale again | agent or human |
| any | `error` | automation run left inconsistent state | agent |
| `error` | `profiled` | issue reviewed and resolved; record returned to working flow | human |

Any other transition is invalid unless the design pack changes.

## Edge Classes

Every proposed or materialised edge must be treated as one of the following classes. Ambiguous edges must not be materialised.

| Class | Description | Example |
| --- | --- | --- |
| `provenance` | Source supports a note or claim | evidence → knowledge note |
| `conceptual` | One concept relates to another as peers | capability → maturity model |
| `structural` | Part-of, component-of, stage-of, or taxonomy relation | phase → programme |
| `contrast` | Conflicts-with, differs-from, limits | model A ↔ model B |
| `operational` | Workflow, project, review, or filing relationship | runbook → step |
| `weak-association` | Discovery-only; noted but not materialised by default | potential link from compare/classify |

Weak associations must not be materialised as relation notes by default. They are discovery signals only. A weak association becomes a candidate edge only when an operator explicitly elevates it.

If an edge does not clearly fit one of the first five classes, treat it as a weak association until further review.

## Source Coverage Status

Every evidence source processed during a corpus pass must have a `SourceCoverageStatus` recorded in the candidate ledger. This field tracks whether the source has been adequately represented in the knowledge graph.

Valid values:

| Value | Meaning |
| --- | --- |
| `unassessed` | Source has not been profiled |
| `source-note-only` | A bare reference note exists; no concept decomposition done |
| `partially-decomposed` | Some concepts extracted; others known to be missing |
| `fully-decomposed` | Concept set is complete and graph-ready |
| `deferred` | Deliberate decision to defer deeper processing |
| `needs-human-review` | Operator flagged for human judgement before continuing |

For dense sources, a `source-note-only` status is insufficient before the full deep pass. A source may have one good note but still be under-mapped.

## Detailed Companion

Use [08 Record And Note Specification](08-record-and-note-specification.md) for:

- exact metadata fields
- concrete note templates
- relation-note structure
- mirror file structure
- run artifact shapes
