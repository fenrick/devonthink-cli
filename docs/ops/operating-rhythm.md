# Operating Rhythm

## Purpose

This page defines the regular cadence for operating PKIM as a knowledge operating system.

It answers:

- what to check before work starts
- how inbox material moves through the system
- when skills and the `pkim` binary are used
- where run evidence lands
- how to keep the knowledge graph from becoming a pile of disconnected notes

## Operating Principle

PKIM work is not "run a script and hope". The rhythm is:

1. inspect the current state
2. choose the right skill method
3. use deterministic `pkim` verbs for bounded execution
4. review the output
5. write only through approved paths (env-var gate + dry-run preview)
6. verify queues, graph state, and run artifacts

The LLM-driven skill layer performs judgement. The `pkim` binary's atomic verbs provide repeatable mechanics. DEVONthink remains the canonical record system.

## The Meta-Skill

The whole operating system is one composable LLM skill:

1. read the current state
2. decide what kind of work is actually needed
3. select the relevant bounded skill
4. use `pkim` verbs only for deterministic evidence and mutation
5. review the result against the graph, queues, and workflow contract
6. either continue to the next skill or stop with a repairable state

The smaller skills exist so the LLM can stay inside a safe method instead of solving every task from scratch. The `pkim` command surface exists so the LLM does not hand-edit DEVONthink state blindly.

The important distinction:

- **Skill layer:** why this action matters, whether it is appropriate, what risk exists, and what should happen next.
- **Command layer:** exact reads, writes, artifacts, and validation — performed by `pkim` verbs.
- **Design layer:** the contract that says whether the action is legitimate.

Progressive disclosure matters because the operator and the LLM both need the same ladder: purpose first, method second, mechanics third.

## Session Start

Run this before meaningful work:

```bash
pkim health-check
pkim probe-capabilities
```

Check:

- DEVONthink is reachable
- `PKIM-Knowledge` and target evidence databases are open
- capability probe passes
- write gate state is intentional
- `.dt` metadata cache reachable

If live writes are needed, set `PKIM_ALLOW_PRODUCTION_WRITES=true` only for the session that needs it. The default behaviour for every write verb is to write live when the env var is set; pass `--dry-run` to preview without touching DT.

## Daily Or Per-Session Loop

Use this order:

1. Review queue health.
2. Process inbox material one record at a time.
3. Create or update knowledge notes where justified.
4. Run graph maintenance after note work.
5. File records only after semantic enrichment is complete.
6. Sync mirrors when canonical notes changed.
7. Review run artifacts and commit repo changes in small chunks.

The compound operations that used to be single Python verbs (`sweep-inbox`, `graph-audit`, `metadata-overview`, etc.) retired with the CLI-first pivot (see [docs/design/22-cli-first-atomic-primitives.md](../design/22-cli-first-atomic-primitives.md) §"What moves into skills"). The orchestration now lives in skill markdown that composes the atomic verbs:

- **Inbox triage**: `dt-sweep-inbox` skill composes `pkim list /Inbox/` + `pkim get` per record + `pkim set-metadata` + `pkim move`.
- **Per-record profiling**: `dt-profile-record` composes `pkim get` + `pkim body` + `pkim aliases` + skill judgement.
- **Graph audit**: `dt-audit-graph-corpus` composes `pkim search` + `pkim body` + `pkim get` and emits a findings JSON for review.
- **Mirror export**: `dt-sync-export-mirror` composes `pkim get` + `pkim body` + (if needed) `pkim set-metadata` per indexed record.

Run a skill by reading its `SKILL.md` and following the steps; the skill calls `pkim` verbs directly.

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

## Skill And Verb Relationship

Skills are the operating method. The `pkim` binary provides the deterministic atomic verbs each skill composes. The full verb contract is in [docs/design/23-swift-pkim-binary.md](../design/23-swift-pkim-binary.md).

