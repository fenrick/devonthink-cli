# DEVONthink Operating Model

## Purpose

How PKIM sits inside DEVONthink: which databases exist, what shape they take, how imported vs indexed content is handled, and which native DEVONthink features carry the operational load. This document is the source of truth for anything you'd expect to see when you open DEVONthink and look around.

## Operating stance — native first

DEVONthink owns:

- Evidence storage and retrieval
- Knowledge note authoring (as native markdown records)
- Relation-note and claim-record authoring
- Item-link resolution and back-references
- Aliases and WikiLinks (within a database)
- Review queues via smart groups
- Triggered automation via smart rules, templates, URL commands
- Note versioning and named versions
- The MCP server that skills compose against (v4.3+)

The repo owns everything around that — design, skills, prompts, operational history. Skills extend DEVONthink's native behaviour; they don't replace it.

## Databases

Five canonical databases. Multiple focused databases beat one giant everything-store — search context, DEVONthink AI, and audit reliability all improve when context is dense.

| Database | Role | On-disk class |
|---|---|---|
| `PKIM-Knowledge` | Native knowledge graph — every KN, RL, CL lives here | **Indexed** against an iCloud-synced on-disk root. That root is the portability surface. |
| `PKIM-Evidence-Personal` | Personal-domain evidence | Local `.dtBase2` package (not cloud-synced) |
| `PKIM-Evidence-Work` | Work-domain evidence | Local `.dtBase2` package |
| `PKIM-Evidence-Server` | Server / infra / mounted-share evidence | Local `.dtBase2` package |
| `PKIM-Pilot` | Scratch database — where new automation fails safely | Local `.dtBase2` package |

Databases are created manually in DEVONthink. The `dt-bootstrap` skill installs the group trees, smart groups, custom metadata schema, and templates *into* an existing database — it does not create databases.

## Group trees

### PKIM-Knowledge (shape: `knowledge`)

- `/Inbox`
- `/Notes`
  - `/Notes/Literature` — literature notes (one KN per EV, close reading)
  - `/Notes/Synthesis` — synthesis notes (many EVs → one argument)
  - `/Notes/Relations` — every RL record
  - `/Notes/Topics` — topic notes (defines what a concept means)
  - `/Notes/Projects` — project notes (goal / context / status)
  - `/Notes/Claims` — every CL record; optionally sub-grouped by parent KN name
- `/Templates` — the four note templates (see [03 Record And Note Specification](03-record-and-note-specification.md) §Note templates)
- `/Operations` — dashboards, reports, queue artifacts
- `/Archive` — retired notes

### Evidence-style databases (shape: `evidence`)

Applies to `PKIM-Evidence-Personal`, `-Work`, `-Server`, `PKIM-Pilot`.

- `/Inbox`
- `/Sources`
  - `/Sources/Imported` — records whose file lives inside the `.dtBase2` package
  - `/Sources/Indexed` — records whose file lives on disk (rare; usually a working folder cross-referenced from elsewhere)
- `/Captures`
  - `/Captures/Web` — web archives
  - `/Captures/Bookmarks`
  - `/Captures/Scans` — scanned PDFs, typically OCR'd
- `/Working` — records being actively reviewed
- `/Review` — ready for approval
- `/Archive`

The tree is deliberately shallow. Depth is expressed through tags, not folders.

## Imported vs indexed

**Import by default** for everything mobile-critical, annotation-heavy, or intended for long-term retention. Imported records live inside the `.dtBase2` package; DEVONthink owns the file lifecycle.

**Index only when**:
- The canonical file must remain editable outside DEVONthink.
- The item belongs to a meaningful parent working folder.
- The file is local and materialised, not a cloud placeholder.

Non-negotiable indexed rules:
- Index only parent folders, never individually scattered files.
- Never auto-move an indexed file. Filing rules that apply to imported records don't apply to indexed ones.
- Assume path fragility on indexed content — cloud-sync clients can create update edge cases.

