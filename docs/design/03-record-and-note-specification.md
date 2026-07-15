# Record And Note Specification

## Purpose

Field-by-field schema and note templates. The conceptual model (why records are shaped this way) lives in [02 Information Model](02-information-model.md); this document is the exhaustive contract.

Two rules govern every field:

1. **Graph edges live in note bodies as WikiLinks** (within a database) or item links (across databases). Custom metadata describes *properties* of a record, not relationships to other records. See [02 Information Model](02-information-model.md) §Metadata classification.
2. **Every field is classified** PROPERTY / INDEX-POINTER / DERIVED at design time.

## Identifier contract

### PKIM_ID

Format: `<class-prefix>-<YYYYMMDD>-<NNNN>` — zero-padded 4-digit sequence, resets per class + date.

- `EV-20260417-0007`
- `KN-20260417-0021`
- `RL-20260417-0004`
- `CL-20260517-0001`

Class prefixes: `EV`, `KN`, `RL`, `CL`. Minted once, never reassigned.

Stored two places:
- `mdpkim_id` custom metadata (canonical).
- DEVONthink `Aliases` field, semicolon-joined with the display name (so `lookup_records name: "KN-..."` finds it).

### DT UUID

Native DEVONthink UUID. Read from the record; never invent. Persistent identifier for cross-references (`x-devonthink-item://<UUID>`).

### DT ItemLink

`x-devonthink-item://<UUID>`. The clickable reference used in every context outside DEVONthink: mirror files, cross-database links, RL endpoint metadata.

## Custom metadata fields

Canonical field set. Every field's identifier is lowercase; DEVONthink stores with an `md` prefix (`docrole` → `mddocrole`). Both forms accepted by `set_record_custom_metadata`.

### Identity + class

| Field | Classification | Type | Values | Purpose |
|---|---|---|---|---|
| `pkim_id` | PROPERTY | text | `<CLASS>-YYYYMMDD-NNNN` | Human-readable identifier |
| `docrole` | PROPERTY | set | `evidence` / `knowledge` / `relation` / `claim` | Record class |
| `notetype` | PROPERTY | set | `literature` / `synthesis` / `topic` / `project` / `decision` / `workflow` | KN sub-class |
| `createdbymode` | PROPERTY | set | `human` / `agent` / `mixed` | Provenance of authorship |

### Lifecycle

| Field | Classification | Type | Values | Purpose |
|---|---|---|---|---|
| `review_state` | PROPERTY | set | `inbox` / `profiled` / `needs-human` / `approved` / `filed` / `blocked` / `mirrored` / `archived` / `error` | Operational review status |
| `evidencestatus` | PROPERTY | set | `proposed` / `approved` / `retired` / `superseded` | EV-only |
| `knowledgestatus` | PROPERTY | set | `active` / `reviewed` / `published` / `archived` / `needs-review` | KN-only |
| `knowledgeconfidence` | PROPERTY | set | `low` / `medium` / `high` | KN-only — worst-case claim confidence |
| `relationstatus` | PROPERTY | set | `proposed` / `reviewed` / `accepted` / `retired` | RL-only |
| `relationconfidence` | PROPERTY | set | `low` / `medium` / `high` | RL-only |
| `claimtype` | PROPERTY | set | `fact` / `inference` / `assumption` / `open-question` | CL-only |
| `claimconfidence` | PROPERTY | set | `low` / `medium` / `high` | CL-only |

### Relation endpoints (INDEX-POINTER, RL-only)

| Field | Classification | Type | Values | Purpose |
|---|---|---|---|---|
| `source_item` | INDEX-POINTER | text | item link | Duplicates the body's source WikiLink |
| `target_item` | INDEX-POINTER | text | item link | Duplicates the body's target WikiLink |
| `relation_type` | PROPERTY | set | closed vocabulary (below) | Edge class |

### CL parent (INDEX-POINTER, CL-only)

| Field | Classification | Type | Values | Purpose |
|---|---|---|---|---|
| `parentkn_id` | INDEX-POINTER | text | `KN-YYYYMMDD-NNNN` | Duplicates the body's `## Parent` WikiLink |

