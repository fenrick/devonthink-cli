# Sweep Inbox — Prompt Contract

## Purpose

Triage all records in a database inbox that are missing PKIM metadata, classify them from native DEVONthink `kind`, and produce a prioritised intake plan. No writes happen until Step 3 (flagging `needs-human`) and Step 5 (applying metadata).

This is the start of the intake loop described in `docs/ops/intake-runbook.md`.

## Step 1 — Run the sweep

```
pkim sweep-inbox \
  --database <db-name> \
  --scope inbox \
  --format json
```

Default scope is `inbox` (limits to `/Inbox/`). Use `--scope all` if you suspect records elsewhere in the database are also missing metadata.

## Step 2 — Interpret the output

Each record in `records[]` has:
- `recommended_action`: `profile` / `ocr-first` / `needs-human`
- `kind`: native DEVONthink file kind
- `intake_class`: `pdf` / `web` / `markdown` / `office` / `scan` / `email` / `unknown`
- `needs_ocr`: whether OCR should be triggered before profiling
- `is_indexed`: whether the record is an indexed file (treat with extra care)
- `word_count`: proxy for whether the record is readable

Interpret the batch summary in `by_action`:
- `profile` — ready for agent profiling; these are your primary workload
- `ocr-first` — trigger DEVONthink OCR first, then re-sweep
- `needs-human` — cannot be auto-profiled; will be flagged in live mode

## Step 3 — Flag unresolvable records

If there are `needs-human` records, apply the flag:

```
pkim sweep-inbox \
  --database <db-name> \
  --scope inbox \
  --live \
  --format json
```

This sets `Review_State=needs-human` only on records classified as `needs-human`. Verify the output lists the correct UUIDs in `needs_human_applied`.

Requires `PKIM_ALLOW_PRODUCTION_WRITES=true`.

## Step 4 — Handle OCR candidates

For each record where `needs_ocr: true`:
- Open the record in DEVONthink
- Run Data → Convert → to Searchable PDF
- Re-run the sweep after OCR completes

Do not profile a record with zero words — the summary will be empty.

## Step 5 — Profile and apply metadata

For each record with `recommended_action: profile`, work through individually:

```
pkim profile --record "<referenceURL>" --format json
```

Read the source content. Synthesise:
- What does this record actually contain?
- What is its DocRole: `evidence`, `knowledge`, or `relation`?
- What `Review_State` is appropriate: `profiled` is the correct state after first profiling

Then apply:

```
pkim apply-metadata \
  --record "<referenceURL>" \
  --file runs/<run-id>/metadata-intent.json \
  --live
```

With at minimum:
```json
{
  "PKIM_ID": "mint",
  "Review_State": "profiled",
  "DocRole": "evidence"
}
```

## Step 6 — Verify queue clears

After processing a batch, re-run the sweep to confirm the count drops:

```
pkim sweep-inbox --database <db-name> --scope inbox --format json
```

`total` should reflect only unprocessed records.

## Quality bar

- Do not apply `Review_State=profiled` to a record you have not actually read.
- A record's `DocRole` must match what it actually is — not what you guess from the filename.
- Treat DEVONthink `kind` as the authoritative file-type signal. Use filename extension only as a narrow fallback when `kind` is absent or useless.
- If a record is unreadable (binary, corrupt, zero words after OCR), use `needs-human` not `profiled`.
- Indexed records get profiled but never moved — flag that for the human to handle.

## Failure modes

| Condition | Action |
|---|---|
| `result: error` with "Database not found" | Confirm database name; check DEVONthink is open |
| Word count stays 0 after OCR | Source file may be corrupt; set `needs-human` manually |
| `needs_human_applied` is empty in live mode | Check `PKIM_ALLOW_PRODUCTION_WRITES=true` is set |
| Sweep returns 0 records but `Needs Profile` queue is non-empty | Scope may be wrong; try `--scope all` |
