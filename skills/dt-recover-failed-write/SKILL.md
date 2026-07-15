---
name: dt-recover-failed-write
description: Inspect a failed or partial PKIM write operation, determine the actual state of the affected record, classify the failure as recoverable or unrecoverable, and either execute the corrective action or escalate to the user. Make sure to use this skill whenever a live write returned an error or mismatch, a run artifact shows a failed mutation, a record is in Review_State=error, or the user asks what happened after an automation run went wrong.
compatibility: Works in any runtime that can read run artifacts from the runs/ directory, profile the affected record in DEVONthink, and call dt-apply-approved-metadata for corrective writes. Requires access to the run directory that produced the failure.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-recover-failed-write

This skill exists because live writes fail in ways that are not symmetric. A failure before the write is safe to retry. A failure after a partial write may have left the record in an inconsistent state that a naive retry would make worse. The difference between these cases is not visible from the error message alone — it requires reading the actual record state and comparing it against the run artifact.

Your job is to determine what actually happened, classify it, and either fix it cleanly or escalate with a specific description of why it cannot be self-corrected.

## What this skill is for

Use it when:

- a live write returned `result: error` or `result: mismatch`
- a record is in `Review_State=error` with `Automation_Last_Run_State` set to an error value
- `dt-audit-graph-corpus` surfaced records in `error` state
- the user reports that a run finished unexpectedly or a record looks wrong
- you need to confirm whether a partially-executed sequence of writes left the system in a consistent state

The result should be a classification of the failure type, the actual current state of the affected record, and either a recovery action or an escalation with a specific diagnosis.

## Why this matters

Unresolved write failures produce two concrete problems:

1. **False state** — a record in `Review_State=error` is stuck. Every downstream automation that reads `Review_State` to make a routing decision sees a blocked record. If the error is not cleared, the record falls out of every queue permanently without being explicitly rejected.

2. **Uncertain consistency** — a partial write may have written some fields and not others. If a retry applies the full intended payload again, it may overwrite a field that was correctly written the first time, or create a collision with an intermediate state that was never intended to be durable.

Recovery requires knowing what succeeded before deciding what to retry.

## Failure taxonomy

Understanding the failure type is the first step. Use this taxonomy to classify before acting.

### Type 1 — Pre-write failure

The write was never attempted. The command failed during validation, preflight, or policy check. The record is in its original pre-run state.

Signals:
- `run.json` shows `actions_proposed` but `actions_applied` is empty
- `mutation.json` either does not exist or shows `before` but no `after`
- Record state matches the `before` snapshot exactly

Recovery: safe to retry the full intended write after fixing the blocking condition.

### Type 2 — Mid-write failure

The write started but did not complete. Some fields may have been written; others were not. The record is in a partial state that matches neither `before` nor `intended`.

Signals:
- `mutation.json` shows `before` and `after` but `after` does not match `intended`
- `mismatch` array in `mutation.json` lists specific fields that diverge
- `result: mismatch` in the command output

Recovery: read the current record state first. Do not retry the full payload — apply only the fields that were not written. Avoid overwriting fields that were correctly written on the first pass.

### Type 3 — Post-write verification failure

The write completed but the subsequent re-read returned a state that does not match `intended`. The record may actually be in the intended state and the verification read failed (rare but possible under timing or caching conditions), or the record may genuinely be wrong.

Signals:
- `mutation.json` shows `after` exists but `mismatch` is non-empty
- Re-reading the record now returns the intended state → the verification read was stale
- Re-reading the record now still returns the mismatched state → the write partially failed

Recovery: re-read the record as the first step. If the re-read now matches `intended`, the write succeeded and the verification was a false alarm — clear the `error` state and update `Automation_Last_Run_State`. If the re-read still mismatches, treat as Type 2.

### Type 4 — Cascading sequence failure

A sequence of writes was planned (for example: apply-metadata, then safe-file, then create-relation-note). Some writes in the sequence succeeded; later ones failed. The record may be partially advanced along the intended path.

Signals:
- Multiple run artifacts in `runs/<run-id>/` or across multiple run directories
- `run.json` shows a multi-step action set with a partial `actions_applied` list
- Record state is consistent with an intermediate step in the sequence

Recovery: determine which step in the sequence was the last to succeed. Resume from the next step — do not re-run from the beginning.

### Type 5 — Unrecoverable failure

The record is in a state that cannot be self-corrected without human intervention.

Conditions:
- the `before` state in the run artifact does not match any valid state in the `Review_State` transition model
- the record has conflicting metadata that cannot be resolved by a single write (for example, `PKIM_ID` exists but does not match the expected format)
- the failure involved a `move` action and the record cannot be found at either the original or destination location
- the write produced a new record (note creation) and the created record has incorrect identity fields that cannot be patched

Escalate with: the specific inconsistency, the `run_id`, and the affected `pkim_id` or `dt_item_link`.

## Workflow

Follow this sequence.

1. Identify the failed run. Read `runs/<run-id>/run.json` and any `mutation.json` or `filing-proposal.json` in the same directory.
2. Read the affected record's current state from DEVONthink:
   ```bash
   pkim profile --record "<affected-ref>" --format json
   ```
