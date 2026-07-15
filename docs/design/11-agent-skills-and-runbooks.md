# Agent Skills And Runbooks

> **Superseded 2026-07-15 by [24 DT MCP Adoption](24-dt-mcp-adoption.md).**
>
> The 20+ skills this brief mapped retired with the pkim-verb layer. The new skill set is three: `pkim-orient-and-setup`, `dt-intake`, `dt-audit`. See [`skills/README.md`](../../skills/README.md) for the current index. The *principle* recorded here (skills own judgement; the mechanism layer owns bounded mechanics) is preserved — the mechanism layer is now DEVONthink's in-app MCP server, not a PKIM-owned CLI.
>
> The rest of this doc is retained for reasoning history — it explains why the skill-command split exists at all. That reasoning applies unchanged to the new skill set.

## Purpose

This document is the design-level map for PKIM skills and runbooks.

It explains why skills exist, how they combine with scripts, which skill to load for each operating need, and where the canonical per-skill instructions live.

It does not repeat every skill body. The canonical instructions for an executable skill live in that skill's `SKILL.md` file under `skills/`.

## Why This Exists

PKIM is not "scripts plus vibes". It is an LLM-operated knowledge system with deterministic support tools.

The LLM uses skills to decide what work is appropriate, what risk exists, what evidence matters, and what should happen next. Scripts and `pkim` commands perform bounded mechanics: read, write, validate, export, log, and report.

This split matters because a command can say what it found, but it cannot decide whether the knowledge graph is semantically healthy. The skill layer performs that judgement and then uses the command layer so the mechanics are repeatable.

## Progressive Use

Use this document as an index.

1. Identify the current operating need.
2. Load the relevant skill's `SKILL.md`.
3. Load the workflow or schema document only if the skill references a contract you need to verify.
4. Load command source code only if you are changing implementation or debugging a command failure.

Do not load every skill for a routine task. That defeats the purpose of the skill system.

## Boundary

| Surface | Owns | Does not own |
| --- | --- | --- |
| `skills/*/SKILL.md` | agent method, judgement, sequencing, stop rules, output shape | command implementation |
| `scripts/` and `src/pkim/` | deterministic command behaviour, artifacts, validation, write mechanics | semantic judgement |
| `docs/design/` | stable contracts, state model, safety model, authority model | per-session procedure |
| `docs/ops/` | operating cadence and runbooks | low-level command internals |
| DEVONthink | canonical records, notes, metadata, queues, item links | repo build history |

## Skill Contract

Every project skill should disclose:

- what the skill is for
- why it matters
- when to use it
- required inputs or preconditions
- workflow
- how to know it is being done right
- what not to do
- output contract
- preferred command surface, if one exists

A skill that only wraps a command is unfinished. A skill must carry the judgement that the command cannot.

## Command Surface Contract

Every command that supports a skill should disclose:

- purpose
- required inputs
- deterministic outputs
- artifacts written
- safety constraints
- failure modes with actionable messages

If a command starts making broad semantic decisions, the boundary has been broken. Return evidence and bounded classifications; let the skill perform the judgement.

## Skill Loading Map

| Current need | Load | Usually calls |
| --- | --- | --- |
| Check runtime readiness | [`dt-health-check`](../../skills/dt-health-check/SKILL.md) | `pkim health-check`, `pkim probe-capabilities` |
| Check queue health | [`dt-review-queue-health`](../../skills/dt-review-queue-health/SKILL.md) | `pkim queue-metrics` |
| Triage inbox records | [`dt-sweep-inbox`](../../skills/dt-sweep-inbox/SKILL.md) | `pkim sweep-inbox` |
| Understand one record | [`dt-profile-record`](../../skills/dt-profile-record/SKILL.md) | `pkim profile` |
| Write reviewed metadata | [`dt-apply-approved-metadata`](../../skills/dt-apply-approved-metadata/SKILL.md) | `pkim apply-metadata` |
| Resolve a candidate note | [`dt-resolve-canonical-note`](../../skills/dt-resolve-canonical-note/SKILL.md) | `pkim search-notes`, profile output |
| Create or update knowledge | [`dt-build-knowledge-note`](../../skills/dt-build-knowledge-note/SKILL.md) | `pkim create-knowledge-note`, `pkim update-knowledge-note` |
| Create or update relations | [`dt-build-relation-note`](../../skills/dt-build-relation-note/SKILL.md), [`dt-reconcile-relation-edge`](../../skills/dt-reconcile-relation-edge/SKILL.md) | `pkim create-relation-note`, `pkim update-relation-note` |
| Inspect graph neighbourhood | [`dt-inspect-graph-neighbourhood`](../../skills/dt-inspect-graph-neighbourhood/SKILL.md) | `pkim graph-pass`, `pkim search-notes` |
| Audit graph corpus | [`dt-audit-graph-corpus`](../../skills/dt-audit-graph-corpus/SKILL.md) | `pkim graph-audit`, search commands |
| Execute graph or metadata repairs | [`dt-execute-repair-plan`](../../skills/dt-execute-repair-plan/SKILL.md) | approved write commands in phase order |
| Find evidence missing knowledge notes | [`dt-identify-knowledge-gaps`](../../skills/dt-identify-knowledge-gaps/SKILL.md) | `pkim search-notes`, graph checks |
| Move or rename records | [`dt-safe-file`](../../skills/dt-safe-file/SKILL.md), maybe [`dt-ensure-group-path`](../../skills/dt-ensure-group-path/SKILL.md) | `pkim safe-file`, `pkim ensure-group-path` |
| Recover failed writes | [`dt-recover-failed-write`](../../skills/dt-recover-failed-write/SKILL.md) | read current state, then minimal approved repair |
| Refresh mirrors | [`dt-sync-export-mirror`](../../skills/dt-sync-export-mirror/SKILL.md) | `pkim sync-mirror` |
| Check scale readiness | [`dt-check-scale-readiness`](../../skills/dt-check-scale-readiness/SKILL.md) | `pkim scale-readiness` |
| Run restore evidence | [`dt-run-restore-drill`](../../skills/dt-run-restore-drill/SKILL.md) | `pkim restore-drill` |
| Review metadata overview | [`dt-review-metadata-overview`](../../skills/dt-review-metadata-overview/SKILL.md) | `pkim metadata-overview` |
| Triangulate evidence into structured claims | [`dt-build-claim-ledger`](../../skills/dt-build-claim-ledger/SKILL.md) | `pkim search` for the EV set, then run-artefact at `runs/<run-id>/claim-ledger.md` |
| Stress-test a draft KN before publish | [`dt-audit-claim-evidence`](../../skills/dt-audit-claim-evidence/SKILL.md) | reads claim block from the draft KN; surfaces missing evidence, weak confidence, contradictions |
| Detect corpus-level contradictions | [`dt-detect-contradictions`](../../skills/dt-detect-contradictions/SKILL.md) | mirror SQL audit; output `runs/<run-id>/contradiction-register.md` |
| Audit discipline (metadata-edge, missing endpoints/evidence/claims, unclassified fields) | [`dt-audit-graph-corpus`](../../skills/dt-audit-graph-corpus/SKILL.md) | `pkim audit-discipline` |

