---
name: dt-run-restore-drill
description: Rebuild PKIM backup/restore evidence by copying a live DEVONthink database package, opening a restore-test copy, verifying a required group path, and recording deterministic evidence. Make sure to use this skill whenever backup evidence is missing, stale, or questioned, or when the user asks to prove that restore still works rather than just assuming it does.
compatibility: Works in any runtime that can resolve a live DEVONthink database package and call the shared `scripts/pkim restore-drill` command. The local CLI is the preferred deterministic path when available.
---

# dt-run-restore-drill

This skill exists because backup claims are worthless without restore proof. The only backup that matters is one you can actually open.

## What this skill is for

Use it to:

- regenerate restore-drill evidence
- verify that a live DEVONthink package can be copied and reopened safely
- provide fresh evidence for the scale-readiness gate

The result should be a reproducible evidence file and a run manifest, not a verbal assurance.

## Why this matters

PKIM is safe only if the operator can recover the canonical database packages. That means:

- package copy works
- restore-test copy opens
- expected structure is readable in the restored copy

Anything less is just storage, not recovery.

## Workflow

1. Choose the target database. Default to the scratch database unless the user asked for another one.
2. Run:
   ```bash
   scripts/pkim restore-drill --database PKIM-Pilot --format json
   ```
3. Inspect the evidence payload:
   - `source_path`
   - `backup_path`
   - `restore_test_path`
   - `timestamp_utc`
   - `verified_group_path`
   - `verified_child_count`
4. Confirm the result is `ok`.
5. If the drill is meant to unblock scale, rerun `dt-check-scale-readiness`.

## How to know you are doing it right

You are doing this skill correctly when:

- the evidence file is refreshed on disk
- the restored copy actually opened in DEVONthink
- the verified group path is explicit
- the run manifest exists

You are doing it badly when:

- you only copy files and never open the restored database
- you treat directory existence as proof
- you leave stale evidence in place after a failed run

## What not to do

- Do not claim restore works without fresh evidence.
- Do not manually edit the evidence JSON.
- Do not use this skill as a substitute for broader backup policy.

## Output

Produce deterministic evidence at:

- `tmp/restore-drill/evidence/restore-drill-summary.json`
- `runs/<run-id>/restore-drill.json`
- `runs/<run-id>/run.json`

## Preferred tool path

```bash
scripts/pkim restore-drill --database PKIM-Pilot --format json
```
