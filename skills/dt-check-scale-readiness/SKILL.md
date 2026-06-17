---
name: dt-check-scale-readiness
description: Determine whether PKIM is operationally ready to scale beyond the pilot by validating reporting health, mirror drift, automation errors, and fresh restore-drill evidence. Make sure to use this skill whenever the user asks whether the system is ready to scale, whether the pilot exit conditions still hold, or whether a larger ingest batch is safe to start.
compatibility: Works in any runtime that can read the shared run artifacts and call the local `scripts/pkim scale-readiness` command. The local CLI is the preferred deterministic path when available.
---

# dt-check-scale-readiness

This skill exists because “looks fine” is how systems get bulk-loaded into avoidable damage. Scale readiness is an operational gate, not a vibe.

## What this skill is for

Use it to answer:

- whether the PKIM stack is currently safe to scale beyond the pilot
- which gate checks are passing or failing
- whether the restore-drill evidence, queue health, and mirror state are current enough to trust

The result should be a clear go/no-go decision with named blockers.

## Why this matters

Pilot success does not guarantee scale safety. Before larger ingest or broader write volume, the system needs:

- fresh backup/restore evidence
- queue health without unresolved automation errors
- mirror state without accepted drift
- complete run manifests

If those are not true, the next failure becomes harder to recover and harder to explain.

## Workflow

1. Run the shared gate:
   ```bash
   scripts/pkim scale-readiness --format json
   ```
2. Read each check result directly.
3. If the user asked for a self-healing pass and restore evidence is stale or missing, rerun with:
   ```bash
   scripts/pkim scale-readiness --refresh-restore-drill --format json
   ```
4. Separate:
   - hard blockers
   - informational thresholds
   - operator follow-up items
5. State plainly whether scale should proceed.

## How to know you are doing it right

You are doing this skill correctly when:

- the answer is an explicit go/no-go
- each failing check is named directly
- restore-drill freshness is treated as a real gate, not a footnote
- you do not downgrade a failed check into a vague warning

You are doing it badly when:

- you summarize instead of naming blockers
- you treat stale restore evidence as “close enough”
- you ignore run-manifest completeness

## What not to do

- Do not start a scale-up batch just because the docs say Step 17 is complete.
- Do not treat a blocked result as advisory.
- Do not bypass failed restore-drill evidence.

## Output

Produce a structured readiness result with:

- overall result
- pass/fail state
- per-check details
- failed checks
- threshold values
- restore-drill refresh details if one was attempted

## Preferred tool path

```bash
scripts/pkim scale-readiness --format json
```

Optional self-healing path:

```bash
scripts/pkim scale-readiness --refresh-restore-drill --format json
```
