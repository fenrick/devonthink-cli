# DEVONthink Operating Model

## Purpose

This document expands the operating design for the DEVONthink side of the PKIM. The goal is to make DEVONthink do as much of the durable knowledge and evidence management work as possible, while keeping the repo and automation layer focused on extension, instrumentation, and controlled execution.

## Operating Stance

### Native first

DEVONthink should own:

- evidence storage and retrieval
- knowledge note authoring
- relation-note authoring
- item-link resolution
- aliases and WikiLinks
- native review queues via smart groups
- native triggered automation via smart rules, scripts, templates, and URL commands
- note versioning and named versions

The automation layer should extend this, not replace it.

The approved runtime path is the shared local command surface backed by JXA or AppleScript helpers. MCP may be present, but it is not the required primary path.

### Multiple focused databases

Do not create a single universal database for everything. Use several focused databases so search, classify, compare, and graph neighbourhoods stay meaningful.

Recommended baseline:

| Database | Role | Why it exists |
| --- | --- | --- |
| `PKIM-Knowledge` | Canonical knowledge graph | Keeps note context dense and graph behaviour legible |
| `PKIM-Evidence-Personal` | Personal evidence | Lets personal captures and mobile-important content stay portable |
| `PKIM-Evidence-Work` | Work evidence | Isolates policy-constrained and indexed material |
| `PKIM-Evidence-Server` | Mounted-share evidence | Separates unstable pathing and availability concerns |
| `PKIM-Pilot` | Scratch database | So new automation can fail safely |

## Canonical Path Policy

Use this as the single source of truth for imported versus indexed handling.

### Import by default for

- anything mobile-critical
- anything annotation-heavy
- anything intended for long-term retention inside DEVONthink
- captures, scans, and stable evidence objects

### Index only when

- the canonical file must remain editable outside DEVONthink
- the item belongs to a meaningful parent working folder
- the file is local and materialised, not a cloud placeholder

### Non-negotiable indexed rules

- index only parent folders, never scattered individual files
- never auto-move individually indexed files
- require `Update Indexed Items` checks after external filesystem changes

## Content Classes

### Evidence

Evidence includes:

- PDFs
- scans
- web archives
- bookmarks
- EPUBs
- office documents
- image captures
- zipped source bundles

Evidence is not the note graph. It is the raw substrate the note graph points back to.

### Knowledge

Knowledge includes:

- literature notes
- synthesis notes
- decision notes
- method notes
- project notes
- relation notes
- topic notes

Knowledge should be imported into `PKIM-Knowledge` as DEVONthink Markdown documents. That gives stable in-app behaviour for:

- WikiLinks
- names and aliases
- incoming and outgoing links
- graph view
- note versioning
- annotation backlinks

### Operational records

Operational records are records used to manage the system itself:

- queue notes
- run summaries
- export manifests
- review packets
- diagnostics

These can live in DEVONthink when they need tight in-app linkage, or in the repo when they are primarily machine-generated artifacts.

## Import vs Index Policy

The design only works if import and index behaviour are disciplined.

### Import by default when

- the item must be portable inside DEVONthink
- mobile access matters
- Apple Pencil or iPad annotation matters
- the item is a stable evidence object rather than a live collaborative working document
- the source is a capture or archive rather than a living file

### Index by exception when

- the canonical file must remain in a shared filesystem
- another app must edit the same file in place
- the folder already has real operational meaning outside DEVONthink
- policy or compliance means the item should not be imported into a private database

### Hard rules for indexed content

- index parent roots, not orphan files
- avoid individually indexed files as a normal pattern
- assume path fragility
- assume cloud sync clients can create update edge cases
- treat indexed content as higher-risk for autonomous filing

## Database Topology

### Knowledge database structure

Suggested top-level groups:

- `/Inbox`
- `/Notes/Literature`
- `/Notes/Synthesis`
- `/Notes/Relations`
- `/Notes/Topics`
- `/Notes/Projects`
- `/Templates`
- `/Operations`
- `/Archive`

Suggested rationale:

- keep note class visible without making it the full ontology
- separate relation notes so graph maintenance is explicit
- keep templates native to DEVONthink
- give operations a stable place for native dashboards, reports, and queue artifacts

### Evidence database structure

Suggested baseline:

- `/Inbox`
- `/Sources/Imported`
- `/Sources/Indexed`
- `/Captures/Web`
- `/Captures/Bookmarks`
- `/Captures/Scans`
- `/Working`
- `/Review`
- `/Archive`

The exact taxonomy can vary by library, but each evidence database should preserve:

- an inbox
- a reviewed/curated surface
- an explicit indexed boundary
- an archive boundary

## Ingest Workflow

### Entry channels

Evidence can arrive via:

