# Update Knowledge Note — Command Surface

Update the body of an existing knowledge note in DEVONthink. Replaces named sections or appends to evidence links. Does not touch metadata fields — route those through `scripts/pkim apply-metadata`.

Used by:
- `skills/dt-build-knowledge-note/SKILL.md` — update path when resolution decision is `update`
- `skills/dt-reconcile-relation-edge/SKILL.md` — no (use `update-relation-note` instead)
- `skills/dt-inspect-graph-neighbourhood/SKILL.md` — dispatches to this when a node needs body enrichment

## Command

```bash
scripts/pkim update-knowledge-note \
  --note "<item-link | PKIM_ID | UUID>" \
  [--summary "<new summary text>"] \
  [--key-points "<newline-separated points>"] \
  [--add-evidence-link "<Name|url>"] \
  [--live] \
  [--format json]
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `--note` | yes | Note reference: item link (`x-devonthink-item://…`), PKIM_ID, or UUID |
| `--summary` | no | Replacement content for the `## Summary` section |
| `--key-points` | no | Newline-separated list; replaces the `## Key Points` section |
| `--add-evidence-link` | no | Appends one item to `## Evidence Links`. Format: `Name\|url`. If `url` is already in the section, skipped. |
| `--live` | no | Write to DEVONthink. Dry-run if omitted. Requires `PKIM_ALLOW_PRODUCTION_WRITES=true`. |
| `--format` | no | `json` (default `text`) |

At least one of `--summary`, `--key-points`, or `--add-evidence-link` must produce a change. If no changes are detected, result is `dry-run` with message `No changes requested`.

## Pre-conditions

- DEVONthink must be running.
- Record must exist and be resolvable via the given reference.
- `PKIM_ALLOW_PRODUCTION_WRITES=true` required for `--live`.

## Expected output (dry-run)

```json
{
  "run_id": "RUN-2026-04-21T09-00-00Z",
  "command": "update-knowledge-note",
  "result": "dry-run",
  "dry_run": true,
  "record": {
    "uuid": "03CF4017-...",
    "name": "Problem framing in local second-brain systems",
    "dt_item_link": "x-devonthink-item://03CF4017-..."
  },
  "draft_body": "# Problem framing…\n\n## Summary\n\nUpdated summary…\n\n…"
}
```

## Expected output (live)

```json
{
  "run_id": "RUN-2026-04-21T09-05-00Z",
  "command": "update-knowledge-note",
  "result": "ok",
  "dry_run": false,
  "record": {
    "uuid": "03CF4017-...",
    "name": "Problem framing in local second-brain systems",
    "dt_item_link": "x-devonthink-item://03CF4017-..."
  },
  "draft_body": "# Problem framing…\n\n## Summary\n\nUpdated summary…\n\n…"
}
```

## Artifact

`runs/<run-id>/mutation.json` — contains the full result payload.

## Section contract

The command operates on specific named sections. If a section does not exist in the current body, it is appended at the end. Sections not named in the arguments are left unchanged.

| Section heading | Argument that controls it |
|---|---|
| `## Summary` | `--summary` |
| `## Key Points` | `--key-points` |
| `## Evidence Links` | `--add-evidence-link` (append only) |
| `## Related Notes` | not controllable via this command |

## Hard rules

- Read-only without `--live`.
- Never modifies metadata fields — use `apply-metadata` for those.
- `--add-evidence-link` appends; it does not replace the evidence links section.
- If the same URL is already present in `## Evidence Links`, the append is silently skipped.

## Failure modes

| Error | Cause | Resolution |
|---|---|---|
| `Record not found` | Reference does not resolve | Confirm reference format; use item link or PKIM_ID |
| `PKIM_ALLOW_PRODUCTION_WRITES not true` | `--live` without env flag | Set `PKIM_ALLOW_PRODUCTION_WRITES=true` |
| `No changes requested` | All arguments produced no diff | Confirm arguments against current note body |
| `Post-write body mismatch` | JXA write returned different content | Re-read record and inspect; retry if transient |
