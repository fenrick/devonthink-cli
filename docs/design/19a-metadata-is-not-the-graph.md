# Metadata Is Not The Graph

## Purpose

This one-page note exists to settle a recurring temptation: storing relationships between records as DEVONthink custom metadata fields. It explains why that is fake graph, what DEVONthink actually treats as graph data, and where the line falls between legitimate metadata and a graph edge.

It supports the principle codified in [01 Principles And Decisions](01-principles-and-decisions.md) — *Graph edges live in note bodies* — and is referenced from [03 Information Model](03-information-model.md), [08 Record And Note Specification](08-record-and-note-specification.md), and [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md).

## What DEVONthink considers a relationship

DEVONthink's native graph behaviours — See Also and See Related Text, back-references, item-link traversal, AI suggestions, smart-rule navigation — read these primitives:

- **WikiLinks** `[[Name]]` and aliased WikiLinks `[[PKIM_ID|Name]]` in note bodies.
- **Native item links** `x-devonthink-item://UUID` in note bodies.
- **Replicants** — the same record present in multiple groups.
- **Tags** — loose, non-directional grouping.

Custom metadata is not in that list. A custom field set to `RelatedTo=KN-123` is a string. DT will not:

- show `KN-123` as a back-reference on the source record,
- include the edge in See Also,
- traverse the relationship in any UI,
- expose it as a graph in DT's AI features.

The cost of pretending otherwise is high: schema surface grows, the data looks structured but isn't queryable as a graph, and the user is misled into thinking DT understands relationships it cannot see.

## What custom metadata is for

Custom metadata is for **properties of the record itself**. A property is something true about the record regardless of any other record's existence. Examples that pass the test:

- `PKIM_ID` — the record's identity.
- `Review_State` — operational status of this record.
- `KnowledgeStatus`, `KnowledgeConfidence` — qualities of this knowledge note.
- `DocRole`, `NoteType` — the kind of thing this record is.
- `Content_SHA256` — change-detection hash for this record.
- `Origin_URI` — where this record came from. (Note: this is a property of the record's provenance, not a relationship to another PKIM record.)

A useful test: *if every other record in the corpus disappeared, would this field still be meaningful?* If yes, it's a property. If no, it's an edge in disguise.

## Allowed exceptions, narrowly drawn

### Identity pointers on relation notes

A relation note carries `Source_Item` and `Target_Item` as custom metadata. This is permitted because:

- The relation note **is** the edge. The two pointers identify which edge.
- The body of the relation note must independently carry the same two records as WikiLinks (`## Endpoints` section). The body is what DT treats as the graph; the metadata is an index.
- Removing the metadata would not remove the relationship; removing the body WikiLinks would.

### Derived dashboard counters

Fields like `Claim_Backed`, evidence counts, or other rollups computed by the export mirror are permitted because:

- They describe a property of the record (a quality derived from its own claims and the state of its cited evidence).
- They are written by automation, never authored by humans.
- They are not authoritative graph data — they are summaries, recomputable from the body content and the mirror's parsed graph.

If a value looks like an edge but is computed and not authored, it is a derived property. If it looks like a property but is authored as a pointer to another record, it is a banned edge-in-metadata.

## Banned patterns

- `RelatedTo`, `Supersedes`, `Contradicts`, `SupportedBy`, `DerivedFrom`, or any scalar metadata whose value is another record's `PKIM_ID` and whose intent is to express a relationship.
- Comma-separated `PKIM_ID` lists used as adjacency lists in metadata.
- Treating a custom metadata field as a substitute for an explicit relation note.
- "Denormalised hint" fields that smuggle graph structure into metadata for dashboard convenience without an explicit derived-property contract.

## How relationships are expressed instead

- **Inline mention or evidence citation:** WikiLink in the relevant section of the note body (`## Claims`, `## Evidence`, `## Related notes`).
- **First-class attributed edge:** a relation note (RL), with the two endpoints as WikiLinks in the body and `Source_Item` / `Target_Item` as indexing metadata.
- **Cross-corpus analysis:** parsed out of the note bodies into the export mirror's graph store (see [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) Phase 2). DT remains the human surface; the mirror is the analytical surface.

## Enforcement

- [03 Information Model](03-information-model.md) restates the rule in structural terms.
- [08 Record And Note Specification](08-record-and-note-specification.md) hard-codes it into the contract for each record class.
- `dt-audit-graph-corpus` enforces it on the corpus (see WP0.4).
- New fields must be classified at design time as PROPERTY, INDEX-POINTER, or DERIVED. Anything that does not fit is not added.

## Why this matters operationally

PKIM's value as a second brain depends on DT's graph features actually working over the relationships it stores. Every edge-in-metadata is an edge that DT cannot see, which means it cannot appear in See Also, cannot inform AI suggestions, and cannot be navigated by the human reviewing a note. Over time, an edge-in-metadata corpus produces a richly-tagged but operationally inert knowledge base — the failure mode this principle exists to prevent.
