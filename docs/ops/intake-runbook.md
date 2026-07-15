# Intake Runbook — Inbox Enrichment

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces it.

## Purpose

Turn arriving inbox records into profiled, enriched, and deliberately filed records. This runbook covers the actual pilot workflow: triage, profiling, enrichment in `/Inbox/`, optional low-risk knowledge-note creation, then rename and move once the record has semantic shape.

## When to run

- After a manual import batch into any database Inbox.
- After a browser capture session.
- After a scanner ingest.
- Periodically to clear the `Needs Profile` smart group across all databases.

## Trigger points

The intake loop is operator-triggered (no fully automatic sweep is in place at this phase). Typical triggers:

| Trigger | Method |
|---|---|
| New captures in Inbox | `pkim sweep-inbox --database <db>` to triage |
| Periodic queue clearing | Run sweep across all evidence databases |
| Post-import batch | Run sweep immediately after import |

## Step 1 — Sweep to classify

```bash
pkim sweep-inbox \
  --database PKIM-Pilot \
  --scope inbox \
  --format json
```

`--scope inbox` limits to `/Inbox/`; use `--scope all` to catch records in other locations that are missing PKIM metadata.

The output classifies each record as:

| `recommended_action` | Meaning |
|---|---|
| `profile` | Ready for agent profiling — run `pkim profile` |
| `ocr-first` | PDF or scan with low word count — trigger OCR in DEVONthink first |
| `needs-human` | Unrecognised type or unresolvable — flag manually |

## Step 2 — Handle OCR candidates

For any record with `recommended_action: ocr-first`:

1. Open the record in DEVONthink.
2. Run **Data → Convert → to Searchable PDF** (or use OCR via smart rule if configured).
3. Re-run `pkim sweep-inbox` after OCR completes. Word count should now exceed the threshold and the record will be reclassified to `profile`.

Do not run `pkim profile` on an unreadable scan — the summary will be empty and the metadata application will be wasted.

## Step 3 — Flag unresolvable records as `needs-human`

For records classified `needs-human`, apply the flag via live mode:

```bash
pkim sweep-inbox \
  --database PKIM-Pilot \
  --scope inbox \
  --live \
  --format json
```

This sets `Review_State=needs-human` on unrecognised-type records only. The `Needs Human Review` smart group will surface them for manual attention.

Requires `PKIM_ALLOW_PRODUCTION_WRITES=true`.

## Step 4 — Profile each record

For each record with `recommended_action: profile`, read the record and synthesise:

```bash
pkim profile --record "<referenceURL>" --format json
```

Review the profile output:
- `suggested_tags` — confirm relevance
  - `source.*` should be treated as the default stable provenance tag when the origin is clear
- `suggested_destination` — treat as a candidate, not an automatic answer
- `risk_level` — flag anything above low before proceeding

The profile command is read-only. Nothing is written at this step.

## Step 5 — Apply baseline metadata

After reviewing the profile, apply the minimum identity fields while the record still remains in `/Inbox/`:

```bash
pkim apply-metadata \
  --record "<referenceURL>" \
  --file runs/<run-id>/metadata-intent.json \
  --live
```

The metadata file must include at minimum:
- `PKIM_ID: mint` (will be resolved to the next sequence value)
- `Review_State: profiled`
- `DocRole: evidence` (or `knowledge` for notes)

Dry-run first, check the before/after diff, then apply live.

After this step the record will have `PKIM_ID` and `Review_State=profiled`, which clears it from the `Needs Profile` smart group. Do not move it yet.

## Step 6 — Enrich the record in Inbox

Once the record is profiled, do the semantic work before any filing:

1. decide whether the record is worth keeping active, needs human review, or should remain merely profiled
2. derive a better title if the ingest title is weak
3. derive tags, aliases, and a real browseable destination path
4. decide whether the record is low-risk enough for immediate knowledge-note creation
5. if yes, create or update the relevant knowledge note(s) and relation note(s)
6. wire the evidence into the graph using stable DEVONthink item links

The key rule is simple:

- profile in `/Inbox/`
- enrich in `/Inbox/`
- only then rename and move

