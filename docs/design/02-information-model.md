# Information Model

## Purpose

Conceptual model. What kinds of records exist, what identities matter, and the rules that govern their structure. The concrete schema (fields, types, allowed values, templates) lives in [03 Record And Note Specification](03-record-and-note-specification.md); this document says why the shape is what it is.

## Record classes

Four record classes. Each has one canonical home and one distinguishing rule.

| Class | Code | Canonical database | Rule that separates it |
|---|---|---|---|
| **Evidence** | `EV` | `PKIM-Evidence-*` (never in `PKIM-Knowledge`) | Original source material. What the corpus is built on. Preserves an artefact you did not author. |
| **Knowledge note** | `KN` | `PKIM-Knowledge` | Native markdown authored *from* evidence. Explains what the material means. Every KN is your interpretation, not the source. |
| **Relation note** | `RL` | `PKIM-Knowledge` | First-class attributed edge between two records. Exists because scalar metadata is not a graph edge. Every RL has a prose rationale and a closed-vocabulary type. |
| **Claim** | `CL` | `PKIM-Knowledge` | Individual claim promoted out of a KN's `## Claims` block into its own record. Exists so a claim can be tagged, cited, contradicted, and audited independently of the KN it was extracted from. |

### Why four, not fewer

- **Merging EV and KN would fail**: evidence is a preservation surface (imported / indexed, immutable content); knowledge notes are edited synthesis. Their filing, sync, and mobile policies differ.
- **Merging RL into note bodies would fail**: relationships need to be tagged, dated, and audited as edges. WikiLinks in prose carry semantics but not lifecycle.
- **Merging CL back into KN would fail**: a single claim needs to be individually addressable. When two KNs contradict each other's claim about X, a CL record is the thing the audit refers to.

### Why not more

- No `Annotation` class. Annotations are working notes; if one becomes durable it graduates to KN.
- No `Person`, `Concept`, `Topic` as first-class classes. Those live as tags (`entity/`, `concept/`, `domain/`) and as topic KNs where the concept warrants a landing page.

## Identity

Every record carries two identifiers. Neither is optional.

### DT UUID — identity

Assigned by DEVONthink on record creation. Persistent, opaque, unique across the whole system. Used for cross-references in item links (`x-devonthink-item://<UUID>`). The audit walks these; the mirror stores them; every cross-database reference is one.

### PKIM_ID — human-readable index

Format: `<CLASS>-YYYYMMDD-NNNN`. Zero-padded 4-digit sequence, resets per class and date.

- `EV-20260417-0007`
- `KN-20260417-0021`
- `RL-20260417-0004`
- `CL-20260517-0001`

Minted once, never reassigned. Stored as `mdpkim_id` custom metadata AND as an entry in the record's DEVONthink `Aliases` field (so `lookup_records name: "KN-..."` finds it).

**Why both.** DT UUID is durable but unreadable; PKIM_ID is readable but not native. Skills mint PKIM_ID for filenames and human context; automation looks up records by UUID.

## Metadata classification

Every custom metadata field has exactly one classification, decided at design time. Fields that don't fit one of these classifications are not added to the schema.

| Classification | Meaning | Test |
|---|---|---|
| **PROPERTY** | A quality of the record itself. | If every other record in the corpus disappeared, would this field still be meaningful? |
| **INDEX-POINTER** | Points to another record's identity, but only where the same edge is *already* present as a body WikiLink. | Removing the metadata does not remove the edge. Currently: `Source_Item`, `Target_Item` on relation notes only. |
| **DERIVED** | Computed by the export mirror or an audit from corpus state. Never authored by humans. | Would this value change if a *different* record changed? If yes, and it's a summary, it's DERIVED. |

### Why the classification matters

A scalar metadata field whose value is another record's PKIM_ID and whose intent is to express a relationship is an **edge-in-metadata**. DEVONthink cannot see it as a graph edge (see [04 DEVONthink Operating Model](04-devonthink-operating-model.md) §What DT treats as a relationship). Every edge-in-metadata is a relationship the See Also, back-reference, and AI features can't traverse. The classification discipline prevents this failure mode.

### Banned patterns

- `RelatedTo`, `Supersedes`, `Contradicts`, `SupportedBy`, `DerivedFrom` as scalar metadata fields whose value is another record's PKIM_ID.
- Comma-separated PKIM_ID lists in metadata used as adjacency lists.
- A custom metadata field as a substitute for a relation note.

## Lifecycle

Every record moves through a small number of states. The vocabulary is closed.

### Review-state vocabulary