- manual import into database inboxes
- indexed parent roots
- browser capture
- share sheet or mobile capture
- scanner ingest
- script or MCP-assisted import

### Capture policy by kind

| Kind | Default policy |
| --- | --- |
| web page | bookmark only, or bookmark plus snapshot if evidentiary capture is required |
| PDF | import by default; OCR if needed |
| scan | import plus OCR |
| canonical markdown note | import into `PKIM-Knowledge` only |
| spreadsheet or active office working file | usually indexed if cross-app editing matters |
| email or clipper capture | send to inbox, then review before filing |

### Ingest states

Use a minimal but explicit operational state model:

| State | Meaning |
| --- | --- |
| `inbox` | Arrived, not yet profiled |
| `profiled` | Core identity and metadata set |
| `needs-human` | Human inspection required |
| `knowledge-linked` | At least one knowledge note or relation note exists |
| `filed` | Accepted into its long-term location |
| `archived` | Retained but not active |

### Ingest rules

1. Every new item gets a `PKIM_ID` once it passes basic profiling.
2. Every imported or indexed item should have a clear `DocRole`.
3. No autonomous filing before the item is profiled.
4. Profiling happens in `/Inbox/`, and enrichment should also happen there until title, tags, note intent, and destination are clear.
5. Rename and move are acceptable once the semantic work is done because the stable reference is the DEVONthink item link, not the filename.
6. No autonomous move of indexed items without an explicit path policy check.
7. No assumption that classify or compare are authoritative.
8. Mobile expectations must be explicit at the library-policy level.

## Review Queues

The system should rely heavily on native DEVONthink smart groups for operational visibility.

### Core smart groups

| Queue | Filter idea | Purpose |
| --- | --- | --- |
| `Needs Profile` | missing `PKIM_ID` or `Review_State` | first-pass triage |
| `Needs OCR` | OCR missing where expected | evidence hygiene |
| `Needs Knowledge Note` | evidence with no linked knowledge note | pushes evidence into interpretation |
| `Needs Relation Note` | candidate linked material without explicit relationship | graph quality |
| `Needs Filing` | approved but still in inbox or holding group | curation queue |
| `Indexed Risk` | indexed items recently moved or under fragile roots | operational risk |
| `Mirror Drift` | note changed without export refresh | portability control |
| `Automation Error` | latest run failed or left inconsistent metadata | support queue |

### Canonical queue contract

| Queue | Created by | Cleared by | Agent may clear? | Governing field or signal |
| --- | --- | --- | --- | --- |
| `Needs Profile` | ingest without complete minimum identity | profiling completion | yes | `PKIM_ID`, `DocRole`, `Review_State` |
| `Needs OCR` | ingest or OCR audit detects missing OCR where required | OCR completion or human exemption | yes, if OCR succeeds | `Needs_OCR` |
| `Needs Knowledge Note` | profiled evidence lacks canonical synthesis link | canonical knowledge note creation | yes | `Knowledge_Link_State` |
| `Needs Relation Note` | graph review detects missing explicit relation | reviewed relation note creation | yes | `Relation_Gap_State` |
| `Needs Filing` | approved item remains unfixed in holding or inbox | filing completion | yes, with approval | `Review_State` |
| `Indexed Risk` | indexed item violates path policy or refresh assumptions | human review or policy resolution | no | `Indexed_Risk_State`, `Origin_Last_Path` |
| `Mirror Drift` | canonical note changed without verified mirror refresh | successful mirror export | yes | `Mirror_State`, `Mirror_Path`, `Content_SHA256` |
| `Automation Error` | failed run leaves inconsistent state | reviewed resolution | no | `Automation_Last_Run_State` |

Queue definitions should be treated as contract surfaces, not informal dashboard ideas.

### Smart group predicate format (confirmed 2026-04-18)

DEVONthink 4.1.1 uses the `md<lowercased_field_name>` prefix for custom metadata fields in smart group predicates. Underscores are preserved; uppercase is lowercased.

| PKIM field name | Predicate key |
| --- | --- |
| `PKIM_ID` | `mdpkim_id` |
use | `Review_State` | `mdreview_state` |
| `Needs_OCR` | `mdneeds_ocr` |
| `Knowledge_Link_State` | `mdknowledge_link_state` |
| `Relation_Gap_State` | `mdrelation_gap_state` |
| `Indexed_Risk_State` | `mdindexed_risk_state` |
| `Mirror_State` | `mdmirror_state` |
| `Automation_Last_Run_State` | `mdautomation_last_run_state` |
| `KnowledgeStatus` | `mdknowledgestatus` |

Predicate operators confirmed: `==` (equals), `!=` (not equals), `==""` (empty), `!=""` (not empty), `==1` (boolean true), `&&` (AND), `||` (OR).