## End-To-End Skill Chain

The normal knowledge operating-system chain is:

1. `dt-health-check` confirms the runtime and write-gate state.
2. `dt-review-queue-health` identifies what queue pressure exists.
3. `dt-sweep-inbox` identifies records that need profiling, OCR, or human review.
4. `dt-profile-record` turns one source record into a concept set and candidate graph.
5. `dt-apply-approved-metadata` writes reviewed identity and retrieval metadata.
6. `dt-resolve-canonical-note` decides whether each candidate concept should create, update, merge, or supersede a note.
7. `dt-build-knowledge-note` performs one bounded note mutation for one resolved candidate.
8. `dt-build-relation-note` and `dt-reconcile-relation-edge` materialise defensible graph edges.
9. `dt-inspect-graph-neighbourhood` checks local graph consequences after note work.
10. `dt-audit-graph-corpus` checks wider graph health after batches.
11. `dt-safe-file` renames and files evidence only after semantic enrichment is complete.
12. `dt-sync-export-mirror` refreshes the portable mirror after canonical note changes.

The sequence can stop after any step if the record is blocked, risky, or not worth deeper capture. Stopping is valid if the state is explicit and repairable.

## Runbooks

### Bring Up A Runtime

Use when a new agent runtime or shell needs to operate PKIM.

1. Read [../../README.md](../../README.md).
2. Read [../ops/agent-runtime-surface.md](../ops/agent-runtime-surface.md).
3. Copy `.env.example` to local `.env` if needed.
4. Run `pkim health-check --format json`.
5. Run `pkim probe-capabilities --format json`.
6. Run one read-only profile before any write operation.

Success means the runtime can read, report, and log without mutating production state.

### Enable Live Writes

Use only when the relevant skill calls for a live mutation.

1. Run the capability probe.
2. Confirm target database and record class are allowed.
3. Run the command dry-run first.
4. Set `PKIM_ALLOW_PRODUCTION_WRITES=true` only for the session that needs it.
5. Execute the smallest live mutation that satisfies the task.
6. Inspect refreshed after-state and the run artifact.

Success means the intended state and actual refreshed state match.

### Handle Automation Failure

Use when a command returns `error`, a post-write mismatch appears, or a run artifact is incomplete.

1. Load [`dt-recover-failed-write`](../../skills/dt-recover-failed-write/SKILL.md).
2. Inspect `runs/<run-id>/run.json`.
3. Re-read the target record from DEVONthink.
4. Classify the failure as before-write, during-write, after-write, or verification-only.
5. Execute only the minimal repair path, or stop with a specific diagnosis.

Success means the actual state is known and the repair path is recorded.

## Artifact Contract

Meaningful runs should leave structured evidence under `runs/<run-id>/`.

Typical files:

```text
runs/
  RUN-2026-04-17T15-12-00Z/
    run.json
    summary.md
    profile.json
    mutation.json
    graph-pass.json
    export-manifest.json
```

Not every run emits every file. The important rule is that actions affecting knowledge state should be explainable after the fact.

## Anti-Patterns

Avoid:

- loading the whole skill catalogue before every action
- treating a command result as sufficient semantic judgement
- creating relation notes without an explicit rationale
- moving evidence before profiling, enrichment, note work, and graph wiring
- mutating DEVONthink with no dry-run, write gate, or post-write verification
- duplicating command details in design docs when the command contract already owns them
- duplicating skill bodies in this design map when `skills/*/SKILL.md` owns them
