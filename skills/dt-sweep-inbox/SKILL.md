---
name: dt-sweep-inbox
description: Triage all records in a DEVONthink database inbox that are missing PKIM metadata, classify them by readiness, and drive each record through profile and metadata application until the intake queue is clear. Make sure to use this skill whenever the user asks to sweep the inbox, process arrivals, triage new captures, clear the needs-profile queue, run intake, or handle a batch of unprocessed records, even if they only say "what's in the inbox?" or "let's process these."
compatibility: Works in any runtime that can read DEVONthink records, call the shared `pkim sweep-inbox` and `pkim probe-capabilities` commands, and hand off to dt-profile-record and dt-apply-approved-metadata for per-record work.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-sweep-inbox

This skill exists because arriving records need to be classified before any deeper work begins. Profiling an unreadable scan is wasted effort. Filing an unprofiled record breaks downstream queue logic. The intake sweep is the gate that sorts what is ready from what is not.

Your job is to move a batch of unprocessed inbox records from unclassified to profiled and queue-assigned.

## What this skill is for

Use it to handle the full intake loop after records arrive in a DEVONthink database:

- sweep the inbox to classify all records by readiness
- identify which records need OCR before profiling
- flag unresolvable records for human review
- profile each ready record using `skills/dt-profile-record/SKILL.md`
- apply minimum identity metadata to each profiled record using `skills/dt-apply-approved-metadata/SKILL.md`
- verify the intake queue clears

The result should be that every processed record has a `PKIM_ID` and `Review_State=profiled`, and every unresolvable record is flagged `needs-human`.

## Why this matters

Intake is the moment when records join the system. If this step is sloppy, everything downstream degrades: queues fill with noise, filing runs on unprofiled records, and the knowledge layer starts being built on records that were never understood.

The structure of this skill is intentionally sequential and per-record. Batch operations obscure failures. One record at a time means one clear error message, one clean verification step, and one known state at the end.

## Workflow

Follow this sequence.

1. Confirm the target database and scope (`inbox` or `all`). Default to `inbox` unless the user has asked for a wider sweep or the `Needs Profile` queue appears stale.
2. Run `pkim sweep-inbox --database <db> --scope <scope> --format json`.
3. Read the sweep output and partition records into three buckets:
   - `profile` — ready for profiling
   - `ocr-first` — readable content not yet available; OCR required first
   - `needs-human` — unrecognisable type or unresolvable
4. Report the counts to the user before proceeding: how many in each bucket, which are indexed, any `high` risk flags from the sweep.
5. Handle OCR candidates first:
   - List each record with `recommended_action: ocr-first` and its current word count.
   - Instruct the user to trigger OCR in DEVONthink (Data → Convert → to Searchable PDF) for each one.
   - Do not profile zero-word records. Wait for OCR and re-sweep those records before continuing.
6. If there are `needs-human` records and the user confirms, flag them with a live sweep run. This is the only write this skill does directly — everything else goes through the sub-skills.
7. For each record with `recommended_action: profile`, process one at a time:
   a. Switch to `skills/dt-profile-record/SKILL.md` to produce a profile assessment.
   b. Review the profile with the user: confirm suggested tags, destination, and risk level.
   c. Switch to `skills/dt-apply-approved-metadata/SKILL.md` to apply at minimum: `PKIM_ID: mint`, `Review_State: profiled`, `DocRole: <class>`.
   d. Confirm the metadata was applied before moving to the next record.
8. After all profileable records in the batch are done, re-run `pkim sweep-inbox --database <db> --scope <scope> --format json`.
9. Confirm `total` has decreased by the number of records processed. Report any records that remain unexpectedly.

## How to think about triage

### Classification signals

The sweep classifies using native DEVONthink `kind` and word count. These are the authoritative signals for this step. Do not override `recommended_action` based on filename guesses.

| Condition | Classification |
|---|---|
| Kind is PDF, word count ≥ 50 | `profile` |
| Kind is PDF, word count < 50 | `ocr-first` |
| Kind is scan, image, TIFF, JPEG | `ocr-first` |
| Kind is Markdown, plain text, RTF | `profile` |
| Kind is web archive, bookmark, web document | `profile` |
| Kind is office document, spreadsheet, email | `profile` |
| Indexed record (`is_indexed: true`) | `profile` — no OCR flag regardless of word count |
| Kind not recognised | `needs-human` |

