# Apply Approved Metadata

Use the shared local command surface only.

## Goal

Apply an already approved metadata payload to one record.

## Command

```bash
scripts/pkim apply-metadata --record "<record-ref>" --file "<payload.json>" --dry-run
```

## Required result

- before state
- intended mutation
- refreshed after state for live mode
- rejected fields with reasons when policy blocks them

## Allowed write surface

- `PKIM_ID`
- `Review_State`
- `DocRole`
- `LastProfiledAt`
- `Automation_Last_Run_State`

## Hard rule

Dry-run first. No blind live writes.
