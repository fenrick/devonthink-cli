---
name: dt-ensure-group-path
description: Create a missing DEVONthink group path under the approved PKIM taxonomy with dry-run planning, allowlist checks, and post-create verification. Make sure to use this skill whenever a proposed filing destination does not exist yet, a filing action fails because the destination group is missing, or dt-safe-file hands off to this skill to create the path before proceeding.
compatibility: Works in any runtime that can resolve a DEVONthink database, validate a proposed path against the PKIM taxonomy, and call the shared `scripts/pkim ensure-group-path` command surface.
---

# dt-ensure-group-path

This skill exists because filing destination depends on taxonomy, not just string concatenation. If a recommended subpath does not exist, the model needs a controlled way to create it without smuggling taxonomy changes through `safe-file`.

Your job is to validate one proposed group path and create it only when the structure is allowed and the user wants it.

## What this skill is for

Use it when:

- profiling recommends a sensible sub-folder under an approved taxonomy root
- filing fails because the destination group does not exist
- the user wants PKIM to create a missing filing path in DEVONthink

The result should be either a dry-run path-creation plan or a verified group creation mutation.

## Why this matters

Taxonomy creation is a structural decision, not a filing side-effect. If groups are created casually inside `dt-safe-file`, the taxonomy drifts without review. Separating path creation into its own bounded skill means:

- every new group path goes through policy validation
- dry-run always surfaces what would change before anything is written
- taxonomy violations are caught explicitly, not silently allowed
- the audit trail shows who created what and when

Bad taxonomy is hard to undo. Unwanted groups accumulate, paths diverge, and downstream filing logic starts making choices based on a structure that was never intentionally designed.

## Workflow

Follow this sequence.

1. Identify the target database and the full proposed group path.
2. Validate that the path sits under an approved taxonomy root for that database type.
3. Run `scripts/pkim ensure-group-path --database <db> --path <path> --format json` (dry-run by default).
4. Read the returned blocking conditions and intended action.
5. If the path is blocked, stop and explain the blocking condition plainly.
6. If the path is allowed and the user wants it created, confirm before proceeding.
7. Run the same command with `--live`.
8. Read `runs/<run-id>/mutation.json`.
9. Verify the group exists after creation by re-reading the database tree or checking the returned after-state.
10. Hand off to `dt-safe-file` if the next action is to move or replicate a record into that path.

## How to think about path validation

### Approved taxonomy roots

The allowed taxonomy surface is determined by the database type:

- Evidence databases: paths must begin under `/Sources/Imported`, `/Sources/Indexed`, or `/Archive`
- Knowledge database: paths must begin under approved note subtrees

A path like `/Sources/Imported/PKIM/Topic` is a sensible subdivision of an existing taxonomy root. A path like `/MyCustomRoot/Stuff` is a taxonomy violation.

Proposing a new sub-folder under an existing approved root is acceptable when the subdivision is semantically useful and matches the record class being filed. Do not treat every sub-folder suggestion as a violation — but do treat every path that leaves the approved root surface as one.

### Single-step creation only

This skill creates one group path per invocation. If the path has multiple missing segments (for example `/Sources/Imported/PKIM/Topic` when `/Sources/Imported/PKIM` also does not exist), the command should create all missing segments in a single operation. If it cannot, surface the deepest missing segment that would block creation and let the user decide whether to create in stages.

### Database scope

Always confirm which database the group belongs in. Evidence groups live in evidence databases. Knowledge groups live in `PKIM-Knowledge`. Mixing them produces broken filing logic.

## How to know you are doing it right

You are doing this skill correctly when:

- dry-run runs first and surfaces the full intended path
- paths outside the approved allowlist are rejected explicitly
- live creation only happens after the dry-run plan is clean and the user has confirmed
- the after-state is verified, not assumed
- the handoff to `dt-safe-file` is clear and immediate when the next step is filing

You are doing it badly when:

- you create the group path as a side-effect inside another skill
- you skip dry-run because the path looks obviously right
- you assume creation succeeded without verifying the after-state
- you create paths that are outside the approved taxonomy surface

## What not to do

- Do not create paths outside the approved allowlist.
- Do not bypass the dry-run step because the path looks simple.
- Do not hide taxonomy decisions inside `dt-safe-file`. This skill owns that work.
- Do not treat a post-create mismatch as success.
- Do not mutate DEVONthink if the production write gate is off.
- Do not silently absorb blocked conditions — surface them to the user with the blocking reason.
- Do not create groups in the wrong database.

## Output

Produce a path-creation result with:

- target database
- proposed path
- allowed or blocked status
- blocking reason if blocked
- intended action (segments to create)
- after-state confirming group existence

Canonical shape for a dry-run result:

```json
{
  "run_id": "RUN-2026-04-17T15-14-00Z",
  "mode": "dry-run",
  "database": "PKIM-Evidence-Work",
  "proposed_path": "/Sources/Imported/PKIM/Topic",
  "result": "proposal",
  "blocking": null,
  "segments_to_create": ["/Sources/Imported/PKIM/Topic"],
  "rationale": "Parent path /Sources/Imported/PKIM exists. One new group required."
}
```

Canonical shape for a live result:

```json
{
  "run_id": "RUN-2026-04-17T15-14-00Z",
  "mode": "live",
  "database": "PKIM-Evidence-Work",
  "proposed_path": "/Sources/Imported/PKIM/Topic",
  "result": "ok",
  "segments_created": ["/Sources/Imported/PKIM/Topic"],
  "after": {
    "group_exists": true,
    "path": "/Sources/Imported/PKIM/Topic"
  }
}
```

## Preferred tool path

Dry-run:

```bash
scripts/pkim ensure-group-path \
  --database "PKIM-Evidence-Work" \
  --path "/Sources/Imported/PKIM/Topic" \
  --format json
```

Live:

```bash
scripts/pkim ensure-group-path \
  --database "PKIM-Evidence-Work" \
  --path "/Sources/Imported/PKIM/Topic" \
  --live \
  --format json
```

Use live mode only after the dry-run proposal is clean and the user has confirmed the path should be created.