| State | Meaning |
|---|---|
| `inbox` | Arrived. No useful operator meaning yet. |
| `profiled` | Class and baseline metadata set; basic identity established. |
| `needs-human` | Automation deliberately paused. Human decision required before this record progresses. |
| `approved` | Safe for the next bounded automation step. |
| `filed` | In its long-term filing destination. |
| `blocked` | Cannot proceed. Different from `needs-human` — this is stuck, not paused. |
| `mirrored` | Mirror export completed and verified (KN-only). |
| `archived` | Intentionally inactive. |
| `error` | Automation left inconsistent state. Interrupt; needs review before proceeding. |

### Allowed transitions

```
inbox → profiled → {needs-human | approved | error}
needs-human → {approved | blocked | archived}    (human-driven only)
approved → filed                                  (agent or human)
approved → mirrored                                (agent, KN-only, when mirror sync completes)
blocked → profiled                                (human-driven; issue resolved)
filed → archived                                  (retention decision)
mirrored → approved                                (canonical note changed after mirror)
any → error                                        (automation failure)
error → profiled                                   (human-driven; recovery)
```

Any other transition is invalid. Extending the vocabulary requires an update to this table.

### Class-specific status ladders

Each class has an additional status field that runs in parallel to `review_state`:

- **EV**: `evidencestatus ∈ {proposed, approved, retired, superseded}`
- **KN**: `knowledgestatus ∈ {active, reviewed, published, archived}`, plus `knowledgeconfidence ∈ {low, medium, high}` derived from claim block
- **RL**: `relationstatus ∈ {proposed, reviewed}`, plus `relationconfidence ∈ {low, medium, high}`
- **CL**: `claimtype ∈ {fact, inference, assumption, open-question}`, `claimconfidence ∈ {low, medium, high}`

## Tagging

Every touched record ends up tagged. Two mandatory layers:

### Structural (closed vocabulary, one axis per class)

Identifies what kind of record this is. Uses slash-namespaced tags DEVONthink renders as a hierarchy.

- **EV**: `pkim/evidence`, `evidence/status/<state>`, `evidence/capture/<type>`
- **KN**: `pkim/knowledge`, `knowledge/type/<note-type>`, `knowledge/status/<state>`, `knowledge/confidence/<level>`
- **RL**: `pkim/relation`, `relation/type/<rel>`, `relation/status/<state>`, `relation/confidence/<level>`
- **CL**: `pkim/claim`, `claim/type/<type>`, `claim/confidence/<level>`, `claim/state/<state>`

### Topical (open vocabulary, shared corpus-wide)

Identifies what the record is *about*. Every record carries at least one topical tag from these axes:

- `domain/<broad-area>` — always, e.g. `domain/digital-transformation`
- `concept/<named-thing>` — always, e.g. `concept/composable-enterprise`
- `source/<class>` — always for EVs, e.g. `source/vendor-research`
- `entity/<name>` — when a specific organisation, product, person, place is named
- `year/<YYYY>` — when the record is time-bounded
- `method/<approach>` — optional, when the source has a methodological signature

### Inheritance rules

- CLs inherit topical tags from their parent KN.
- RLs inherit topical tags as the union of their two endpoints' sets.
- KNs inherit source-class tags from their cited EVs.
- Tags do not cascade backward — an EV does not gain a KN's tags when a KN cites it.

## Edge classes

Not every mention is an edge. The graph audit distinguishes:

| Edge class | Description | Example |
|---|---|---|
| **provenance** | Source supports a note or claim. | EV → KN (via item link + optional `supports` RL) |
| **conceptual** | Peer relationship between concepts. | KN → KN (via `extends` or `references` RL) |
| **structural** | Part-of, component-of, taxonomy. | KN → KN (via `precedes` RL on a phase) |
| **contrast** | Conflict, difference, boundary. | KN ↔ KN (via `contradicts` RL) |
| **operational** | Workflow or lifecycle. | KN → KN (via `supersedes` RL) |
| **weak association** | Discovery signal; not materialised. | DT's Compare / Classify output — always requires operator elevation to become an RL |

Weak associations must not be materialised as relation notes by default. They are discovery only. If an edge doesn't clearly fit the first five classes, treat it as weak.

## Detailed contracts

- Field-by-field schema and templates: [03 Record And Note Specification](03-record-and-note-specification.md).
- Where each record lives in DEVONthink: [04 DEVONthink Operating Model](04-devonthink-operating-model.md).
- How records move through the system: [05 Workflows](05-workflows.md).
- Review-state gates and safety rules: [06 Operations And Safety](06-operations-and-safety.md).
