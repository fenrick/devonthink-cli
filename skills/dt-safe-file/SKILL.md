---
name: dt-safe-file
description: Evaluate, then safely replicate or move one DEVONthink record under PKIM filing policy with dry-run first and post-write verification. Make sure to use this skill whenever the user asks to file, move, replicate, archive, or relocate a PKIM record in DEVONthink, even if they describe it as "put this where it belongs" rather than naming the command.
compatibility: Works in any runtime that can resolve a DEVONthink record, validate filing policy, and run the shared `scripts/pkim safe-file` command surface. The local CLI is the preferred deterministic path when available.
---

# dt-safe-file

This skill exists because filing is one of the few operations that can quietly damage structure if the model gets sloppy. PKIM needs a policy gate, a dry-run, and a verified mutation record, not a casual “move that over there.”

Your job is to decide whether a filing action is allowed, present the proposal clearly, and only execute live filing when the gate conditions are satisfied and the user has actually approved it.

## What this skill is for

Use it for one bounded filing action on one record:

- replicate an imported record into a stable destination group
- move an imported approved record into a stable destination group
- optionally rename the imported record to a clearer human title as part of filing
- optionally apply aliases, tags, and abstract alignment metadata during filing
- assess whether an indexed record can safely replicate under indexed-folder policy
- archive an approved record into an allowed archive path

The result should be either:

- a clear filing proposal, or
- a verified filing mutation result

## Why this matters

Filing is where queue logic becomes structure. Bad metadata is annoying. Bad filing is how records disappear into the wrong branch and stop being findable by humans.

The safety comes from:

- dry-run first
- explicit policy evaluation
- stable destination allowlist
- optional rename-to intent when the ingest title is junk
- optional aliases/tags/abstract alignment when retrieval quality would materially improve
- live gating on capability probe plus write gate
- post-write refresh verification

## Workflow

Follow this sequence.

1. Resolve the target record and intended destination.
2. If the destination group does not exist yet, switch first to `skills/dt-ensure-group-path/SKILL.md`.
3. Run dry-run first with `scripts/pkim safe-file ... --format json`.
4. Read the returned `risk_level`, `risk_flags`, `blocking`, and `rationale`.
5. If the result is `blocked`, stop and explain the blocking condition plainly.
6. If the result is a proposal, confirm whether the user wants the live action.
7. Before live filing, confirm:
   - `PKIM_ALLOW_PRODUCTION_WRITES=true`
   - capability probe passes
   - the record is imported, or it is an indexed record that passed the indexed path-policy checks
   - `Review_State=approved`
   - destination is inside the stable allowlist
   - any `--rename-to` value is only being used for an imported record
8. Run live filing with `--live`.
9. Read `runs/<run-id>/mutation.json`.
10. Verify that the `after` state matches the intended action.

## How to think about filing

### Replicate vs move

**For standard evidence intake (imported record from `/Inbox/` → permanent filing destination), always use `--action move`.** This is the expected and correct action. It calls `dt.move`, which relocates the record cleanly. The record leaves the Inbox and appears only at the destination.

Use `replicate` only when you explicitly want to keep the source record in place while placing a copy in the destination — for example, replicating into a second group for a specific cross-reference purpose.

**DEVONthink 4 replicate behaviour:** In DEVONthink 4, `dt.replicate` is non-functional for both same-database and cross-database targets (returns null silently). The CLI therefore maps `--action replicate` to `dt.duplicate`, which creates an **independent copy** at the destination rather than a true DEVONthink replica (shared underlying file). The output will include `"actual_operation": "duplicate"` and a note explaining this. **This means the source record remains in its original location and a separate independent copy appears at the destination — it does not move the record.** Using `--action replicate` for standard intake filing will create duplicates: the original stays in Inbox and a copy appears at the destination. Use `--action move` to actually relocate the record.

### Rename while filing

Use `--rename-to` only for imported records when the current ingest title is clearly garbage or materially weaker than the understood content.

Do not use it for indexed items. Indexed filenames and paths stay under filesystem control.

### Alignment metadata while filing

**PKIM_ID alias is automatic for imported records.** If the record has a `PKIM_ID` in its customMetaData, safe-file automatically includes it in the aliases applied during filing — even if `--aliases` was not passed. This ensures the record's stable identity survives any rename or refile, and `[[PKIM_ID]]` WikiLinks stay live.

