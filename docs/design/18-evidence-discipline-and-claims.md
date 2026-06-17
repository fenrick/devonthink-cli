# Evidence Discipline And Claims

## Purpose

Define the claim schema, confidence ladder, contradiction-handling rules, and the claim-ledger artefact contract that together turn PKIM's knowledge notes from free-prose summaries into structured arguments. This doc is the canonical contract referenced by every Phase 1 work package in [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md).

It pairs with [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md): WikiLinks express relationships, the claim schema expresses the *reasoning* over those relationships.

## Why claims, not key points

A free-prose `## Key points` list rewards plausible-sounding writing. Every assertion has the same rhetorical weight regardless of evidence support, and there is no way to ask the system "what do I actually know vs. assume?". A structured claim block forces three explicit choices on every statement that survives review:

- **What kind of statement is this** — fact, inference, assumption, open question?
- **How much do you believe it** — low, medium, high confidence?
- **What supports it** — which evidence records, and is the relationship one of support or contradiction?

This is the minimum structure needed for an audit to detect zombie claims (claims whose supporting evidence has retired), contradictions across the corpus, and unfalsifiable assertions.

## Claim block schema

Every claim sits inside a fenced YAML block under the `## Claims` section of a knowledge note. The fenced form keeps the schema parseable by humans and by the export mirror while leaving the rest of the note prose-friendly.

```yaml
- claim: "Local-first systems reduce sync overhead for personal knowledge work"
  type: inference
  confidence: medium
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
    - "[[EV-20260418-0012|Riffle case study]]"
  contradicted_by: []
  note: "Inferred from two distinct sources; no contradicting evidence found."
```

### Required fields

| Field | Required when | Notes |
| --- | --- | --- |
| `claim` | always | A single declarative sentence. Avoid compound claims joined with "and" — split them. |
| `type` | always | One of: `fact`, `inference`, `assumption`, `open-question`. See vocabulary below. |
| `confidence` | always | One of: `low`, `medium`, `high`. See ladder below. |
| `evidence` | `type ∈ {fact, inference}` | List of WikiLinks in the `[[PKIM_ID|Name]]` form, targeting evidence records (`EV-…`) or upstream knowledge notes (`KN-…`). Empty list is valid only for `assumption` and `open-question`. |
| `contradicted_by` | always (list, may be empty) | WikiLinks to records or claims that contradict this one. The audit cross-references against the contradiction register. |
| `note` | optional | Short prose context. Not parsed; preserved verbatim by the mirror. |

### Claim type vocabulary

The vocabulary is closed. Adding a type requires an explicit schema change recorded in [00 Source Reconciliation](00-source-reconciliation.md).

| Type | Meaning | Evidence required |
| --- | --- | --- |
| `fact` | A directly observed or directly cited claim. The claim is what the evidence says, not an interpretation of it. | yes |
| `inference` | A conclusion drawn by the operator from one or more evidence records. The reasoning is the operator's; the support is the evidence. | yes |
| `assumption` | A working belief the operator is currently holding. Not yet supported by evidence; documented so it can be challenged later. | no |
| `open-question` | A claim the operator wants to be true or false but cannot currently answer. Tracked so it surfaces in audit and review. | no |

The discipline: every `assumption` and `open-question` is a flag that should eventually become a `fact`, an `inference`, or be retracted. A KN with too many `assumption` entries is a synthesis-debt signal.

### Confidence ladder

The ladder defines what each band *means operationally*, not what it sounds like:

| Band | Operational meaning |
| --- | --- |
| `high` | Corroborated by ≥2 independent evidence records, with no entries in `contradicted_by`. Safe to act on without re-review. |
| `medium` | Supported by ≥1 evidence record, or by a single source where the operator has additional context. Acceptable for `KnowledgeStatus=reviewed`; verify before promoting to `published`. |
| `low` | Best current estimate but evidence is thin, indirect, or contested. Records with low-confidence claims should not move past `KnowledgeStatus=active` without review. |

A claim's confidence is **not** derived from its `type`. An `assumption` may be held with `high` confidence ("I am confident this is what we'll find when we look"); a `fact` may sit at `low` confidence when the evidence quality is itself questionable.

### Validation rules (enforced by `pkim audit-discipline`)

1. The `## Claims` section is required on every knowledge note with `KnowledgeStatus ∈ {reviewed, published}`.
2. Each claim block must have `claim`, `type`, `confidence`, `contradicted_by` (possibly empty).
3. Claims of type `fact` or `inference` must have at least one `evidence` WikiLink.
4. Every WikiLink in `evidence` or `contradicted_by` must resolve to an existing PKIM record. Dangling references are flagged.
5. Claims must not duplicate the `claim` text within the same note (textual duplication is a signal of unintended forking; the audit flags it).

## Contradiction handling

Contradictions arrive in three shapes; each has a defined response.

### 1. Within a single KN — `contradicted_by` is populated

The author has acknowledged a contradicting source. Required actions:

- The contradicting record must be linked in `contradicted_by`.
- The `confidence` ladder applies: a claim with non-empty `contradicted_by` cannot be `high` confidence; the audit flags it if claimed.
- A short `note` explaining how the contradiction is resolved (or unresolved) is encouraged but not mandatory.

### 2. Across KNs citing overlapping evidence

The export mirror's audit (Phase 2) detects this: two KNs cite the same EV, but one classifies the citation as `supports` and the other as `contradicts` (via the edge class on the relation note connecting EV to KN). This is a **corpus-level contradiction**. Required actions:

