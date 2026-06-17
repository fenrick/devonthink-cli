---
name: dt-execute-repair-plan
description: Take an action plan produced by dt-audit-graph-corpus, dt-inspect-graph-neighbourhood, or a staged candidate-session orchestrator, validate it, execute each repair in the correct order with checkpoints between phases, track progress so partial runs can be resumed, and produce an execution log.
compatibility: Works in any runtime that can read run artifacts, call dt-apply-approved-metadata, dt-build-relation-note, dt-reconcile-relation-edge, dt-build-knowledge-note, dt-safe-file, and dt-sync-export-mirror. Requires access to the run directory that produced the action plan.
---

# dt-execute-repair-plan

This skill exists because producing an action plan and executing it are different cognitive modes, and mixing them produces errors. `dt-audit-graph-corpus` produces a prioritised issue list but does not execute repairs. `dt-inspect-graph-neighbourhood` produces a per-node-and-edge action plan but does not apply it. Staged candidate sessions also produce interdependent action queues. Without a dedicated execution skill, the operator must mentally track which actions were done, what order they go in, what candidate resolved to which note, and what to do when one fails.

Your job is to execute the plan, not to re-derive it. If the plan is ambiguous, stop and clarify before starting.

## What this skill is for

Use it when:

- `dt-audit-graph-corpus` has produced a `corpus-audit.json` and you are ready to start repairs
- `dt-inspect-graph-neighbourhood` has produced a `neighbourhood-assessment.json` and you are ready to apply it
- A prior repair session was interrupted and you need to resume from a checkpoint
- The user says "execute the plan" or "start the repairs" after an audit or neighbourhood inspection

The result should be a completed set of repairs, a progress log, and explicit escalation for anything that could not be self-corrected.

## Why this matters

Action plans from audit, neighbourhood, and staged candidate sessions contain multiple interdependent actions. The order matters: metadata corrections must precede node canonicality checks, which must precede edge materialisation and edge reconciliation, which must precede mirror sync. Executing out of order produces a second inconsistency on top of the first.

Execution also fails. A corrective write may produce a mismatch. An endpoint may have changed between audit and repair. The plan may contain an action that is blocked by a condition the audit did not detect. Without a skill that handles partial execution and checkpoints, an interrupted repair leaves the system in an unknown intermediate state.

## Execution order

Always execute in this order, regardless of what the plan contains:

1. **Metadata corrections** — `Review_State`, `PKIM_ID`, `DocRole`, `Automation_Last_Run_State` via `dt-apply-approved-metadata`
2. **Node canonicality** — create or update knowledge notes via `dt-build-knowledge-note` or `scripts/pkim update-knowledge-note`
3. **Edge reconciliation** — create, strengthen, supersede, or retire relation notes via `dt-build-relation-note`, `scripts/pkim update-relation-note`, `dt-reconcile-relation-edge`
4. **Mirror sync** — export updated notes via `dt-sync-export-mirror`

For staged candidate sessions, keep the same checkpoint model:
- candidate resolution map updated after every note mutation
- edge materialisation queue updated after every relation mutation
- no separate batch-execution model

Within each phase, process in severity order (high before medium before low), then by the number of issues touching the same record (most-affected records first).

## Workflow

Follow this sequence.

1. Read the source action plan: `runs/<source-run-id>/corpus-audit.json` or `runs/<source-run-id>/neighbourhood-assessment.json`.
2. Read any existing `runs/<source-run-id>/execution-log.json` — if one exists, this is a resume. Identify which actions are already marked `done` or `skipped` and skip them.
3. Validate the plan before starting:
   - Confirm each affected record reference still resolves in DEVONthink.
   - Flag any action whose preconditions are not met (e.g. a `create-relation-note` action where one endpoint has been archived since the audit). Mark as `blocked` — do not execute, escalate.
4. Report the validated action count and any pre-execution blocks to the user. Pause for confirmation before proceeding if any blocks were found.
5. Execute Phase 1 (metadata). For each action:
   a. Dry-run via `dt-apply-approved-metadata`.
   b. Confirm dry-run output matches the intended state.
   c. Apply live.
   d. Verify after-state.
   e. Log the result in `execution-log.json` as `done` or `failed`.
6. Report Phase 1 completion before starting Phase 2.
7. Execute Phase 2 (node canonicality). For each action:
   a. If the action is `create`: run `dt-build-knowledge-note` (which gates through `dt-resolve-canonical-note`).
   b. If the action is `update`: dry-run via `scripts/pkim update-knowledge-note`, confirm, apply live.
   c. Log the result.
8. Report Phase 2 completion.
9. Execute Phase 3 (edges). For each action:
   a. `strengthen`: dry-run via `scripts/pkim update-relation-note`, confirm, apply live.
   b. `create`: dry-run via `scripts/pkim create-relation-note`, confirm, apply live.
   c. `retire`: set `RelationStatus=retired` via `scripts/pkim update-relation-note --relation-status retired`, then set `Automation_Last_Run_State` via `dt-apply-approved-metadata`.
   d. `supersede`: create the new relation note, then retire the old one.
   e. Log each result.
