# Custom metadata schema

The canonical PKIM custom metadata fields. Every field's identifier is lowercase; DT prepends the `md` storage prefix automatically. `mcp__devonthink__set_record_custom_metadata` accepts either form (`docrole` or `mddocrole` — both refer to the same field).

Use `mode="merge"` on every write. `mode="replace"` drops every field not in the payload; you almost never want that.

## Identity + class

| Field | Type | Values | Purpose |
|---|---|---|---|
| `pkim_id` | text | `<CLASS>-YYYYMMDD-NNNN` | Human-readable PKIM identifier. Also stored in `aliases`. |
| `docrole` | set | `evidence` / `knowledge` / `relation` / `claim` | Which class the record is. Drives smart groups + tag inference. |
| `notetype` | set | `literature` / `synthesis` / `topic` / `project` / `decision` / `workflow` | For KN records only. Sub-classification. |

## Lifecycle

| Field | Type | Values | Purpose |
|---|---|---|---|
| `review_state` | set | `inbox` / `profiled` / `needs-human` / `approved` / `filed` / `mirrored` | Where in the review ladder the record sits. Drives smart groups. |
| `knowledgestatus` | set | `active` / `reviewed` / `published` / `archived` | KN-only. Publication ladder. |
| `evidencestatus` | set | `proposed` / `approved` / `retired` / `superseded` | EV-only. Evidence status. |
| `relationstatus` | set | `proposed` / `reviewed` | RL-only. |

## Relation edges

| Field | Type | Values | Purpose |
|---|---|---|---|
| `relation_type` | set | `supports` / `contradicts` / `extends` / `summarizes` / `references` / `exemplifies` / `precedes` / `supersedes` | RL-only. The edge class. |
| `source_item` | text | item link `x-devonthink-item://<uuid>` | RL-only. Source endpoint. |
| `target_item` | text | item link | RL-only. Target endpoint. |

## Claim fields (CL records)

| Field | Type | Values | Purpose |
|---|---|---|---|
| `claimtype` | set | `fact` / `inference` / `assumption` / `open-question` | Claim's epistemic type. |
| `claimconfidence` | set | `low` / `medium` / `high` | Confidence band. |
| `parentkn_id` | text | `KN-YYYYMMDD-NNNN` | Which KN this claim was extracted from. INDEX-POINTER — the authoritative edge is the WikiLink in the body. |
| `knowledgeconfidence` | set | `low` / `medium` / `high` | KN-level confidence, not to be confused with per-claim confidence. |
| `claim_backed` | set | `yes` / `no` / `partial` | KN-only. Derived by the mirror from the KN's claim block. |

## Provenance

| Field | Type | Values | Purpose |
|---|---|---|---|
| `origin_uri` | text | any URI | Where the record came from (URL, file:// path, capture source). |
| `origin_last_path` | text | any path | Last filesystem location before import. |
| `canonicalsourceurl` | text | any URL | The canonical URL for a captured source. |
| `capturetype` | set | `import` / `clip` / `scan` / `web` / `note` | How the EV entered the system. |
| `content_sha256` | text | hex digest | For dedupe. |
| `createdbymode` | set | `human` / `agent` / `automation` | Whether a human or an agent authored the record. |
| `lastrunid` | text | run identifier | Which orchestrated run last touched this. |

## Topics + indexes

| Field | Type | Values | Purpose |
|---|---|---|---|
| `primarytopic` | text | free | The one topic this record is primarily about. |

## State signals (derived, drive smart groups)

| Field | Type | Values | Purpose |
|---|---|---|---|
| `needs_ocr` | boolean | | EV-only. Set true when a PDF has no extractable text yet. |
| `knowledge_link_state` | text | free | Whether an EV has an inbound knowledge link. |
| `relation_gap_state` | text | free | Whether a KN has expected RLs missing. |
| `indexed_risk_state` | text | free | EV-only. Whether an indexed EV file is at risk (moved / deleted / permission issues). |
| `mirror_state` | text | `fresh` / `stale` | KN-only. Whether the mirrored file matches the DT record. Set by the mirror sync workflow. |
| `automation_last_run_state` | set | `ok` / `error` / `pending` | Set by any skill that touched the record. Drives the `Automation Error` smart group. |

## Timestamps

| Field | Type | Purpose |
|---|---|---|
| `lastprofiledat` | date | When `dt-intake` last profiled this record. Never round-trip through string; use `mode="merge"` and pass an ISO date. |
| `lastmirroredat` | date | KN-only. When the mirror last touched this. |

## Registration on first use

If a field doesn't exist in DT yet, writing it via `mcp__devonthink__set_record_custom_metadata` auto-registers it. The type is inferred from the value on first write, so **write the right type first time**:

- Boolean fields: pass `true` / `false`, not `"true"` / `"false"`.
- Date fields: pass an ISO 8601 string (`"2026-07-15T10:30:00Z"`).
- Set (enum) fields: pass a string from the canonical vocabulary.

DT reports `dropped_fields` + `rejection_reasons` if a value doesn't match a set-field's vocabulary. Read those on every write; do not assume success.