### Provenance

| Field | Classification | Type | Values | Purpose |
|---|---|---|---|---|
| `origin_uri` | PROPERTY | text | URI / URL | Upstream source |
| `origin_last_path` | PROPERTY | text | POSIX path | Last known filesystem path (indexed EV only) |
| `canonicalsourceurl` | PROPERTY | text | URL | Canonical published URL |
| `capturetype` | PROPERTY | set | `import` / `clip` / `scan` / `web` / `note` | EV-only |
| `content_sha256` | PROPERTY | text | hex digest | Change-detection hash |
| `primarytopic` | PROPERTY | text | free | The one topic this record is primarily about |

### Timestamps

| Field | Classification | Type | Purpose |
|---|---|---|---|
| `lastprofiledat` | PROPERTY | date | Last profiling pass (ISO 8601) |
| `lastmirroredat` | PROPERTY | date | KN-only. Last mirror sync |
| `lastrunid` | PROPERTY | text | Most recent skill run that touched this record |

### Derived (mirror-computed; never authored)

| Field | Classification | Type | Purpose |
|---|---|---|---|
| `claim_backed` | DERIVED | set | KN-only. `yes` / `partial` / `no` — whether every `fact`/`inference` claim has resolved evidence |
| `evidencecount` | DERIVED | integer | KN-only. Count of `EV-...` WikiLinks/item-links in `## Evidence links` |
| `knowledge_link_state` | DERIVED | text | EV-only. Whether the EV has inbound KN references |
| `relation_gap_state` | DERIVED | text | KN-only. Whether expected RLs are missing |
| `mirror_state` | DERIVED | set | KN-only. `fresh` / `stale` |
| `indexed_risk_state` | DERIVED | text | EV-only. Whether an indexed file is at path or refresh risk |
| `automation_last_run_state` | PROPERTY | set | `ok` / `error` / `pending` — set by skills |

### Operational signals

| Field | Classification | Type | Purpose |
|---|---|---|---|
| `needs_ocr` | PROPERTY | boolean | EV-only. Set true when PDF has no extractable text |

## Relation type vocabulary

Closed set. Adding a type requires updating this document + the audit checks.

| Type | Meaning |
|---|---|
| `supports` | Source provides reasoning, evidence, or grounding for target |
| `contradicts` | Source challenges, refutes, or conflicts with target |
| `extends` | Source builds on, elaborates, or deepens target |
| `summarizes` | Source is a synthesis or compression of target |
| `references` | Source cites target (weakest edge; use sparingly) |
| `exemplifies` | Source is a concrete case or instance of target |
| `precedes` | Source is logically or temporally prior to target |
| `supersedes` | Source replaces target |

## Note templates

### Knowledge note (KN)

MultiMarkdown headers at the top (DEVONthink parses these natively). Body sections in this order:

```markdown
Title: Problem framing in local second-brain systems
Aliases: problem framing; local second-brain; KN-20260417-0021
Tags: pkim/knowledge; knowledge/type/synthesis; domain/tools; concept/second-brain
PKIM_ID: KN-20260417-0021
DocRole: knowledge
NoteType: synthesis
Review_State: approved
KnowledgeStatus: active
KnowledgeConfidence: medium

# Problem framing in local second-brain systems

## Summary

Short paragraph. What this note says.

## Claims

```yaml
- claim: "Local-first systems reduce sync overhead for personal knowledge work"
  type: inference
  confidence: medium
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
  contradicted_by: []
  note: "Two independent sources; consistent framing."
```

## Evidence links

- [Local-first software, Kleppmann et al](x-devonthink-item://EV-UUID)

## Related notes

- [[KN-20260417-0009|DEVONthink operating model]]
```