You can still pass `--aliases` to add additional aliases. They will be merged with the auto-injected PKIM_ID alias.

Use the other alignment fields when they improve retrieval and discovery directly:

- `tags`
- `abstract` stored in the DEVONthink comment field

Good cases:

- tags that sharpen retrieval and classification
- a short abstract that captures what the record actually is

Do not use this step to dump a giant metadata blob into the record. Keep it bounded to what improves storage quality and search.

For indexed items, do not change filename or path semantics as part of this step. Filing decides placement; metadata alignment improves retrieval.

### Indexed content

Indexed filing is stricter:

- indexed `move` is always blocked
- indexed `rename` is always blocked
- indexed metadata alignment during filing is blocked; use the metadata path instead
- indexed `replicate` is allowed only when the indexed path checks pass
- the command should surface:
  - current filesystem path
  - whether the path exists
  - whether `Origin_Last_Path` is missing or differs from the current path

Live indexed replicate should update:

- `Origin_Last_Path`
- `Indexed_Risk_State`

### Destination discipline

Treat the destination allowlist as real policy, not a hint:

- `/Sources/Imported`
- `/Sources/Indexed`
- `/Archive`

If the desired destination is outside that surface, stop and say so.

## How to know you are doing it right

You are doing this skill correctly when:

- dry-run happens first
- the risk and blocking conditions are surfaced verbatim
- live filing only happens after explicit approval
- the mutation result is checked, not assumed

You are doing it badly when:

- you jump straight to `--live`
- you move a record just because the destination sounds plausible
- you ignore indexed/imported distinctions
- you treat a mismatch as “probably fine”

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## What not to do

- Do not perform live filing without a prior dry-run in the same thread.
- Do not create missing groups inside this skill. Use `dt-ensure-group-path` first.
- Do not live-move indexed records.
- Do not bypass the capability probe.
- Do not treat an out-of-allowlist destination as a small warning.
- Do not rename or move indexed records through filing automation.
- Do not use aliases, tags, or abstract as a substitute for a real note when synthesis is needed.

## Output

For dry-run, produce a filing proposal. Canonical shape written to `runs/<run-id>/filing-proposal.json`:

```json
{
  "run_id": "RUN-2026-04-17T15-18-00Z",
  "mode": "dry-run",
  "record": {
    "pkim_id": "EV-20260417-0007",
    "dt_uuid": "03CF4017-...",
    "dt_item_link": "x-devonthink-item://03CF4017-...",
    "capture_type": "imported",
    "review_state": "approved"
  },
  "proposed_action": "replicate",
  "destination": "/Sources/Imported/PKIM",
  "result": "proposal",
  "risk_level": "low",
  "risk_flags": [],
  "blocking": null,
  "rationale": "Record is imported, Review_State=approved, destination is within allowlist."
}
```

Valid `result` values for dry-run: `proposal` (allowed), `blocked` (not allowed).
Valid `risk_level` values: `low`, `medium`, `high`. Risk at `high` requires explicit user escalation before any live action.

For live runs, produce a mutation result written to `runs/<run-id>/mutation.json`:

```json
{
  "run_id": "RUN-2026-04-17T15-18-00Z",
  "mode": "live",
  "record": {
    "pkim_id": "EV-20260417-0007",
    "dt_uuid": "03CF4017-..."
  },
  "intended": {
    "action": "replicate",
    "destination": "/Sources/Imported/PKIM"
  },
  "before": {
    "location": "/Inbox"
  },
  "after": {
    "location": "/Sources/Imported/PKIM",
    "name": "Allen Tickler File overview"
  },
  "mismatch": null,
  "result": "ok"
}
```

A `result` of `"mismatch"` means the after-state did not match the intended action. Treat this as a failed mutation — inspect `mutation.json` and do not assume the record is in its intended state.

## Preferred tool path

Dry-run:

```bash
scripts/pkim safe-file \
  --record "<ref>" \
  --destination "/Sources/Imported/PKIM" \
  --action move \
  --format json
```

Live:

```bash
scripts/pkim safe-file \
  --record "<ref>" \
  --destination "/Sources/Imported/PKIM" \
  --action move \
  --live \
  --format json
```

Use live mode only after the dry-run proposal is clean and the user has approved the action.