- The audit writes a finding under pattern `corpus-contradiction` with the three involved records (EV + 2 KNs).
- A `contradiction-register.md` entry is created in `runs/<run-id>/`.
- Resolution is human-driven: one of the KNs is updated, both are flagged `needs-review`, or a new explanatory note is authored.

### 3. Across relation notes — `contradicts` RL exists

An explicit RL of `Relation_Type=contradicts` is already a first-class edge (see [08 Record And Note Specification](08-record-and-note-specification.md)). The audit's role here is to verify:

- The RL has the required `## Evidence` body section (audit pattern `missing-evidence-link`, already implemented in WP0.4).
- Neither endpoint is retired (audit pattern `zombie-edge`, already implemented).

## Claim ledger artefact

The **claim ledger** is the run-time artefact produced when `dt-build-claim-ledger` runs as Pass 3 of [Workflow 3 — Evidence to Knowledge](05-workflows.md). It is a single markdown file at `runs/<run-id>/claim-ledger.md` consumed by the subsequent note-authoring step.

### Contract

- **Location**: `runs/<run-id>/claim-ledger.md` where `<run-id>` matches the orchestrating run's manifest.
- **Lifetime**: persisted with the run; not authoritative once the KN is created. The KN's `## Claims` section is authoritative.
- **Format**: a single fenced YAML block of claim entries plus a brief prose preamble describing the EV set the ledger was built from.

### Example

```yaml
---
run_id: RUN-2026-05-17T14-10-00Z
source_evidence:
  - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
  - "[[EV-20260418-0012|Riffle case study]]"
target_note_type: synthesis
operator: claude
---

# Claim ledger — local-first synthesis

Built from 2 evidence records via Pass 3 of Workflow 3 (Triangulate).
Pass 3 identified 4 candidate claims; the operator accepted 3 and
downgraded 1 to an open question.

```yaml
- claim: "Local-first systems reduce sync overhead for personal knowledge work"
  type: inference
  confidence: medium
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
    - "[[EV-20260418-0012|Riffle case study]]"
  contradicted_by: []
  note: "Two independent sources; consistent framing."

- claim: "CRDT-backed editing eliminates conflict resolution UI"
  type: fact
  confidence: high
  evidence:
    - "[[EV-20260417-0007|Local-first software, Kleppmann et al]]"
  contradicted_by: []

- claim: "Local-first is operationally cheaper than server-first at small scale"
  type: open-question
  confidence: low
  evidence: []
  contradicted_by: []
  note: "Sources discuss cost qualitatively; no quantitative comparison found."
```
```

The ledger is then consumed by `dt-build-knowledge-note` (now claim-ledger-aware) which writes the KN's `## Claims` section verbatim from the accepted entries.

## Contradiction register

A separate persistent artefact at `runs/<run-id>/contradiction-register.md` produced by the mirror-side audit (Phase 2). Records every corpus-level contradiction with:

- The two KNs and the shared evidence.
- Date of detection.
- Whether the contradiction is `open`, `acknowledged` (both KNs link `contradicted_by`), or `resolved` (one KN retired or revised).

A growing contradiction register is a sign the discipline is working. An empty register on a mature corpus is suspicious, not a success.

## Skills that consume this contract

- **`dt-build-claim-ledger`** (new, WP1.4) — produces the claim ledger from an EV shortlist and writes the run artefact.
- **`dt-detect-contradictions`** (new, WP1.4) — mirror-side query, populates the contradiction register.
- **`dt-audit-claim-evidence`** (new, WP1.4) — per-KN audit: validates each claim's evidence WikiLinks resolve and the cited EVs are not retired.
- **`pkim audit-discipline`** (extended in WP1.bonus) — adds the `missing-claims` detector.

## Glossary

- **Claim** — a single declarative statement inside a KN's `## Claims` block, tagged with type, confidence, and evidence.
- **Claim ledger** — the run-artefact at `runs/<run-id>/claim-ledger.md` produced by Pass 3 of Workflow 3.
- **Confidence band** — one of `low`, `medium`, `high`; describes operational trust in a claim.
- **Contradiction register** — the persistent log at `runs/<run-id>/contradiction-register.md` tracking corpus-level contradictions.
- **Corpus contradiction** — two KNs citing the same EV with opposing edge classes; detected by the mirror audit, not by within-KN review.
- **Knowledge confidence** — a record-level field (`KnowledgeConfidence ∈ {low, medium, high}`) derived from the worst-case claim confidence on the KN.
- **Claim_Backed** — a derived (mirror-computed) field on each KN; values `yes` / `partial` / `no` based on whether claims have valid resolved evidence.

## Open items (track here, not in code comments)

- **Per-evidence weight**. The schema does not currently support claim-level weights per evidence record (e.g. "EV-A strongly supports; EV-B weakly supports"). Deferred until the mirror audit demonstrates a need. The current shape is sufficient for `Claim_Backed` and contradiction detection.
- **Inter-rater reliability**. When two operators (human or LLM) build ledgers from the same EV set, do they converge on the same claims? Not measured yet. Consider a fixture corpus + double-build comparison once Phase 1 lands.
- **Migration cadence**. Existing KNs with free-prose `## Key points` need conversion. WP1.2's migration note flips them all to `KnowledgeStatus=needs-review`; the actual rewrite is refactor-on-touch rather than a one-shot migration.