**PKIM-Knowledge is deliberately indexed**. Every KN, RL, CL is a `.md` file on the iCloud-synced disk root. DEVONthink owns the database index; the disk file is authoritative. External tooling reads from disk; skills write via DT MCP, which keeps the disk file coherent.

**Evidence databases are deliberately imported**. Evidence records live inside their `.dtBase2` package; the operator doesn't hand-edit them.

## Smart groups

DEVONthink smart groups are the operational dashboard. The ten canonical smart groups drive the review cadence.

| Smart group | Predicate | Databases |
|---|---|---|
| `Needs Profile` | `mdreview_state!="approved" && mdreview_state!="filed"` | all five |
| `Needs OCR` | `mdneeds_ocr==true` | four evidence DBs |
| `Needs Knowledge Note` | `mdreview_state=="approved" && mdknowledge_link_state!="linked"` | four evidence DBs |
| `Needs Relation Note` | `mdrelation_gap_state=="open"` | `PKIM-Knowledge` |
| `Needs Filing` | `mdreview_state=="approved"` | all five |
| `Indexed Risk` | `mdindexed_risk_state!=""` | four evidence DBs |
| `Mirror Drift` | `mdmirror_state=="stale"` | `PKIM-Knowledge` |
| `Automation Error` | `mdautomation_last_run_state=="error"` | all five |
| `Needs Human Review` | `mdreview_state=="needs-human"` | all five |
| `Ready for Mirror` | `mdreview_state=="approved" && mdknowledgestatus=="active"` | `PKIM-Knowledge` |

### Text predicates, not the GUI

DEVONthink's GUI smart-group picker emits **binary** NSPredicates that query the internal field index. MCP writes go to the raw customMetaData dict; only **text predicates** query that. All canonical smart groups use text predicates for that reason. The `dt-bootstrap` skill enforces this — a smart group with the right name but a stale binary predicate gets replaced.

Predicate syntax:
- Custom-metadata field prefix: `md<lowercased_field_name>`.
- Operators: `==`, `!=`, `==""` (empty), `!=""` (non-empty), `==1` (boolean true), `&&`, `||`.
- Values quoted with `"..."`.

### Review cadence

Not every queue needs daily attention.

| Cadence | Queues |
|---|---|
| Daily | `Needs Profile`, `Automation Error` |
| Weekly | `Needs Knowledge Note`, `Needs Filing`, `Mirror Drift`, `Needs Human Review` |
| Fortnightly / monthly | `Indexed Risk`, `Needs Relation Note`, `Ready for Mirror` |

Queues that stay non-empty across their cadence are a signal — either the discipline slipped or the queue's predicate is wrong.

## Note templates

Four canonical templates under `PKIM-Knowledge/Templates/`:

- `Knowledge Note` — the KN skeleton (MMD headers + `## Summary` / `## Claims` / `## Evidence links` / `## Related notes`)
- `Relation Note` — the RL skeleton with the mandatory `## Endpoints` + rationale sections
- `Topic Note` — a KN sub-template for topic-anchor notes
- `Project Note` — a KN sub-template for project working notes

Full templates in [03 Record And Note Specification](03-record-and-note-specification.md) §Note templates. Bodies live in `skills/dt-bootstrap/assets/`.

## What DT treats as a relationship

DEVONthink's native graph behaviours — See Also, back-references, item-link traversal, AI suggestions — read these primitives:

- **WikiLinks** in note bodies (`[[Name]]` or `[[PKIM_ID|Name]]`).
- **Item links** in note bodies (`x-devonthink-item://<UUID>`).
- **Replicants** — the same record present in multiple groups.
- **Tags** — loose, non-directional grouping.

Custom metadata is *not* on this list. A custom field set to `RelatedTo=KN-123` is a string — DT will not show `KN-123` as a back-reference, include it in See Also, or expose it in AI features. See [02 Information Model](02-information-model.md) §Metadata classification for the enforcement discipline.

