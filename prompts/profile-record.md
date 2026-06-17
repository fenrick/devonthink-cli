# Profile Record

Read-only profiling command surface. Produces one structured DEVONthink record context packet plus a deterministic interpreted concept set without writing anything.

The project-level skill contract lives at `skills/dt-profile-record/SKILL.md`. This prompt describes the shared command surface the skill can use.

## Command

```bash
scripts/pkim profile --record "<ref>" --format json
```

`<ref>` accepts any of:
- `x-devonthink-item://UUID` — stable item link
- `EV-20260418-0001` — PKIM_ID
- `03CF4017-1689-4112-9213-E96C1EA37FD0` — bare UUID

## Required inputs

| Argument | Required | Description |
|---|---|---|
| `--record` | yes | Record reference (item link, PKIM_ID, or UUID) |
| `--format` | no | `json` (default) or `text` |
| `--runtime` | no | Caller name for audit trail |

## Pre-conditions

- DEVONthink must be running and the target database must be open.
- Run `scripts/pkim probe-capabilities` first and confirm `passed: true`.
- No write permissions are needed or used.

## Expected outputs

A `ProfilePacket` at `runs/<run-id>/profile.json` with:

### Read-only record context

| Field | Description |
|---|---|
| `record.*` | Native record identity, metadata, kind, location, filename, tags |
| `content` | Extracted or native text surface for the record |
| `analysis_warnings` | Non-blocking warnings about helper failures, fixture context, or metadata conflicts |
| `classified_groups` | Raw DEVONthink classify suggestions |
| `compared_records` | Raw DEVONthink compare results |
| `discovery.*` | Discovery helper status |
| `risk_level` | Record-level `low` / `medium` / `high` |

### Interpreted concept set

| Field | Description |
|---|---|
| `candidate_notes[]` | Ordered candidate concepts extracted from the source |
| `candidate_edges[]` | Proposed graph edges between candidate concepts and/or existing notes |
| `candidate_resolution_map[]` | Starts empty; later orchestration records candidate-to-note outcomes here |

Each `candidate_notes[]` entry includes:
- `candidate_id` — run-local orchestration ID
- `candidate_fingerprint` — deterministic source-local concept fingerprint for rerun comparison
- `order` — source-local sequence
- `title_hint`
- `concept_summary`
- `candidate_class` — `canonical-note-candidate`, `deferred-candidate`, `supporting-detail`, or `evidence-for-other-note`
- `note_intent`
- `source_anchors[]`
- `dependency_type` — `independent`, `depends-on-candidate`, or `edge-only`
- `dependency_targets[]`
- `note_worthiness` — `high`, `medium`, `low`
- `graph_value` — `node`, `edge-support`, `local-detail`
- `distinctness` — `distinct`, `overlapping`, `embedded`
- `cross_source_likelihood` — `high`, `medium`, `low`
- `defer_reason`
- `proposed_existing_neighbours[]`
- `risk_level`

Each `candidate_edges[]` entry includes:
- `edge_id`
- `source_candidate_id` and/or `source_note_ref`
- `target_candidate_id` and/or `target_note_ref`
- `relation_type`
- `rationale`
- `confidence`
- `source_anchors[]`
- `materialisation_status`
- `defer_reason`

### Compatibility fields

For the transition period, if the concept set yields exactly one canonical note candidate, the packet may also include:
- `knowledge_note_draft`
- `relation_candidates`

These are derived compatibility fields only. New downstream logic should consume the candidate-set fields instead.

## Example output shape

```json
{
  "run_id": "RUN-2026-04-22T10-00-00Z",
  "runtime": "codex",
  "result": "ok",
  "record": {
    "pkim_id": "EV-20260418-0007",
    "dt_uuid": "03CF4017-1689-4112-9213-E96C1EA37FD0",
    "name": "PKIM Design Brief v1.pdf"
  },
  "content": "This brief defines the operating model for the PKIM stack…",
  "classified_groups": [],
  "compared_records": [],
  "candidate_notes": [
    {
      "candidate_id": "C01",
      "candidate_fingerprint": "cpf-1234567890ab",
      "order": 1,
      "title_hint": "PKIM control plane in DEVONthink",
      "candidate_class": "canonical-note-candidate",
      "note_intent": "literature",
      "note_worthiness": "high"
    }
  ],
  "candidate_edges": [],
  "candidate_resolution_map": [],
  "risk_level": "low"
}
```

## Hard rules

- No write operations. The profile command is permanently read-only.
- Classify and compare results are discovery aids only.
- The concept set is deterministic scaffolding, not a canonical-resolution decision.
- `pkim profile` may identify and structure candidate concepts, but it does not decide create/update/merge/supersede and it never performs writes.
- Edge materialisation must not happen from the profile command.

## DEVONthink helper operations

The profile flow still exposes helper operations directly:

```bash
scripts/pkim devonthink-helper --operation read-record --ref "x-devonthink-item://…"
scripts/pkim devonthink-helper --operation classify --ref "EV-20260418-0001"
scripts/pkim devonthink-helper --operation compare --ref "EV-20260418-0001"
```

## Failure modes

| Error | Cause | Resolution |
|---|---|---|
| `Record not found` | Ref doesn't resolve to an open record | Check ref format; confirm database is open |
| `JXA profile query failed` | DEVONthink not running or AppleEvent timeout | Open DEVONthink and re-run |
| `result: error` in output | Any JXA failure | Read `message` field for details |
