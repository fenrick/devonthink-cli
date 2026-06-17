---
name: dt-apply-approved-metadata
description: Apply a bounded, approved metadata change to one DEVONthink record with dry-run validation and post-write verification. Make sure to use this skill whenever the user asks to write reviewed PKIM metadata back to DEVONthink, assign PKIM_ID after review, push approved review-state changes, or execute a reviewed metadata payload, even if they only say "write back the fields."
compatibility: Works in any runtime that can read the target record, validate a small metadata payload, and perform an approved write path. The local `scripts/pkim apply-metadata` command is the preferred deterministic tool path when available.
---

# dt-apply-approved-metadata

This skill exists because metadata writes are where careless automation becomes real damage. PKIM needs a narrow, auditable, policy-aware write path, not a vague “set some fields” habit.

Your job is to apply one reviewed metadata change safely and prove what happened.

## What this skill is for

Use it for bounded metadata mutations such as:

- assigning a missing `PKIM_ID`
- advancing `Review_State` within policy
- setting a missing `DocRole`
- marking `Automation_Last_Run_State`

The result should be a clean, reviewable mutation record.

If the reviewed metadata change is part of preparing a record for filing, hand off to `skills/dt-safe-file/SKILL.md` for the actual move or replicate. Metadata writeback is not the filing step.

## Why this matters

Metadata is control-plane state. If it drifts, queues drift, filing logic drifts, and downstream automation starts making bad decisions with false confidence.

The safety value here comes from:

- bounded scope
- explicit rejection of bad fields
- dry-run first
- post-write verification

## Workflow

Follow this sequence.

1. Resolve the target record.
2. Read current metadata before deciding anything.
3. Normalize the proposed payload to canonical field names.
4. Check each requested field:
   - is it allowed
   - is overwrite allowed
   - is the value valid
   - is the state transition allowed
5. Produce the intended mutation set.
6. Reject out-of-policy fields explicitly.
7. Run dry-run validation first.
8. Only then use the approved write path.
9. Re-read the record.
10. Verify that the after-state matches the intended mutation.
11. **When `PKIM_ID` is written:** the command automatically sets the record's DT alias to `[record_name, PKIM_ID]` as a side-effect of a successful write. Check for `alias_set` in the result payload to confirm. This is what makes `[[PKIM_ID]]` WikiLinks resolve and keeps the record identifiable by alias even if it is later renamed or refiled. Do not suppress or skip this step.
12. If the user also wants the record relocated, switch to `dt-safe-file` after the metadata mutation succeeds.

## Allowed field surface and overwrite policy

These are the only fields this skill may write. Any field not on this list is rejected.

| Field | Overwrite policy | Notes |
|---|---|---|
| `PKIM_ID` | Mint-once — blocked if the field is already set and non-empty | Format: `<prefix>-<YYYYMMDD>-<NNNN>` where prefix is EV, KN, or RL |
| `Review_State` | Allowed within the valid transition set | See state model below |
| `DocRole` | Allowed when the field is unset; human review needed to change an existing value | Valid values: evidence, knowledge, relation, annotation, project, topic, operation |
| `LastProfiledAt` | Always overwrite | ISO 8601 timestamp |
| `Automation_Last_Run_State` | Always overwrite | Value should be the run ID or `error:<reason>` |

### Review_State transition model

Valid states: `inbox`, `profiled`, `needs-human`, `approved`, `blocked`, `filed`, `mirrored`, `archived`, `error`

Allowed forward transitions for automation:

| From | To | Notes |
|---|---|---|
| `inbox` | `profiled` | After successful profile pass |
| `inbox` | `needs-human` | Cannot profile — human triage required |
| `profiled` | `approved` | Profile complete, action approved |
| `profiled` | `needs-human` | Human decision required |
| `approved` | `filed` | After successful filing |
| `approved` | `needs-human` | Human override — approval needs revisiting |
| `filed` | `mirrored` | After successful mirror export |
| `filed` | `archived` | Intentional deactivation |
| `mirrored` | `archived` | Intentional deactivation |
| `mirrored` | `profiled` | Re-processing a previously mirrored record |
| `mirrored` | `needs-human` | Human review required on a mirrored record |
| `needs-human` | `profiled` | Human cleared — re-profile |
| `needs-human` | `approved` | Human directly approves |
| `needs-human` | `blocked` | Human confirms a blocking condition |
| `blocked` | `needs-human` | Intervention clears the block |
| `archived` | `profiled` | Recovery — intentional reactivation |
| any | `error` | Automation run fails; interrupt state |
| `error` | `profiled` | After manual fix and re-profiling |

Do not advance state speculatively. Transition only when the target state's preconditions are genuinely met.

## Field classification