Structural rules:
- `Aliases` header carries both the display name(s) and the `PKIM_ID`, semicolon-separated.
- `PKIM_ID` is both an MMD header line and a component of `Aliases`.
- `## Evidence links` cites **cross-database** EV records via item links (`x-devonthink-item://UUID`). WikiLinks won't resolve across databases.
- `## Related notes` links to **same-database** KN/RL/CL records via WikiLinks (`[[PKIM_ID|Name]]`).
- The `## Claims` block is required when `KnowledgeStatus ∈ {reviewed, published}`. See [Claim block schema](#claim-block-schema) below.

### Relation note (RL)

```markdown
Title: Relation — problem framing supports local-first PKIM
PKIM_ID: RL-20260417-0004
DocRole: relation
Relation_Type: supports
Source_Item: x-devonthink-item://SOURCE-UUID
Target_Item: x-devonthink-item://TARGET-UUID
Review_State: approved
RelationStatus: accepted

# Why this relation exists

The source note frames the trade-off explicitly; the target note converts that into a durable design decision.

## Endpoints

- Source: [[KN-20260417-0021|Problem framing in local second-brain systems]]
- Target: [[KN-20260417-0050|Local-first PKIM operating principle]]

## Evidence

- [[EV-20260417-0007|Primary source title]]

## Interpretation

Optional; context, caveats, or conditions on this relation.
```

Non-negotiable contract:
- `PKIM_ID`, `DocRole=relation`, exactly one `Source_Item`, exactly one `Target_Item` (both as item links), exactly one `Relation_Type` from the closed vocabulary.
- `## Endpoints` body section is mandatory — two `[[PKIM_ID|Name]]` WikiLinks pointing to the same records the item links point to. The metadata pointers alone don't produce a DEVONthink-visible edge; the body WikiLinks do.
- `# Why this relation exists` prose rationale is mandatory. A relation note with no rationale is invalid.
- For `Relation_Type ∈ {supports, contradicts, supersedes}`: a `## Evidence` body section is required, with at least one `[[EV-...|Name]]` or `[[KN-...|Name]]` WikiLink.

### Claim record (CL)

Individual claim promoted out of a KN's `## Claims` block into its own record. Exists so a single claim can be tagged, cited, contradicted, and audited independently.

```markdown
Title: Local-first systems reduce sync overhead
PKIM_ID: CL-20260517-0001
DocRole: claim
ClaimType: inference
ClaimConfidence: medium
Review_State: approved
ParentKN_ID: KN-20260417-0021

# The claim

Local-first systems reduce sync overhead for personal knowledge work.

## Reasoning

Direct sync approaches require running consensus; local-first CRDTs merge lazily and let each device operate independently, which the sources describe as reducing operational overhead.

## Evidence

- [Local-first software, Kleppmann et al](x-devonthink-item://EV-UUID-A)
- [Riffle case study](x-devonthink-item://EV-UUID-B)

## Parent

- [[KN-20260417-0021|Problem framing in local second-brain systems]]

## Contradicted by

(none)
```

Rules:
- CLs are promoted from a KN when the claim needs individual addressability (querying, citing, contradicting, auditing).
- `ParentKN_ID` (INDEX-POINTER) duplicates the body's `## Parent` WikiLink.
- Evidence in `## Evidence` uses item links (cross-database).
- The KN's `## Claims` section, when its claims are promoted to CLs, becomes a bullet list of WikiLinks to those CLs.

## Claim block schema

Used inside a KN's `## Claims` section when claims stay inline (not promoted to CL records). Fenced YAML block:

```yaml
- claim: "Local-first systems reduce sync overhead for personal knowledge work"
  type: inference
  confidence: medium
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
    - "[[EV-20260418-0012|Riffle case study]]"
  contradicted_by: []
  note: "Two independent sources; consistent framing."
```

Fields:

| Field | Required when | Notes |
|---|---|---|
| `claim` | always | Single declarative sentence. Split compound claims. |
| `type` | always | `fact` / `inference` / `assumption` / `open-question` |
| `confidence` | always | `low` / `medium` / `high` |
| `evidence` | `type ∈ {fact, inference}` | List of item links or WikiLinks to EV/KN records. Empty list valid only for `assumption` / `open-question`. |
| `contradicted_by` | always (list, may be empty) | WikiLinks / item links to contradicting records or claims |
| `note` | optional | Prose context; preserved verbatim by the mirror |

Confidence ladder — what each band means *operationally*:

- **high**: Corroborated by ≥2 independent evidence records, no entries in `contradicted_by`. Safe to act on without re-review.
- **medium**: Supported by ≥1 evidence record, or a single strong source. Acceptable for `KnowledgeStatus=reviewed`; verify before promoting to `published`.
- **low**: Best current estimate but thin. Records with low-confidence claims should not move past `KnowledgeStatus=active` without review.

Confidence is not derived from type. An `assumption` may be held with `high` confidence; a `fact` may sit at `low` if the source is questionable.

## Contradiction handling

Three shapes, three responses:

### Within a KN — `contradicted_by` populated

The author has acknowledged a contradicting record. Rules:
- The contradicting record must appear in `contradicted_by`.
- A claim with non-empty `contradicted_by` cannot be `high` confidence.
- A `note` explaining the resolution (or its absence) is encouraged.

### Across KNs — shared evidence, opposing edges

Two KNs cite the same EV. One via an RL of `Relation_Type: supports`, the other via `contradicts`. The audit surfaces this as a corpus-level contradiction. Resolution is human-driven.

### Across relation notes — explicit `contradicts` RL

Already a first-class edge. The audit verifies:
- `## Evidence` body section is present (see RL contract).
- Neither endpoint is retired.

## Export mirror

Skills don't build the mirror as a separate artefact. `PKIM-Knowledge` is indexed against its on-disk root — that root *is* the portability surface. Every KN/RL/CL in the database is already a `.md` file on disk. External tooling reads from there.

The on-disk root uses YAML frontmatter equivalent to the MMD headers above; DEVONthink's own indexed-file handling maintains the equivalence. Filenames use the pattern `KN-YYYYMMDD-NNNN-<slug>.md` so records are identifiable outside the database.

## Validation rules

### Every record

- MMD header block separated from body by a blank line.
- `PKIM_ID` present.
- `Title`, `DocRole` headers present.
- `Aliases` includes the `PKIM_ID` value.
- Body is not empty.
- Every custom metadata field on the record has one of the three classifications (PROPERTY / INDEX-POINTER / DERIVED).

### KN

- If `KnowledgeStatus ∈ {reviewed, published}`: a `## Claims` section is present with at least one well-formed claim.
- Every `fact` / `inference` claim has at least one resolvable evidence WikiLink or item link.
- If `KnowledgeStatus=published`: `KnowledgeConfidence` is not `low`.
- No duplicate `claim` text within the same note.

### RL

- Exactly one `Source_Item`, `Target_Item`, `Relation_Type` from the closed vocabulary.
- `## Endpoints` body section with two `[[PKIM_ID|Name]]` WikiLinks matching the item links.
- Prose rationale under `# Why this relation exists` (≥ 1 sentence).
- If `Relation_Type ∈ {supports, contradicts, supersedes}`: `## Evidence` body section with at least one WikiLink.

### CL

- `ParentKN_ID` resolves to an existing KN.
- Body `## Parent` WikiLink matches `ParentKN_ID`.
- `fact` / `inference` claims have at least one resolvable evidence WikiLink/item link.

### Corpus

- No scalar metadata field on any record has a value that is another record's PKIM_ID unless the field is INDEX-POINTER (currently `Source_Item`, `Target_Item`, `ParentKN_ID`).
- Every WikiLink in a note body resolves to an existing record (dangling links surface in the audit).

## Anti-patterns

- YAML frontmatter as the canonical native-note header format — DEVONthink doesn't parse it into native properties. Use MMD headers in-database; YAML frontmatter is for the mirrored on-disk files.
- Scalar metadata fields whose value is another record's PKIM_ID and whose intent is to express a relationship — that's edge-in-metadata.
- Relation notes without `## Endpoints` WikiLinks — the metadata pointers alone don't produce a DEVONthink-visible edge.
- `contradicts` / `supports` / `supersedes` relations without `## Evidence`.
- Building relation semantics through tags rather than RL records.
- Encoding graph meaning in filenames.
- Giant metadata schemas where half the fields are always blank.