3. Compare the current state against:
   - `before` in the run artifact — to confirm whether the write was attempted
   - `intended` in the run artifact — to determine what succeeded and what did not
4. Classify the failure type using the taxonomy above.
5. If the failure is recoverable:
   a. Determine the minimum corrective write: only the fields that were not correctly written, or the next step in a sequence.
   b. Dry-run the corrective write via `dt-apply-approved-metadata`.
   c. Confirm the dry-run output matches the intended state.
   d. Apply the corrective write live.
   e. Re-read the record and confirm the corrected state.
   f. Set `Automation_Last_Run_State` to `recovered:<original-run-id>` on the record.
6. If the failure is unrecoverable:
   a. Set `Review_State=error` explicitly if it is not already set.
   b. Set `Automation_Last_Run_State` to `unrecoverable:<original-run-id>:<reason>`.
   c. Report the specific diagnosis to the user with enough detail to act on manually.
7. Log the recovery outcome in a `recovery.json` artifact in the original run directory.

## How to think about recovery

### Read before retrying

Never retry a write without reading the current record state first. The current state is the ground truth. Run artifacts describe intent; they do not describe what actually happened at the record level. A partial write may have succeeded on some fields — retrying the full payload without knowing which fields are already correct can produce a new inconsistency.

### Minimum corrective write

Apply only the fields that need correction. If `Review_State` was correctly written but `PKIM_ID` was not, write only `PKIM_ID`. Do not re-apply `Review_State` alongside it — that adds an unnecessary state transition and produces a confusing audit trail.

### The error state is a real state

`Review_State=error` is not a transient condition. It is a durable interrupt that prevents downstream automation from acting on the record. After recovery, explicitly clear it by advancing `Review_State` to the appropriate post-recovery state — typically back to `profiled` or to whatever state the record was in before the failed run.

Do not leave `Review_State=error` in place after a successful recovery. It will continue to block the record.

### Unrecoverable does not mean abandoned

An unrecoverable failure still requires a documented state. The record must have:
- `Review_State=error` (explicit)
- `Automation_Last_Run_State` set to an error value with the `run_id`
- A human-readable note in the `recovery.json` artifact explaining what failed and what the human needs to do

Without this, the record is invisible in every queue and unreachable for human review.

## How to know you are doing it right

You are doing this skill correctly when:

- you read the actual record state before classifying the failure
- your classification is based on the comparison between current state, `before`, and `intended` — not just the error message
- the corrective write covers only the fields that need correction
- `Automation_Last_Run_State` is updated on every processed record, whether recovered or escalated
- `Review_State=error` is cleared on records that are successfully recovered

You are doing it badly when:

- you retry the full original payload without reading the current state first
- you classify as recoverable based on the error message alone
- you leave `Review_State=error` set after a successful recovery
- you escalate without a specific diagnosis — "something went wrong" is not an escalation

## What not to do

- Do not retry a write before reading the current record state.
- Do not apply the full original payload if the failure was Type 2 or Type 3 — apply only what was not written.
- Do not clear `Review_State=error` without confirming the corrective write succeeded.
- Do not escalate without a specific diagnosis and the `run_id`.
- Do not delete or overwrite run artifacts during recovery — they are the evidence of what happened.
- Do not use this skill to bypass policy checks. If the original write was blocked by policy, the corrective action must also comply with policy.

## Output

Produce a recovery report written to `runs/<run-id>/recovery.json`:

```json
{
  "recovery_run_id": "RUN-2026-04-17T16-25-00Z",
  "original_run_id": "RUN-2026-04-17T15-18-00Z",
  "affected_record": {
    "pkim_id": "EV-20260417-0007",
    "dt_item_link": "x-devonthink-item://03CF4017-..."
  },
  "failure_type": "type-2",
  "failure_summary": "Mid-write failure. Review_State was written; PKIM_ID was not.",
  "current_state": {
    "Review_State": "profiled",
    "PKIM_ID": ""
  },
  "intended_state": {
    "Review_State": "profiled",
    "PKIM_ID": "EV-20260417-0007"
  },
  "corrective_action": "apply PKIM_ID only",
  "recovery_result": "recovered",
  "post_recovery_state": {
    "Review_State": "profiled",
    "PKIM_ID": "EV-20260417-0007",
    "Automation_Last_Run_State": "recovered:RUN-2026-04-17T15-18-00Z"
  }
}
```

Valid `recovery_result` values: `recovered`, `escalated`, `false-alarm` (Type 3 where re-read confirmed the write succeeded).

## Preferred tool path

Read the affected record's current state:

```bash
pkim profile --record "<affected-ref>" --format json
```

Apply corrective write (dry-run first):

```bash
pkim apply-metadata \
  --record "<affected-ref>" \
  --file runs/<run-id>/corrective-intent.json \
  --format json
```

Apply live after dry-run confirms:

```bash
pkim apply-metadata \
  --record "<affected-ref>" \
  --file runs/<run-id>/corrective-intent.json \
  --live \
  --format json
```