PKIM metadata fields fall into two distinct classes. This distinction matters for graph reconciliation, dashboards, and safe automation design. Mixing them causes automation that conflates operational state with record identity.

### Authoritative operational state fields

These fields are machine-managed. Automation reads them to make routing, queue, and eligibility decisions. Their value at any given moment represents the current operational state of the record in the automation pipeline. They change frequently and must always be read from the live record before acting on them — never from a cached profile.

| Field | Managed by | Consumed by |
|---|---|---|
| `Review_State` | Automation and human review | All queue logic, filing gates, mirror eligibility |
| `Automation_Last_Run_State` | Automation only | Error detection, re-run triggers |
| `LastProfiledAt` | Profile runs | Staleness detection, re-profile triggers |
| `LastMirroredAt` | Mirror export runs | Drift detection, export freshness |
| `LastRunID` | Any automation run | Audit trail, failure diagnosis |
| `Mirror_State` | Mirror runs | Export freshness signals |
| `Indexed_Risk_State` | Filing and probe runs | Indexed content safety checks |
| `Knowledge_Link_State` | Knowledge note linking runs | Evidence-to-knowledge coverage |
| `Relation_Gap_State` | Relation maintenance runs | Relation-note coverage signals |

### Semantic record fields

These fields are human-authored or mint-once. They describe what the record is, not what the automation pipeline has done with it. They are stable once set and must not be changed except through an explicit reviewed change with a documented rationale.

| Field | Stable after | Notes |
|---|---|---|
| `PKIM_ID` | Mint | Never reassigned. Format: `<prefix>-<YYYYMMDD>-<NNNN>` |
| `DocRole` | First confirmed profiling | Human review needed to change an existing value |
| `NoteType` | Note creation | Valid: `literature`, `synthesis`, `topic`, `project`, `decision`, `workflow` |
| `PrimaryTopic` | First profiling | Can evolve as understanding improves, but only intentionally |
| `Relation_Type` | Relation note creation | Change by superseding the relation note, not by overwriting |
| `Source_Item` | Relation note creation | Immutable once written |
| `Target_Item` | Relation note creation | Immutable once written |
| `Origin_URI` | First ingestion | Authoritative upstream source; do not overwrite casually |

A metadata writeback that modifies semantic record fields without human review is a policy violation, not just a risk. This skill's write surface intentionally excludes the immutable relation fields (`Source_Item`, `Target_Item`, `Relation_Type`) — they are not writable through the metadata path.

## How to think about metadata quality

- Smaller mutations are safer than convenience writes.
- Rejected fields are not warnings; they are policy decisions.
- Post-write verification matters because DEVONthink metadata writes are not a place for blind trust.
- Minted PKIM_IDs must follow the format exactly: `EV-20260417-0007`, `KN-20260417-0021`, `RL-20260417-0004`. The date segment is the minting date. The counter is zero-padded to four digits and scoped to the date and class prefix.

## How to know you are doing it right

You are doing this skill correctly when:

- the intended mutation is minimal and explicit
- policy rejections are plain and specific
- the after-state is verified
- a later reader can tell exactly what changed

You are doing it badly when:

- you accept arbitrary payload fields
- you skip dry-run reasoning
- you call a mismatched write “close enough”

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## What not to do

- Do not broaden the allowed field surface casually.
- Do not overwrite protected fields because it is convenient.
- Do not count a mismatched after-state as success.
- Do not use metadata writes as a disguised filing action. Use `dt-safe-file` for relocation.
- Do not pass fields as individual CLI flags (e.g. `--pkim-id`, `--doc-role`). The command takes `--file <path>` pointing to a JSON object. Passing individual flags produces exit code 2 with no useful error message.

## Output

Produce a structured mutation result with:

- record reference
- proposed payload
- intended mutation
- rejected fields with reasons
- before state
- after state if written
- mismatch details if verification fails

Canonical shape:

```json
{
  "run_id": "RUN-2026-04-17T15-16-00Z",
  "mode": "dry-run",
  "record": {
    "pkim_id": "EV-20260417-0007",
    "dt_uuid": "03CF4017-..."
  },
  "proposed_payload": {
    "Review_State": "approved"
  },
  "rejected_fields": [],
  "intended_mutation": {
    "Review_State": "approved"
  },
  "before": {
    "Review_State": "profiled"
  },
  "after": null,
  "mismatch": null,
  "result": "proposal"
}
```

For live mode, `mode` becomes `"live"`, `after` contains the re-read state, and `result` is `"ok"` on success or `"mismatch"` with details if the after-state does not match the intended mutation.

## Preferred tool path

When the local CLI is available, use:

```bash
scripts/pkim apply-metadata \
  --record "<ref>" \
  --file runs/example/approved-metadata.json \
  --format json
```

Use dry-run first. Add `--live` only when the intended mutation is clean and the write gate is intentionally enabled.
