# PKIM Skills

## Cross-cutting rule: RL records are part of every end-to-end walk

A Workflow-3 walk that produces a KN + N CLs but zero RLs is **incomplete**. Cross-citations in CL reasoning prose must be expressed as first-class `RL-…` records — the mirror graph, contradiction detection, and supersession propagation all run over RLs, not over prose hints. See [_shared/tagging-discipline.md](_shared/tagging-discipline.md) for RL-class tag axes. Skills that drive the walk include this rule explicitly: `dt-profile-record`, `dt-build-knowledge-note`, `dt-build-claim-ledger`, `dt-inspect-graph-neighbourhood`.

## Cross-cutting rule: indexed-database creates must hit the filesystem

For PKIM-Knowledge (and any other database with a configured indexed root via `PKIM_KNOWLEDGE_INDEXED_ROOT`), record creation must go through `DTWriter.create_indexed_markdown_record` — DT's native `createRecordWith_in_` verb creates *imported* records inside the database bundle, silently defeating indexed-mode. The wrappers in `create_claim`, `create_note`, and `migrate_claims_to_nodes` route correctly; any new command that creates records must follow the same pattern.

## Cross-cutting rule: every record must be tagged

Every PKIM record (EV, KN, CL, RL) **must** end up with a complete slash-namespaced tag set applied via `DTWriter.set_tags` before any skill that touched it returns success. This is non-negotiable. See [_shared/tagging-discipline.md](_shared/tagging-discipline.md) for the per-class axes table, inheritance rules, and structural / topical layer split. The skills that mint or transition records explicitly reference this rule:
`dt-apply-approved-metadata`, `dt-profile-record`, `dt-safe-file`, `dt-build-knowledge-note`, `dt-build-relation-note`, `dt-build-claim-ledger`, `dt-sweep-inbox`, `dt-resolve-canonical-note`.

## Purpose

Skills define the operating methods for the PKIM knowledge operating system.

A skill is not just a prompt. It is a bounded runbook for agent behaviour: when to use it, what to inspect, which command surface to call, what outputs to produce, and what not to do.

Taken together, the project skills form one larger operating skill:

> maintain a DEVONthink-centred knowledge corpus by turning incoming material into profiled evidence, linked knowledge notes, explicit relations, deliberate filing, and auditable run evidence.

Each individual skill is a safe slice of that larger skill.

## Skill Shape

Every skill should disclose information in this order:

1. **Why** — the failure mode it prevents or the value it creates.
2. **When** — the trigger conditions.
3. **What** — the state it owns or changes.
4. **How** — the workflow and command surface.
5. **Evidence** — the artifact, note, metadata, or queue state proving the work happened.
6. **Stop rules** — what not to do and when to escalate.

If a skill lacks the why, it becomes a command wrapper. That is not enough for this system.

## Boundary

| Thing | Role |
| --- | --- |
| Skill | Method, judgement, sequencing, safety rules |
| Script or `pkim` command | Deterministic execution and artifact generation |
| DEVONthink | Canonical record and note state |
| Run artifact | Evidence of what happened |

The LLM uses the skill to decide what should happen. The command surface makes the bounded action repeatable.

## Workflow Groups

### Readiness And Health

- `dt-health-check`
- `dt-check-scale-readiness`
- `dt-run-restore-drill`
- `dt-review-queue-health`
- `dt-review-metadata-overview`

### Intake And Metadata

- `dt-sweep-inbox`
- `dt-profile-record`
- `dt-apply-approved-metadata`
- `dt-safe-file`
- `dt-ensure-group-path`
- `dt-recover-failed-write`

### Knowledge And Graph

- `dt-resolve-canonical-note`
- `dt-build-knowledge-note`
- `dt-build-relation-note`
- `dt-identify-knowledge-gaps`
- `dt-inspect-graph-neighbourhood`
- `dt-reconcile-relation-edge`
- `dt-audit-graph-corpus`
- `dt-execute-repair-plan`

### Portability

- `dt-sync-export-mirror`

## Operating Order

Typical session order:

1. `dt-health-check`
2. `dt-review-queue-health`
3. `dt-sweep-inbox`
4. `dt-profile-record`
5. `dt-apply-approved-metadata`
6. `dt-build-knowledge-note` and `dt-build-relation-note`
7. `dt-audit-graph-corpus`
8. `dt-safe-file`
9. `dt-sync-export-mirror`

Detailed cadence: [../docs/ops/operating-rhythm.md](../docs/ops/operating-rhythm.md).

## Rules

- Do not bypass a skill just because a command exists.
- Do not treat script output as sufficient judgement.
- Do not live-write without the write gate and the relevant safety checks.
- Do not move records before profiling, enrichment, note work, and graph wiring are complete.
- Do not create relation notes without a defensible rationale.
