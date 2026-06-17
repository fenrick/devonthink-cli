# Glossary

## Purpose

This document keeps local terminology stable across the design pack.

## Terms

### evidence

Original source material, capture, archive, or referenced source object.

### knowledge note

Canonical native DEVONthink synthesis or interpretation note.

### annotation

Source-adjacent working note attached to evidence, not the canonical final synthesis object.

### literature note

A knowledge note focused on interpreting one source or a tightly bounded source set.

### relation note

Canonical edge object linking one source item to one target item with a typed relationship and rationale.

### topic note

Curated semantic anchor that defines a topic and links out to key notes and evidence.

### project note

Working note for a bounded initiative, question, or delivery context.

### mirror

Portable exported representation of canonical native notes. Never authoritative for in-app state.

### run manifest

Machine-readable record of what a run proposed or did.

### production write

Any mutation against non-scratch databases or canonical libraries.

### scratch database

Disposable DEVONthink database used to validate write behaviour safely.

### MultiMarkdown header (MMD header)

The canonical metadata header format for native DEVONthink Markdown notes in PKIM. A block of `Key: Value` lines at the top of the file, separated from the body by a single blank line. DEVONthink natively parses standard MMD keys (`Title`, `Aliases`, `Tags`, `Author`, `Keywords`, `URL`, `Date`) into its corresponding native properties. PKIM-specific keys (`PKIM_ID`, `DocRole`, `Review_State`, etc.) are carried in the MMD header for portability but are authoritative on the DEVONthink record's custom metadata, not in the file. Mirror files use YAML frontmatter instead.

### PROPERTY field

A custom metadata field that describes a quality of the record itself. Passes the test: *if every other record disappeared, would this field still be meaningful?* Authored by humans or automation. The default classification.

### INDEX-POINTER field

A custom metadata field that points to another record's identity and duplicates a WikiLink already present in this record's body. Allowed only on relation notes (`Source_Item`, `Target_Item`). Removing the WikiLink, not the pointer, removes the edge.

### DERIVED field

A custom metadata field whose value is computed by automation (typically the export mirror) from corpus state. Never authored by humans. Not authoritative graph data — recomputable from body content and the mirror's parsed graph.

### needs-human (Review_State)

The Review_State value that marks a record as awaiting an explicit human decision. Automated workflows surface `needs-human` records in queues but never advance their state. Routes that flip records here automatically include unresolved corpus-level contradictions detected by `dt-detect-contradictions`, `verdict: degraded` results from `dt-audit-claim-evidence` on `published` knowledge notes, and ambiguous classification outcomes from `pkim sweep-inbox`. See [08 Record And Note Specification](08-record-and-note-specification.md) §Review State Model.

### edge-in-metadata (banned)

A scalar custom metadata field whose value is another record's `PKIM_ID` and whose intent is to express a relationship. Banned because DEVONthink does not treat custom metadata as graph data; the relationship would be invisible to See Also, back-references, and AI suggestions. Use a body WikiLink or a relation note instead. See [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md).

