# Evaluate Safe Filing — Prompt Contract

## Purpose

Evaluate whether a record can be replicated or moved to a destination group, and if approved execute the filing action with verification. Dry-run remains the default. Live filing is available for imported records and for indexed replicate only when the indexed path-policy checks pass.

## Step 1 — Identify the record and destination

You need:
- The record reference (`PKIM_ID`, item link, or UUID)
- The destination group path (for example `/Sources/Imported/PKIM` or `/Archive/Reviewed`)
- The action: `replicate` or `move`
- Optional: a better human title to apply during filing for imported records via `--rename-to`
- Optional: aliases via `--aliases`
- Optional: tags via `--tags`
- Optional: abstract via `--abstract` (stored in the DEVONthink comment field)

For standard evidence intake (imported record from Inbox → permanent destination), use `move`. Use `replicate` only when you explicitly want to keep the source record in its current location while placing a copy at the destination.

## Step 2 — Run the dry-run proposal first

```bash
pkim safe-file \
  --record "<record-ref>" \
  --destination "<group-path>" \
  --action replicate|move \
  --rename-to "<better title>" \
  --aliases "alias one; alias two" \
  --tags "tag one,tag two" \
  --abstract "<short summary>" \
  --format json
```

Inspect:
- `result`
- `risk_level`
- `risk_flags`
- `blocking`
- `rationale`

Do not jump straight to live filing unless the user has explicitly approved it.

If the destination group does not exist yet, create it first with:

```bash
pkim ensure-group-path \
  --database "<db-name>" \
  --path "<group-path>" \
  --format json
```

Use `--live` only after the dry-run path plan is clean and approved.

## Step 3 — Preconditions for live filing

Live filing is allowed only when all of the following are true:
- `PKIM_ALLOW_PRODUCTION_WRITES=true`
- `pkim probe-capabilities --format json` returns `passed: true`
- The record is imported, or it is an indexed record being replicated after the indexed path-policy checks pass
- `Review_State=approved`
- The destination is inside the stable allowlist:
  - `/Sources/Imported`
  - `/Sources/Indexed`
  - `/Archive`

For indexed records, also require:
- source filesystem path exists
- `Origin_Last_Path` / `Indexed_Risk_State` are updated during the live path when needed

## Step 4 — Run live filing

```bash
pkim safe-file \
  --record "<record-ref>" \
  --destination "<group-path>" \
  --action replicate|move \
  --rename-to "<better title>" \
  --aliases "alias one; alias two" \
  --tags "tag one,tag two" \
  --abstract "<short summary>" \
  --live \
  --format json
```

Live output is a `MutationResult` written to `runs/<run-id>/mutation.json` with:
- `before`
- `intended`
- `after`

The command re-reads state after the move or replicate and fails loudly on mismatch.
If `--rename-to` is provided for an imported record, the command also verifies that the record name matches the intended title after the write.
If `--aliases`, `--tags`, or `--abstract` are provided, the command also verifies those fields after the write.

Indexed records must not be renamed or moved by automation.

## Interpretation rules

| Condition | Action |
|---|---|
| `result: proposal` | Review the plan with the user |
| `result: blocked` | Do not proceed; fix the blocking condition |
| `result: error` | Treat as failed mutation or failed preflight |
| `risk_level: high` | Escalate to the user before any live action |
| `action=move` | Confirm the user accepts irreversibility |

## Policy rules

| Condition | Dry-run | Live |
|---|---|---|
| `Review_State` unset, `inbox`, `needs-human`, `blocked`, `filed`, `mirrored`, `archived` | Blocked | Blocked |
| `Review_State=profiled` | Proposal with risk | Blocked |
| Imported + `Review_State=approved` + `replicate` | Allowed | Allowed |
| Imported + `Review_State=approved` + `move` | Allowed with risk | Allowed |
| Indexed + `replicate` | Proposal with risk | Allowed only if indexed path-policy checks pass |
| Indexed + `move` | Blocked | Blocked |
| Destination outside allowlist | Blocked | Blocked |

## Failure modes

| Condition | Action |
|---|---|
| Record not found | Report the unresolved reference |
| Destination not found | Check the path and database scope |
| Capability probe fails | Stop; fix the runtime before any write |
| Post-write mismatch | Treat as a failed mutation and inspect `mutation.json` |
