# Operating Rhythm

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) for the mapping table.

## Purpose

This page defines the regular cadence for operating PKIM as a knowledge operating system.

It answers:

- what to check before work starts
- how inbox material moves through the system
- when skills are used
- where evidence lands
- how to keep the knowledge graph from becoming a pile of disconnected notes

## Operating Principle

PKIM work is not "call a tool and hope". The rhythm is:

1. inspect the current state
2. choose the right skill method
3. use DT MCP tools for bounded execution
4. review the output
5. write only through DT MCP (which honours DEVONthink's per-record and per-database gates)
6. verify queues, graph state, and results

The LLM-driven skill layer performs judgement. DT MCP tools provide repeatable mechanics. DEVONthink remains the canonical record system.

## The Meta-Skill

The whole operating system is one composable LLM skill:

1. read the current state
2. decide what kind of work is actually needed
3. select the relevant bounded skill
4. use DT MCP tools only for deterministic mutation and observation
5. review the result against the graph, queues, and workflow contract
6. either continue to the next skill or stop with a repairable state

The smaller skills exist so the LLM can stay inside a safe method instead of solving every task from scratch. The DT MCP surface exists so mechanics are done through a trusted, DEVONthink-signed API.

The important distinction:

- **Skill layer:** why this action matters, whether it is appropriate, what risk exists, and what should happen next.
- **DT MCP layer:** exact reads, writes, searches, extractions, validations.
- **Design layer:** the contract that says whether the action is legitimate.

## Session Start

Run these DT MCP tools before meaningful work:

```
mcp__devonthink__is_running
mcp__devonthink__get_databases
```

Check:

- DEVONthink is running (`{running: true}`)
- `PKIM-Knowledge` and target evidence databases are in the returned list
- The scratch database (`PKIM-Pilot`) is open if you plan to test writes
- Optionally: `mcp__devonthink__list_custom_metadata_fields` to confirm the schema

Writes are gated by DEVONthink's per-record `Exclude from AI` and per-database `Exclude from Chat & MCP` settings. There is no session-level env-var gate.

## Daily Or Per-Session Loop

Use this order:

1. Review queue health (via `search_records` against the canonical smart groups).
2. Process inbox material one record at a time.
3. Create or update knowledge notes where justified.
4. Run graph maintenance after note work.
5. File records only after semantic enrichment is complete.
6. Sync mirrors when canonical notes changed.
7. Review outcomes and commit repo changes in small chunks.

The compound operations that used to be single Python verbs (`sweep-inbox`, `graph-audit`, `metadata-overview`, etc.) live in skill markdown that composes DT MCP tools:

- **Inbox triage** — `dt-sweep-inbox` composes `search_records` (scoped to `/Inbox/`) + `get_record_properties` + `set_record_custom_metadata mode="merge"` + `move_record`.
- **Per-record profiling** — `dt-profile-record` composes `get_record_properties` + `get_record_text` + `get_record_tags` + skill judgement.
- **Graph audit** — `dt-audit-graph-corpus` composes `search_records` + `get_record_text` + `get_record_properties` and emits a findings JSON for review.
- **Mirror export** — `dt-sync-export-mirror` composes `get_record_properties` + `get_record_text` + `update_record_content` where writeback is needed.

Run a skill by reading its `SKILL.md` and following the steps; the skill calls DT MCP tools directly.

## Inbox Rhythm

The inbox loop is:

1. sweep
2. profile
3. apply baseline metadata
4. enrich while still in `/Inbox/`
5. create or update notes and relations where low-risk
6. apply approved enrichment metadata
7. rename and file deliberately
8. verify queues

Detailed runbook: [intake-runbook.md](intake-runbook.md).

The rule that prevents mess:

- profile in `/Inbox/`
- enrich in `/Inbox/`
- only then rename and move

## Skill And DT MCP Relationship

Skills are the operating method. DT MCP tools provide the deterministic atomic mechanics each skill composes. The full DT MCP tool surface is described by the tool schemas themselves; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the mapping from any retired `pkim <verb>` mentions to the DT MCP tool.

| Need | Skill | Composes these DT MCP tools |
| --- | --- | --- |
| Runtime readiness | `dt-health-check` | `is_running`, `get_databases`, `list_custom_metadata_fields` |
| Inbox triage | `dt-sweep-inbox` | `search_records`, `get_record_properties`, `set_record_custom_metadata`, `move_record` |
| Record profiling | `dt-profile-record` | `get_record_properties`, `get_record_text`, `get_record_tags` |
| Metadata writeback | `dt-apply-approved-metadata` | `set_record_custom_metadata` (`mode="merge"`) |
| Knowledge note creation | `dt-build-knowledge-note` | `create_record`, `set_record_custom_metadata`, `update_record_content`, `set_record_tags` |
| Relation note creation | `dt-build-relation-note` | `create_record`, `set_record_custom_metadata`, `update_record_content` |
| Filing | `dt-safe-file` | `move_record` (never `replicate_record`) |
| Graph audit | `dt-audit-graph-corpus` | `search_records`, `get_record_text`, `get_record_properties` |
| Mirror refresh | `dt-sync-export-mirror` | `get_record_properties`, `get_record_text`, `update_record_content`, `get_imported_record_path` |
| Bootstrap canonical setup | `dt-bootstrap-pkim` | `create_group_path`, `create_record type="group"/smart-group`, `search_records` for verification |

If a skill's result is insufficient, improve the skill. There is no PKIM-owned runtime to extend.

## Weekly Or Batch Review

Run the audit skills after a material batch of inbox processing or note creation:

- `dt-audit-graph-corpus` — broken relation endpoints, missing relation metadata, duplicate relations, orphan notes.
- `dt-sync-export-mirror` — mirror drift, indexed-file divergence.
- (If defined) queue-health review via `search_records` against the canonical smart groups.

If graph audit finds issues, use `dt-audit-graph-corpus` and a repair skill (`dt-execute-repair-plan`). Do not patch graph structure casually from raw tool output.

## Mirror Rhythm

The mirror is a portability surface, not canonical state.

The `dt-sync-export-mirror` skill composes:

- `get_imported_record_path` — read the disk path for an indexed record.
- `get_record_text` — read canonical body.
- `update_record_content` — write back through DT (which keeps indexed files coherent).

## Where Evidence Lands

| Artifact | Location |
| --- | --- |
| Session notes (from the operator) | wherever you keep them; the repo doesn't mandate a run manifest anymore |
| Execution logs (from the AI client) | client-specific — Claude Code transcripts, Codex output |
| Mirror output | `exports/knowledge-mirror/` (gitignored) |
| Permanent operating docs | `docs/ops/` |
| Permanent design contracts | `docs/design/` |

The old `runs/<run-id>/` per-invocation manifests came from the retired PKIM-owned runtime; DT MCP tools don't produce them. If a skill wants an audit trail, the skill writes it explicitly.

## Working-Process Rule

If a workflow is used successfully during corpus work, it must be documented as a working process (a skill, an inline `docs/ops/` runbook, or both) before it is repeated at scale.

Design intent is not enough. Each repeated workflow must state:

- when to use it
- inputs
- which DT MCP tools or skills are invoked
- expected artefacts
- review points
- stop conditions
- how results are verified

A workflow that exists only in operator memory is not ready for scale.

## Rerun Stability Check

Before the full deep pass, at least one already-processed source must be rerun to confirm the graph is stable under repeated passes.

For that rerun:

1. Rerun `dt-profile-record` on the source.
2. Compare candidate fingerprints against the previous run.
3. Confirm main candidates are stable.
4. Confirm existing notes are resolved rather than duplicated.
5. Confirm existing edges are recognised rather than duplicated.
6. Record differences in the candidate ledger.

A full deep pass must not begin until one rerun has completed without duplicate note creation or relation-note duplication.

## Candidate Ledger Rule

Every multi-concept profile run must produce or update a candidate ledger.

The ledger must record:

- source record
- candidate IDs
- candidate fingerprints
- candidate class
- triage outcome
- resolution result
- note mutation result
- edge materialisation result
- deferred candidates
- blocked edges
- operator decisions

A session that runs multi-concept profiling without a ledger has no traceability and must not proceed to writes.

## Mirror Validation Gate

Mirror validation is a gate, not a utility. Before scaling, mirror validation must confirm:

- every approved knowledge note has valid YAML frontmatter
- every mirrored note includes `PKIM_ID`, `DocRole`, `Review_State`, and source links where applicable
- relation notes export with `Source_Item`, `Target_Item`, `Relation_Type`, and rationale
- stale mirror records are explainable
- no exported file is missing required graph or provenance fields

Mirror validation failure blocks the full deep pass.

## Stop Conditions

Stop and inspect before continuing when:

- a DT MCP write returns an error or the tool's post-write read-back doesn't match the intended change
- a relation note cannot resolve source or target
- graph audit finds broken endpoints
- `dt-safe-file` proposes a generic destination
- an indexed record is about to be moved
- a queue suddenly changes in a way the current run cannot explain
- a skill and a DT MCP response disagree about what should happen next

Use `dt-recover-failed-write` for failed or partial writes.