Use this syntax in JXA search queries and capability probe field-existence checks.

### Review cadence

Do not make the queues ornamental. Assign a cadence:

- daily: `Needs Profile`, `Automation Error`
- weekly: `Needs Knowledge Note`, `Needs Filing`, `Mirror Drift`
- fortnightly or monthly: `Indexed Risk`, `Needs Relation Note`

## Knowledge Capture Workflow

### Evidence-backed note creation

The canonical path is:

1. profile evidence
2. decide whether it deserves a literature note, synthesis note, or both
3. create native markdown note in `PKIM-Knowledge`
4. embed stable reference back to the evidence record
5. add aliases and topic placement
6. export or refresh the mirror

### Canonical note hygiene

- annotations are source-adjacent working notes
- literature or knowledge notes are canonical synthesis objects
- relation notes are canonical edge objects
- final synthesis must not live in both annotations and knowledge notes

### Relation-note pattern

For non-trivial connections, create a dedicated relation note instead of relying on loose tags or prose-only backlinks.

A relation note should include:

- source item link
- target item link
- relation type
- short explanatory paragraph
- confidence or review state where relevant
- optional evidence excerpt or note about why the link matters

This turns “graph-ish” behaviour into explicit maintained records.

## Filing Policy

### Filing outcomes

Every approved item should end up in one of three places:

- a stable imported group
- a stable indexed parent root
- an archive or hold group pending later action

### Replicate vs move

Prefer replicate when:

- the target structure is still evolving
- the item is high-value
- you are testing automation
- the item is indexed and path risk is high

Prefer move when:

- the record is imported
- the destination rule is stable
- the item has passed review
- replication would create unnecessary ambiguity

Hard rule:

- indexed items are never moved autonomously by PKIM automation

Prefer group-level routing over brittle path-level choreography.

### Delete

Delete is an administrative act, not a routine automation tool.

Practical rule:

- automation should not permanently delete records in early system versions
- use DEVONthink trash and human review first

## Native Automation Design

### Use native features before custom code

DEVONthink already offers:

- smart groups
- smart rules
- triggered scripts
- templates
- URL commands
- custom metadata
- metadata overview sheets
- summarize and table-of-contents commands

Use these where they solve the problem directly. Script only the gaps.

### Native-first operational views

Smart groups, smart rules, metadata overview sheets, and native DEVONthink queues are the default dashboards and operational views. Move queue or status handling outward only when DEVONthink stops short.

### Native automation jobs worth using

- assign initial `Review_State` on import
- move reviewed notes to holding groups
- create metadata overview sheets
- run scheduled dashboard generation
- add template-backed note scaffolds

### Native automation jobs better left to the repo/service layer

- cross-runtime audit logging
- export mirror refresh
- external manifest generation
- compatibility matrix checks
- MCP capability probing
- scratch-database test harnessing

## Mobile and Sync Behaviour

### What mobile matters for

- reading evidence
- annotating PDFs
- reviewing notes
- quick capture

### What mobile should not be asked to do

- be the primary automation runtime
- operate on indexed-only records as if they were fully portable
- serve as the canonical location for operational logs or generated manifests

The design must keep the mobile subset intentionally imported where mobile utility matters.

### Apple Pencil and mobile policy

- anything that must be reliably available in DEVONthink To Go should be imported
- annotation-heavy source classes should prefer import
- mobile expectations must be explicit per evidence library

## Named Versions and Revision Discipline

Knowledge notes should use DEVONthink’s own revision model as the first layer of history.

Named versions are appropriate for:

- significant synthesis revisions
- important relation-note changes
- publishing or sharing milestones
- automation-generated note updates that change substantive content

Named versions must be created:

- before major synthesis changes
- before automated rewrites of canonical notes
- before relation-graph restructures
- before bulk export or migration actions

## Discovery vs authority

- explicit item links and reviewed relation notes are authoritative edges
- compare and classify outputs are reviewable inferred edges
- graph view, mentions, and WikiLinks are discovery aids, not proof of truth

The repo mirror is not a substitute for this. It is a second layer for text portability and external tooling.

## Operational Anti-Patterns

Avoid these:

- one giant everything database
- individually indexed files scattered across the filesystem
- using tags as a graph model
- making the export mirror canonical
- allowing autonomous filing before profiling and review
- pushing queue logic into external SaaS when DEVONthink can already handle it
- storing databases inside cloud-synced folders

## Design Outcome

If this operating model is followed:

- DEVONthink remains the coherent local second brain
- the graph stays legible
- evidence and knowledge are linked without being conflated
- automation has clear boundaries
- Claude Code and Codex CLI can extend the system without destabilising its core state

## Appendix Link

For per-library evidence handling policy, use [16 Evidence Policy By Library](16-evidence-policy-by-library.md).
