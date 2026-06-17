# Update Relation Note — Command Surface

Update the rationale body or `RelationStatus` metadata of an existing relation note. Used by the strengthen path in `dt-reconcile-relation-edge`. Does not change source, target, or relation type — those fields are immutable after creation.

## Command

```bash
scripts/pkim update-relation-note \
  --note "<item-link | PKIM_ID | UUID>" \
  [--rationale "<replacement rationale text>"] \
  [--relation-status <proposed|reviewed|accepted|retired>] \
  [--live] \
  [--format json]
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `--note` | yes | Note reference: item link (`x-devonthink-item://…`), PKIM_ID, or UUID |
| `--rationale` | no | Replacement text for the `## Why This Relation Exists` section |
| `--relation-status` | no | New `RelationStatus` value: `proposed`, `reviewed`, `accepted`, or `retired` |
| `--live` | no | Write to DEVONthink. Dry-run if omitted. Requires `PKIM_ALLOW_PRODUCTION_WRITES=true`. |
| `--format` | no | `json` (default `text`) |

At least one of `--rationale` or `--relation-status` must be provided.

## Pre-conditions

- DEVONthink must be running.
- Record must exist and be resolvable.
- `PKIM_ALLOW_PRODUCTION_WRITES=true` required for `--live`.

## Expected output (dry-run)

```json
{
  "run_id": "RUN-2026-04-21T09-10-00Z",
  "command": "update-relation-note",
  "result": "dry-run",
  "dry_run": true,
  "record": {
    "uuid": "AB12CD34-...",
    "name": "Problem framing → local-first PKIM",
    "dt_item_link": "x-devonthink-item://AB12CD34-..."
  },
  "draft_body": "# Problem framing → local-first PKIM\n\n**Type:** supports\n\n## Why This Relation Exists\n\nStrengthened rationale…\n\n…",
  "metadata_changes": {
    "RelationStatus": "accepted"
  }
}
```

## Expected output (live)

```json
{
  "run_id": "RUN-2026-04-21T09-15-00Z",
  "command": "update-relation-note",
  "result": "ok",
  "dry_run": false,
  "record": {
    "uuid": "AB12CD34-...",
    "name": "Problem framing → local-first PKIM",
    "dt_item_link": "x-devonthink-item://AB12CD34-..."
  },
  "draft_body": null,
  "metadata_changes": {
    "RelationStatus": "accepted"
  }
}
```

(`draft_body` is null in the live result when only `--relation-status` was changed with no body update.)

## Artifact

`runs/<run-id>/mutation.json` — contains the full result payload.

## What this command does not do

- Does not change `Source_Item`, `Target_Item`, or `Relation_Type` — these are immutable after creation.
- Does not create new relation notes — use `create-relation-note` for that.
- Does not retire a note and create a successor — the supersede path in `dt-reconcile-relation-edge` handles that sequence.

## Strengthen vs supersede

Use this command when strengthening an existing relation (rationale thinning, status advancement). Use the supersede path in `dt-reconcile-relation-edge` when the relation type itself is wrong or the endpoints have changed meaning sufficiently that a new note is needed.

## Hard rules

- Read-only without `--live`.
- `--relation-status retired` via this command sets the field; it does not create a successor. For a full supersede, the calling skill must separately create the new relation note first.
- Body and metadata are written in sequence: body first, then metadata. If body write succeeds but metadata write fails, the record is in a partial state — re-inspect and apply only the remaining change.

## Failure modes

| Error | Cause | Resolution |
|---|---|---|
| `Record not found` | Reference does not resolve | Confirm reference format |
| `PKIM_ALLOW_PRODUCTION_WRITES not true` | `--live` without env flag | Set `PKIM_ALLOW_PRODUCTION_WRITES=true` |
| `No changes requested` | Neither `--rationale` nor `--relation-status` provided | Provide at least one argument |
| `Body write failed` | JXA plainText setter error | Inspect DEVONthink state; retry |
| `Metadata write failed` | JXA customMetaData setter error after body write | Body already written — apply metadata only on retry |
