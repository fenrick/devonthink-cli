# Workflows

## Purpose

This document defines only the operational workflows of the PKIM.

It answers one question:

What are the repeatable human-plus-automation flows that move records through the system?

It does not define:

- capability readiness checkpoints
- implementation sequencing
- the automation architecture
- the detailed metadata or note specification

Those live elsewhere.

## Workflow Set

The PKIM has five core workflows:

1. ingest and profile
2. enrich reviewed evidence
3. evidence to knowledge
4. relation maintenance
5. mirror refresh

Each workflow should be executable by an operator using the same local command surface whether the caller is Claude Code or Codex CLI.

## Workflow Map

Use this table before reading the detailed workflow sections.

| If the task is... | Read | Then use |
| --- | --- | --- |
| New or unprocessed material | Workflow 1 and Workflow 2 | `dt-sweep-inbox`, `dt-profile-record`, `dt-apply-approved-metadata` |
| Turning evidence into notes | Workflow 3 | `dt-resolve-canonical-note`, `dt-build-knowledge-note` |
| Wiring notes together | Workflow 4 and Workflow 5 | `dt-build-relation-note`, `dt-reconcile-relation-edge`, `dt-audit-graph-corpus` |
| Exporting portable notes | Workflow 6 | `dt-sync-export-mirror` |
| Deciding if records can move | Workflow 2 plus intake runbook | `dt-safe-file` |

The detailed sections below are reference material. Load only the workflow matching the current state transition.

## Workflow 1: Ingest And Profile

### Purpose

Turn a new evidence object into a known record with identity, baseline metadata, and a review packet while it still remains in `/Inbox/`.

### Trigger

- new imported evidence
- newly indexed parent-root content
- captured bookmark or web archive
- manually selected existing record that has never been profiled

### Inputs

- target evidence record
- target database
- runtime and environment context

### Steps

1. confirm runtime health
2. read record properties and content
3. assign or confirm `PKIM_ID`
4. produce a read-only record-context packet
5. use the profiling skill to propose tags, possible filing locations, likely related items, and candidate knowledge-note directions
6. set review outcome outside the profile command itself

### Outputs

- read-only record-context packet
- skill-derived suggested tags, with `source.*` as the default provenance layer when origin is clear
- skill-derived possible filing locations
- skill-derived related items
- skill-derived candidate knowledge-note directions
- risk notes

### Exit condition

The record is known enough to enter an enrichment pass. Profiling alone does not imply final filing.

## Workflow 2: Enrich Reviewed Evidence

### Purpose

Develop a profiled evidence record into a useful curated object before it leaves the inbox review surface.

### Trigger

- a profiled evidence record is low-risk enough to continue
- the operator wants a single-pass review outcome rather than a bare metadata update

### Inputs

- profiled evidence record
- profile packet
- operator judgement about usefulness, risk, and destination

### Steps

1. review the profile output while the record is still in `/Inbox/`
2. decide whether the record is worth deeper capture, should remain profiled, or needs human review
3. derive a better human title when the ingest title is weak
4. derive tags, aliases, and a real browseable destination path
5. decide whether low-risk note creation should happen now
6. if yes, create or update the relevant knowledge note(s)
7. attach stable DEVONthink item links between evidence and notes
8. write approved metadata and retrieval aids
9. rename and move the evidence record only after the semantic work is in place

### Outputs

- reviewed title
- tags and aliases
- approved destination path
- optional knowledge note(s)
- evidence-to-knowledge links
- curated evidence record ready for browsing and graph use

### Exit condition

The record is either:

- still in `/Inbox/` with a clear review state and next action, or
- renamed, linked, and moved to a deliberate long-term location

## Workflow 3: Evidence To Knowledge

### Purpose

Create or update a native knowledge note from approved evidence.

### Trigger

- a profiled evidence record is worth interpreting
- a topic or project note needs new source-backed content

### Inputs

- approved evidence record or topic context
- desired note type
- title or scope hint

### Candidate triage checkpoint

Before any candidate creates or updates a note, review the concept set for graph bloat risk.

Only candidates with all of the following proceed automatically:

- `candidate_class = canonical-note-candidate`
- `note_worthiness = high`
- `distinctness = distinct`
- `graph_value = node`

Candidates with `medium`, `overlapping`, `embedded`, `edge-support`, `local-detail`, `supporting-detail`, or `evidence-for-other-note` classification remain recorded in the candidate ledger but are deferred unless explicitly elevated by the operator. Deferred candidates are not silently dropped — they must appear in the ledger with a triage outcome of `deferred`.

This checkpoint applies at the handoff between `dt-profile-record` and `dt-resolve-canonical-note`.

### Steps

1. confirm source evidence is profiled
2. apply the candidate triage checkpoint — confirm which candidates pass before proceeding
3. select note type for each passing candidate
4. **Pass 3 — Triangulate.** Run [`dt-build-claim-ledger`](../../skills/dt-build-claim-ledger/SKILL.md) over the accepted candidate's EV shortlist. The output is the run-artefact at `runs/<run-id>/claim-ledger.md` per the contract in [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md). The operator (human or LLM) reviews the ledger before continuing.
5. create or update native note per candidate, in dependency order, writing the accepted claim entries verbatim into the KN's `## Claims` section
6. attach stable links back to evidence
7. refresh aliases and note metadata
8. queue or execute mirror refresh