`Review_State=approved` means the record is safe for the next bounded automation step. It does not mean "skip enrichment and throw it in a holding bucket."

## Step 7 — Apply approved enrichment metadata

After the title, tags, note intent, and destination are reviewed, write the approved metadata payload:

- `Review_State`
- retrieval tags and aliases
- any other bounded approved fields allowed by the metadata contract

Keep this mutation small and explicit. Metadata writeback is not the filing step.

## Step 8 — Rename and file deliberately

Rename and move only when all of these are true:

- the record is worth keeping
- the destination path reflects the actual subject grouping
- the record can be found later by DEVONthink item link even after rename and move
- any low-risk knowledge-note creation for this pass is already done

Use `pkim safe-file --action move` for the final relocation step. The `move` action is correct and expected for standard evidence intake: it relocates the record from Inbox to its permanent destination. Do not use `--action replicate` — in DEVONthink 4, replicate maps to duplicate and will leave the original in Inbox while creating a copy at the destination.

```bash
pkim safe-file \
  --record "<referenceURL>" \
  --destination "/Sources/Imported/<subject-group>" \
  --action move \
  --format json          # dry-run first

pkim safe-file \
  --record "<referenceURL>" \
  --destination "/Sources/Imported/<subject-group>" \
  --action move \
  --live \
  --format json          # live after dry-run is clean
```

For imported records with junk ingest titles, add `--rename-to "<better title>"` to the same filing action.

## Step 9 — Verify queues and browseability

After applying metadata, confirm the `Needs Profile` smart group no longer shows the record. In DEVONthink, open the smart group — it should be empty or show only unprocessed records.

Also verify:

- the knowledge note exists if this record was supposed to produce one
- the evidence note links still resolve after rename and move
- the destination folder makes human browsing easier, not harder

Cross-check via CLI:

```bash
pkim sweep-inbox --database PKIM-Pilot --scope all --format json
```

`total` should decrease by the number of records you just profiled.

## Source-type policy table

| Source type | Detection | Default action |
|---|---|---|
| PDF (OCR'd) | type=`PDF document`, word count ≥ 50 | profile |
| PDF (unreadable) | type=`PDF document`, word count < 50 | ocr-first |
| Scan / image | type contains jpeg, png, tiff, picture | ocr-first |
| Web bookmark | type=`Bookmark` | profile |
| Web archive | type=`Web archive` or `Web document` | profile |
| Markdown | type=`Markdown` or `Plain Text` | profile |
| Office document | type contains rtf, word, spreadsheet, excel | profile |
| Email | type contains email | profile |
| Indexed file | `isIndexed=true` | profile (no OCR flag) |
| Unknown | none of the above | needs-human |

## Indexed record handling

Indexed records are never flagged for OCR — DEVONthink does not import indexed files, so OCR must happen at the filesystem level before DEVONthink picks it up. They are classified as `profile` regardless of word count.

If an indexed PDF has zero words, investigate the source file directly. Do not trigger DEVONthink OCR on an indexed record.

## Queue contract

After a successful intake sweep:

| Queue | Expected state |
|---|---|
| `Needs Profile` | Empty (or shows only newly arrived records) |
| `Needs Human Review` | Shows any records flagged needs-human this sweep |
| `Needs OCR` | Shows any records where `Needs_OCR` was set (if OCR metadata applied) |

The `Needs Filing` queue is **not** cleared by baseline profiling. It clears only after enrichment is complete and the record has been renamed and moved to a deliberate long-term location.

## Failure modes

| Failure | Resolution |
|---|---|
| `Database not found` | Confirm database name; check DEVONthink is open |
| Record word count stays 0 after OCR | OCR may have failed; check DEVONthink's OCR log |
| `needs-human` flag not applying | Confirm `PKIM_ALLOW_PRODUCTION_WRITES=true` is set |
| `Needs Profile` queue not clearing | Confirm both `PKIM_ID` and `Review_State` were written |
| Profile returns empty summary | Source text may be missing — check word count and OCR state first |
| Filing destination feels generic or arbitrary | Stop. Derive a real browseable destination before moving the record |
| Record was moved before notes/tags/title were developed | Use the DEVONthink item link as the stable handle and finish enrichment from the new location |