| Need | Skill | Composes these `pkim` verbs |
| --- | --- | --- |
| Runtime readiness | `dt-health-check` | `pkim health-check`, `pkim probe-capabilities` |
| Inbox triage | `dt-sweep-inbox` | `pkim list`, `pkim get`, `pkim set-metadata`, `pkim move` |
| Record profiling | `dt-profile-record` | `pkim get`, `pkim body`, `pkim aliases`, `pkim tags` |
| Metadata writeback | `dt-apply-approved-metadata` | `pkim set-metadata` |
| Knowledge note creation | `dt-build-knowledge-note` | `pkim mint-id`, `pkim create-note`, `pkim set-metadata`, `pkim set-body` |
| Relation note creation | `dt-build-relation-note` | `pkim mint-id`, `pkim create-note`, `pkim set-metadata` |
| Filing | `dt-safe-file` | `pkim move` (move-all-instances; never replicate) |
| Graph audit | `dt-audit-graph-corpus` | `pkim search`, `pkim body`, `pkim get` |
| Mirror refresh | `dt-sync-export-mirror` | `pkim get`, `pkim body`, `pkim mirror-of`, `pkim set-body` for indexed |
| Bootstrap canonical setup | _(one-off)_ | `pkim setup-database`, `pkim verify-database`, `pkim verify-smart-groups`, `pkim fix-smart-groups`, `pkim install-templates` |

If a skill's result is insufficient, do not invent a new one-off workflow. Improve the skill, or — only if the gap is a *missing atomic primitive* — propose a new `pkim` verb (see anti-patterns in [docs/design/23-swift-pkim-binary.md](../design/23-swift-pkim-binary.md) §"Anti-patterns" before adding compound verbs).

## Weekly Or Batch Review

Run the audit skills after a material batch of inbox processing or note creation. The skills that previously had dedicated compound verbs now compose the atomic surface:

- `dt-audit-graph-corpus` — broken relation endpoints, missing relation metadata, duplicate relations, orphan notes.
- `dt-sync-export-mirror` — mirror drift, indexed-file divergence.
- `dt-review-queue-health` (if it exists in your skills set) — stale or suspicious queue counts.

Review:

- broken relation endpoints
- missing relation metadata
- duplicate relations
- actionable orphan notes
- mirror drift
- automation errors
- stale or suspicious queue counts

If graph audit finds issues, use `dt-audit-graph-corpus` and a repair skill. Do not patch graph structure casually from raw command output.

## Mirror Rhythm

The mirror is a portability surface, not canonical state.

The `dt-sync-export-mirror` skill composes:

- `pkim mirror-of <ref>` — read the indexed-file path for one record.
- `pkim body <ref>` — read canonical body (file-as-truth for indexed, SB plainText for imported).
- `pkim set-body <ref>` — write back to the canonical disk file when divergence is the imported side.

Live writes still require `PKIM_ALLOW_PRODUCTION_WRITES=true`.

## Where Evidence Lands

| Artifact | Location |
| --- | --- |
| Run manifests | `runs/<run-id>/invocation.json`, `runs/<run-id>/mutation.json` (live) or `mutation-proposal.json` (dry-run) |
| Stdout snapshots | `runs/<run-id>/stdout.json` |
| Execution logs | `logs/` |
| Mirror output | `exports/knowledge-mirror/` |
| Permanent operating docs | `docs/ops/` |
| Permanent design contracts | `docs/design/` |

Run artifacts are local evidence. They are not usually committed.

## Working-Process Rule

If a workflow is used successfully during corpus work, it must be documented as a working process (a skill, an inline `docs/ops/` runbook, or both) before it is repeated at scale.

Design intent is not enough. Each repeated workflow must state:

- when to use it
- inputs
- which `pkim` verbs or skills are invoked
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

- a live write returns `ok: false` (envelope-level failure) or the verify-read in `mutation.json` doesn't match the proposed change
- a relation note cannot resolve source or target
- graph audit finds broken endpoints
- `dt-safe-file` proposes a generic destination
- an indexed record is about to be moved
- a queue suddenly changes in a way the current run cannot explain
- a skill and a `pkim` verb disagree about what should happen next

Use `dt-recover-failed-write` for failed or partial live writes.