### Indexed records

Indexed records are profiled like any other record but are never moved. If an indexed PDF has zero words, investigate the source file directly — DEVONthink cannot run OCR on indexed content. Do not set `ocr-first` for indexed records; flag them `needs-human` if the source itself is unreadable.

### One record at a time

Do not batch profile multiple records in a single pass. Profile each record, confirm the result, apply metadata, confirm the write, then move to the next. Batching hides failures and leaves you with uncertain queue state.

### Minimum metadata on intake

At intake, apply only the minimum fields that move a record out of the `Needs Profile` queue:

- `PKIM_ID` — mint a new ID
- `Review_State` — set to `profiled`
- `DocRole` — set from the profile assessment

Do not apply filing metadata, tags, or destination assignments at intake. Those belong to the filing workflow after the record is profiled and approved.

### Risk level handling

If the profile for any record returns `risk_level: high`, stop before applying metadata and surface the finding to the user. High-risk records need explicit human review before they advance.

## How to know you are doing it right

You are doing this skill correctly when:

- the sweep output is read and reported before any individual profiling starts
- OCR candidates are identified and handed to the user before profiling begins
- each record is profiled and verified individually before moving to the next
- metadata is confirmed written before moving on
- the final re-sweep shows the `total` has dropped

You are doing it badly when:

- you profile records without reading their content
- you skip the verification sweep at the end
- you profile a zero-word record and produce an empty summary
- you apply metadata in bulk without per-record confirmation
- you move indexed records as part of intake

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `mcp__devonthink__set_record_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## What not to do

- Do not profile a record with `recommended_action: ocr-first`. Return to those records after OCR.
- Do not apply `Review_State=profiled` to a record you have not actually read.
- Do not move or file any record during intake. Filing belongs to `dt-safe-file` after the record reaches `Review_State=approved`.
- Do not use `--scope all` casually. Confirm with the user before sweeping beyond the inbox.
- Do not proceed past a `risk_level: high` profile without explicit user review.
- Do not apply metadata fields beyond the minimum intake set at this step.
- Do not treat the `needs-human` flag as a dispose action. Flagged records still need manual attention; the smart group just surfaces them.

## Output

The sweep command produces a batch summary. Canonical shape at `runs/<run-id>/sweep.json`:

```json
{
  "run_id": "RUN-2026-04-17T15-30-00Z",
  "database": "PKIM-Pilot",
  "scope": "inbox",
  "total": 12,
  "by_action": {
    "profile": 8,
    "ocr-first": 3,
    "needs-human": 1
  },
  "records": [
    {
      "dt_uuid": "03CF4017-...",
      "dt_item_link": "x-devonthink-item://03CF4017-...",
      "name": "2024-06-12-scan.pdf",
      "kind": "PDF document",
      "intake_class": "pdf",
      "word_count": 0,
      "is_indexed": false,
      "needs_ocr": true,
      "recommended_action": "ocr-first"
    }
  ]
}
```

For live mode (flagging `needs-human` records), the result also includes:

```json
{
  "needs_human_applied": ["03CF4017-...", "A1B2C3D4-..."]
}
```

For the intake run as a whole, report to the user:

- records swept
- buckets: how many in `profile`, `ocr-first`, `needs-human`
- per-record profile and metadata results (from sub-skills)
- final re-sweep count confirming queue cleared

## Preferred tool path

Dry-run sweep (read-only triage):

```bash
pkim sweep-inbox \
  --database "PKIM-Pilot" \
  --scope inbox \
  --format json
```

Live sweep (flags `needs-human` records only):

```bash
pkim sweep-inbox \
  --database "PKIM-Pilot" \
  --scope inbox \
  --live \
  --format json
```

The live sweep only writes `Review_State=needs-human` to unresolvable records. It does not profile or apply full metadata. Full metadata application for `profile`-classified records goes through `pkim apply-metadata` via `dt-apply-approved-metadata`.