10. Report Phase 3 completion.
11. Execute Phase 4 (mirror sync) via `scripts/pkim sync-mirror --scope changed --live`.
12. Produce the final execution summary.

## How to handle failures mid-execution

When an action fails:

- Log it as `failed` with the error in `execution-log.json`.
- Do not stop the entire session unless the failure blocks subsequent actions in the same phase.
- If the failure is a Type 1 or Type 3 (pre-write or post-write verification) failure per the taxonomy in `dt-recover-failed-write`: log and continue.
- If the failure is a Type 2 (mid-write): stop that action, log as `failed`, and continue to the next action. Do not re-attempt in this session without reading the current record state.
- After all phases complete, report any `failed` actions and route each to `dt-recover-failed-write`.

Do not silently skip a failed action. Every action must appear in the execution log as `done`, `failed`, `skipped`, or `blocked`.

## How to resume

If the session is interrupted:

1. Read the existing `execution-log.json` to find which actions were `done`.
2. Validate that `done` actions still hold (the record is in the expected state). If a `done` action has regressed, add it back to the pending queue.
3. Resume from the first action not marked `done` in each phase, maintaining phase order.

## How to think about plan fidelity

Execute the plan as given. Do not re-derive priorities during execution. If you observe something unexpected during execution (a record in an unexpected state, a newly-visible problem), log it in `execution-log.json` under `incidental_observations` and address it in a new audit pass after this session is complete. Do not expand the plan mid-execution.

The exception: if an unexpected observation blocks a planned action (for example, an endpoint has changed state and the planned edge repair is now invalid), mark the action as `blocked`, log the observation, and continue.

## How to know you are doing it right

You are doing this skill correctly when:

- every action is logged — nothing is silently skipped
- you execute in phase order and report between phases
- dry-run precedes every live write
- you resume from the checkpoint rather than re-executing completed actions
- `incidental_observations` accumulate in the log rather than expanding the live plan

You are doing it badly when:

- you execute actions out of phase order (e.g. edges before metadata)
- you skip the dry-run step to save time
- you expand the plan during execution to cover newly-observed problems
- you re-execute `done` actions on resume without verifying they have regressed

## What not to do

- Do not re-run `dt-audit-graph-corpus` during repair. The audit phase is complete.
- Do not modify the source action plan document. It is the record of intent; the execution log is the record of what happened.
- Do not execute repairs without a dry-run first, even when confident.
- Do not mark an action as `done` until the after-state is verified.
- Do not execute Phase 2 before Phase 1 is fully logged (even if partial).

## Output

Produce `runs/<source-run-id>/execution-log.json`:

```json
{
  "execution_run_id": "RUN-2026-04-21T10-00-00Z",
  "source_plan_run_id": "RUN-2026-04-17T16-20-00Z",
  "source_plan_type": "corpus-audit",
  "phases_completed": ["phase-1", "phase-2", "phase-3"],
  "phases_skipped": [],
  "summary": {
    "done": 14,
    "failed": 1,
    "blocked": 0,
    "skipped": 2
  },
  "incidental_observations": [],
  "actions": [
    {
      "action_id": "phase-1-001",
      "phase": "metadata",
      "record_pkim_id": "EV-20260417-0007",
      "action": "set Review_State=profiled",
      "status": "done",
      "dry_run_result": "ok",
      "live_result": "ok",
      "run_ref": "RUN-2026-04-21T10-01-00Z"
    },
    {
      "action_id": "phase-3-004",
      "phase": "edges",
      "record_pkim_id": "RL-20260412-0001",
      "action": "retire zombie edge (target archived)",
      "status": "done",
      "dry_run_result": "ok",
      "live_result": "ok",
      "run_ref": "RUN-2026-04-21T10-15-00Z"
    },
    {
      "action_id": "phase-3-007",
      "phase": "edges",
      "record_pkim_id": "RL-20260416-0009",
      "action": "retire duplicate triplet",
      "status": "failed",
      "error": "Record not found — may have been removed since audit",
      "escalation": "dt-recover-failed-write"
    }
  ],
  "result": "partial"
}
```

Valid `result` values: `complete` (all actions done), `partial` (some failed or blocked), `aborted` (stopped before all phases due to critical failure).

## Preferred tool path

Dry-run an individual metadata action:

```bash
scripts/pkim apply-metadata \
  --record "<ref>" \
  --file runs/<run-id>/intent-<action-id>.json \
  --format json
```

Apply live:

```bash
scripts/pkim apply-metadata \
  --record "<ref>" \
  --file runs/<run-id>/intent-<action-id>.json \
  --live \
  --format json
```

Strengthen a relation note (dry-run first):

```bash
scripts/pkim update-relation-note \
  --note "<ref>" \
  --rationale "<new rationale>" \
  --format json
```

Retire a relation note:

```bash
scripts/pkim update-relation-note \
  --note "<ref>" \
  --relation-status retired \
  --live \
  --format json
```

Mirror sync after repairs:

```bash
scripts/pkim sync-mirror --scope changed --live --format json
```