### Outputs

- native knowledge note with a populated `## Claims` section
- stable item link
- claim ledger run-artefact at `runs/<run-id>/claim-ledger.md`
- optional mirror refresh artifact

### Exit condition

The knowledge note exists natively in DEVONthink, is linked back to source evidence, and carries at least one structured claim block when `KnowledgeStatus ∈ {reviewed, published}`.

## Workflow 4: Relation Maintenance

### Purpose

Create or revise explicit relation notes between records.

### Trigger

- a meaningful relationship is identified
- an existing implicit relationship needs to become explicit
- graph maintenance review shows missing or weak connections

### Inputs

- source record
- target record
- relation type
- rationale

### Steps

1. confirm both records exist and are the intended pair
2. create or update relation note
3. add source and target item links
4. add rationale and relation metadata
5. refresh mirror if relation notes are mirrored

### Outputs

- relation note
- stable link to the relation note

### Exit condition

The relationship is expressed as a maintained record rather than an implied guess.

## Workflow 5: Post-Note Graph Pass

### Purpose

Run a bounded graph-maintenance pass after note creation so the system produces connected knowledge, not just isolated literature notes.

### Trigger

- one or more knowledge notes were just created or materially revised
- a pilot batch needs neighbourhood cleanup
- relation density or synthesis coverage is visibly lagging behind note creation

### Inputs

- `PKIM-Knowledge` note set
- existing relation notes
- linked evidence tags, folders, and summaries

### Steps

1. inspect approved literature and synthesis notes in a bounded 1-hop way
2. identify missing literature-to-existing-synthesis links only where the synthesis already scopes those notes or the thematic overlap is explicit
3. identify high-confidence shared-tag literature clusters that warrant a synthesis note
4. materialise only the defensible synthesis notes and relation notes
5. leave weaker thematic candidates as proposals rather than fake graph structure

### Outputs

- graph-pass assessment
- optional newly created synthesis notes
- optional newly created relation notes

### Exit condition

The graph has been checked for obvious missing synthesis or relation structure and any safe, bounded fixes have been applied.

## Workflow 6: Mirror Refresh

### Purpose

Export native notes into the portable filesystem mirror.

### Trigger

- note creation or update
- scheduled refresh
- explicit operator request
- drift detection

### Inputs

- scope or changed-set
- target export root

### Steps

1. identify notes to export
2. render mirror files
3. emit export manifest
4. validate parseability and path placement
5. report drift or failures

### Outputs

- updated mirror files
- export manifest
- drift or error report

### Exit condition

The mirror is a current portable projection of canonical native notes for the requested scope.

## Workflow 7: Periodic Claim Audit

### Purpose

Stress-test published synthesis at a regular cadence to surface zombie claims, missing evidence, weak confidence, and corpus-level contradictions before they accumulate.

### Trigger

- monthly cron / operator-driven invocation
- after a large EV supersession event (triggered indirectly by WP3.1's propagation)
- on demand before a publish wave

### Inputs

- the corpus snapshot at the moment the audit runs
- scope: by default, all KNs with `KnowledgeStatus ∈ {reviewed, published}`; can be narrowed by topic or by author

### Steps

1. run `pkim audit-discipline --database PKIM-Knowledge` to get the structural-discipline report (missing-claims, missing-evidence, dangling-wikilinks, etc.)
2. run the mirror-side audit ([`dt-detect-contradictions`](../../skills/dt-detect-contradictions/SKILL.md)) to populate `runs/<run-id>/contradiction-register.md`
3. for each KN in scope, run a stress-test pass over its `## Claims` block — produces per-note findings
4. aggregate into a single `runs/<run-id>/defect-register.md` keyed by `record_pkim_id`
5. classify defects by severity and propose remediation routes:
   - `missing-claims` / `missing-evidence-link` → [`dt-build-claim-ledger`](../../skills/dt-build-claim-ledger/SKILL.md) re-run over the original EV set
   - `corpus-contradiction` → human triage; possibly `needs-human` flag on the involved KNs
   - `dangling-wikilink` → [`dt-resolve-canonical-note`](../../skills/dt-resolve-canonical-note/SKILL.md)
   - `zombie-claim` (claim cites only retired EVs) → review whether the claim still holds

### Outputs

- `runs/<run-id>/defect-register.md` aggregating all findings
- `runs/<run-id>/contradiction-register.md` (the persistent log, append-only)
- queue entries on affected records pointing at the run

### Exit condition

The defect register exists, has been triaged into either `auto-route` or `needs-human` per finding, and no `KnowledgeStatus=published` record carries an open `high`-severity finding.

## Workflow Composition Rules

- Profiling happens before enrichment.
- Enrichment decides title, tags, destination, and whether note creation should happen before filing.
- Knowledge capture depends on profiled evidence or approved topic context.
- A post-note graph pass should run before calling a note batch operationally complete.
- Relation maintenance depends on stable source and target records.
- Mirror refresh follows canonical note changes, not the other way around.

## Workflow Anti-Patterns

Avoid:

- using workflow documents to define readiness checkpoints
- blending operator flow with backlog sequencing
- treating mirror export as canonical authoring
- treating `approved` as a synonym for "move it now"
- filing unprofiled or semantically undeveloped items