### The cross-database rule

`[[Name|Display]]` WikiLinks resolve only within one database. Any reference from `PKIM-Knowledge` to `PKIM-Evidence-*` (or between evidence databases) uses `x-devonthink-item://<UUID>` — the item link is UUID-native and resolves across databases in constant time. WikiLinks are for within-database prose; item links are for cross-database structure.

## Per-library evidence policy

Different evidence databases have different characteristics; the policy differs accordingly.

### PKIM-Evidence-Personal

- Import-first. Mobile access matters (annotation on iPad, DEVONthink To Go).
- Storage on local disk, not cloud (privacy).
- Retention: long. Personal captures accumulate; archive rather than delete.
- OCR: aggressive for scanned pages.

### PKIM-Evidence-Work

- Import-first. Confidentiality boundary — never mix with personal.
- Local storage. Consider encryption at rest via the disk image.
- Retention: policy-driven. Some material has explicit expiry.
- OCR: standard.

### PKIM-Evidence-Server

- Mixed import + index. Server-mounted material is often indexed to keep the canonical file where operations expect it.
- Higher path fragility — the mount can disappear. `Indexed Risk` smart group monitors this.
- Retention: system-driven.

### PKIM-Pilot

- Scratch. Anything can happen here.
- Local disk, no retention discipline.
- Used by every skill for write-testing (`dt-bootstrap` §Phase 2 creates + trashes scratch records here).

## Filing policy

Every approved record lands in one of three places:

- A stable imported group (`/Sources/Imported`, `/Captures/*`).
- A stable indexed parent root (`/Sources/Indexed`).
- Archive or hold group (`/Archive`).

### Move vs replicate

**Prefer move** when:
- The record is imported.
- The destination rule is stable.
- The record has passed review.

**Avoid replicate** for filing. Replicating creates a second instance in a different group — this is almost never what filing means. Replicants are for deliberate cross-visibility (a record that genuinely belongs in two places), not for filing.

### Hard rules

- **Indexed items are never moved autonomously.** Path stability outside DEVONthink is not PKIM's to guarantee.
- **Delete is administrative, not automated.** DEVONthink's Trash first, human review second. Automation trashes only after explicit operator approval.

## Native automation

DEVONthink already ships:

- Smart groups (queue dashboards).
- Smart rules (triggered automation on state changes).
- Templates (for note creation).
- URL commands (`x-devonthink://open-workspace?name=...`).
- Custom metadata (arbitrary field schema).
- Metadata overview sheets (per-database field-coverage views).
- Summarize and table-of-contents commands.

Use these where they solve the problem directly. Skills add value where DEVONthink stops short — sequencing across records, per-record judgement, orchestrating fan-out, walking finding classes.

## Named versions

Knowledge notes use DEVONthink's own revision model. Named versions are appropriate for:

- Significant synthesis revisions.
- Important relation-note changes.
- Publishing / sharing milestones.
- Automation-generated updates that change substantive content.

Create named versions **before** the change, not after. This gives a clean rollback point.

## Discovery vs authority

- **Authoritative edges**: explicit item links, reviewed relation notes.
- **Reviewable inferred edges**: DT's compare / classify suggestions, annotation backlinks.
- **Discovery signals**: graph view, mentions, unlinked WikiLink references, tag co-occurrence.

Skills that surface DT's inferred edges (e.g. `dt-intake` when profiling) always require operator elevation before materialising a discovery signal as a relation note.

## Anti-patterns

- One giant everything database.
- Individually indexed files scattered across the filesystem.
- Using tags as a graph model — tags are a discovery aid, not edges.
- Storing DEVONthink databases inside cloud-synced folders (except the `PKIM-Knowledge` indexed root which is designed for iCloud).
- Filing before profiling.
- Autonomous move of indexed content.
- Building custom UIs when a smart group would do.
