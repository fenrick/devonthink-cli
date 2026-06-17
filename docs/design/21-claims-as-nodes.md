# Claims As Nodes

## Purpose

Promote claims from embedded YAML inside a KN's `## Claims` block to first-class graph records in DEVONthink. Each claim becomes its own note (`CL-…`) with tags, custom metadata, and outbound WikiLink edges. This brief defines the record class, tag vocabulary, edge model, body shape, migration path, and the impact on existing workflows and skills.

This doc extends [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) — the claim schema (type, confidence, evidence, contradicted_by) is unchanged. What changes is the *carrier*: a claim is no longer a YAML map inside a KN; it is a record in the graph.

It also closes a gap with [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md): YAML-in-KN behaves like metadata-flavoured text — invisible to DT navigation, parsed by regex, not traversable. Nodes behave like the graph already does.

## Why nodes, not YAML

The YAML block in `## Claims` was a parser-friendly mirror representation. It is not how the graph actually behaves:

- **DT navigation is tag-driven.** Memory rule `feedback_note_tags_aliases`: "everything needs tags; DT navigation depends on tags." YAML strings carry no tags, do not appear in tag-filtered lists, cannot be browsed by `type:fact` or `confidence:low`.
- **Contradiction detection wants graph traversal.** With nodes, the mirror query is `SELECT … FROM edges WHERE edge_type='contradicts'`. With YAML, it is regex over note bodies.
- **Review state is per-claim, not per-note.** A KN with 8 claims may want 6 approved and 2 `needs-human`. Per-note `Review_State` cannot express that; per-record state can.
- **Audit passes need an addressable target.** "Re-examine claim X" today means "open the KN and find the entry." With nodes, the operator can be sent a single record link.
- **Supersession propagation already exists for records.** When an EV retires, propagation walks edges. Claim records inherit that machinery for free; YAML claims need a bespoke text-rewrite path.

The cost is record-count inflation. A typical KN of 6–8 claims becomes 1 KN + 6–8 CL records. The DT corpus grows ~6× in record count per literature note. That is real — see Open items below — but the architectural payoff (graph-native reasoning, tag-driven discovery, granular review) justifies it.

## Record class: `CL-…`

### Identity

- **PKIM_ID format**: `CL-YYYYMMDD-NNNN` (matches existing EV/KN/RL pattern).
- **DT record type**: `markdown` (same as KN/RL).
- **DocRole**: `claim` (new value, added to the closed vocabulary in [08](08-record-and-note-specification.md)).
- **Location convention**: `/Notes/Claims` group, or `/Notes/Claims/<parent-KN-name>` when grouping by parent KN is useful. The mirror does not depend on location.

### Required custom metadata

| Field | Values | Source of truth |
| --- | --- | --- |
| `PKIM_ID` | `CL-YYYYMMDD-NNNN` | minted by `pkim mint-id` |
| `DocRole` | `claim` | set on creation |
| `ClaimType` | `fact` / `inference` / `assumption` / `open-question` | from claim schema |
| `ClaimConfidence` | `low` / `medium` / `high` | from claim schema |
| `Review_State` | `inbox` / `profiled` / `needs-human` / `approved` / `filed` / `mirrored` | independent of parent KN |
| `ParentKN_ID` | a `KN-…` value | the KN this claim belongs to (INDEX-POINTER; the graph edge is authoritative) |

`ParentKN_ID` is an INDEX-POINTER, not a graph relation. The authoritative edge is the `claim-of` WikiLink in the body (see Edges below). The metadata copy exists only for fast filtering inside DT.

### Required tags

Tags are how DT navigates. A CL record is searchable only to the extent its tags reflect both **what kind of claim it is** (structural) and **what the claim is about** (topical). Both layers are mandatory. The PKIM_ID itself goes into the DT alias field (existing convention from `feedback_note_tags_aliases`).

**Structural tags** (always present, vocabulary closed):

- `pkim/claim` — class tag, mirrors `DocRole`. Lets a Smart Group select every claim record in the database.
- `claim/type/<value>` — one of `claim/type/fact`, `claim/type/inference`, `claim/type/assumption`, `claim/type/open-question`.
- `claim/confidence/<value>` — one of `claim/confidence/low`, `claim/confidence/medium`, `claim/confidence/high`.
- `claim/state/<value>` — mirrors `Review_State` for browsing (`claim/state/approved`, `claim/state/needs-human`, etc.).

**Topical tags** (always present, vocabulary open but shared across the corpus):

Every CL must carry enough topical tags that someone searching for the *subject* of the claim — not the claim itself — would find it. The minimum set is one tag per topical axis below; more is fine. All topical tags are inherited from (and must match) the parent KN's topical tag set, so a search that surfaces the KN also surfaces every claim that belongs to it.

| Axis | Tag namespace | Example | When required |
| --- | --- | --- | --- |
| Domain | `domain/<area>` | `domain/digital-transformation`, `domain/enterprise-architecture` | Always: the broad area the claim sits in. Drives "all my notes about X" navigation. |
| Concept | `concept/<thing>` | `concept/composable-enterprise`, `concept/microservices`, `concept/api-security` | Always: the named concept the claim is *about*. A claim with no concept tag is structurally suspicious. |
| Entity | `entity/<name>` | `entity/mulesoft`, `entity/gartner`, `entity/aws` | When the claim names a specific organisation, product, person, or place. Drives "what does the corpus say about X" navigation. |
| Source class | `source/<kind>` | `source/vendor-research`, `source/industry-analyst`, `source/peer-reviewed`, `source/blog-post` | Always: lets the operator filter low-confidence claims to vendor-sourced ones, etc. Inherited from the parent EV's classification. |
| Time | `year/<YYYY>` or `period/<label>` | `year/2021`, `period/post-pandemic` | When the claim is temporally bounded (most empirical claims are). Lets searches scope to a period. |
| Method (optional) | `method/<approach>` | `method/case-study`, `method/survey`, `method/benchmark` | When the cited evidence has a specific methodological shape worth surfacing. |

**Inheritance rules.**

- Domain, concept, and entity tags propagate from the parent KN. A claim cannot have a topical tag the parent KN does not also have — adding a new topical axis is a parent-KN edit, not a claim edit. This keeps the tag vocabulary coherent and makes "find every claim about X" symmetric with "find every KN about X."
- Source-class tags propagate from the cited EV records, not the parent KN. If a claim cites two EVs of different source classes, it carries both tags.
- Year/period tags follow the claim's *subject*, not the date the claim was authored. A claim about MuleSoft's 2021 framing carries `year/2021` even if authored in 2026.

**Tag-vocabulary discipline.**

- Tag values are kebab-case, lowercase. `concept/composable-enterprise` not `Concept/Composable Enterprise`.
- The concept vocabulary is the same one used on KN records. A new concept tag introduces a corpus-wide vocabulary entry and should be added deliberately (operator pause; not a casual mint).
- The audit emits `unknown-tag-namespace` if a CL has a tag outside the namespaces listed above; this catches typos like `concepts/foo` or `topic/bar`.

**Worked example.** For `CL-20260517-0001` ("Composable enterprise is one of MuleSoft's eight named trends"):

```
pkim/claim
claim/type/fact
claim/confidence/high
claim/state/approved
domain/digital-transformation
domain/enterprise-architecture
concept/composable-enterprise
concept/api-led-connectivity
entity/mulesoft
source/vendor-research
year/2021
```

A search for `concept/composable-enterprise` now surfaces the parent KN, every claim about that concept across the corpus, and (later) any RL records linking the concept to neighbouring concepts. A search for `entity/mulesoft AND claim/confidence/low` surfaces every shaky claim grounded in MuleSoft material — the exact slice an audit pass needs.

### Body shape (MMD)

A CL body is more than a one-line statement; it is a small, self-contained argument the operator can re-read in six months and understand without opening the parent KN or the source EV. Every CL has the same five sections, and the prose inside each section is what makes the record useful as a graph node rather than a record-shaped tag.

| Section | Purpose | What goes in it |
| --- | --- | --- |
| `## Statement` | The claim as one declarative sentence, followed by 2–4 sentences of unpacking. | Restate the claim crisply; then explain what it means, what it does *not* mean, and any boundary conditions. This is where a future reader recovers the operator's intent. |
| `## Reasoning` | Why the operator believes this, given the evidence. | For `fact`: a brief paragraph quoting or paraphrasing the supporting passage(s) and noting where in the source they live. For `inference`: the chain from evidence → conclusion, including any unstated assumption that bridges them. For `assumption`: the working belief and what would change if it turned out to be false. For `open-question`: what makes this answerable in principle but unanswered now. |
| `## Evidence` | Machine-readable citation list. | One bullet per WikiLink (`[[EV-…|Name]]` or `[[KN-…|Name]]`), with a short trailing phrase noting the role (`— direct support`, `— corroborates`, `— context only`). The mirror parses this section verbatim; do not editorialise here. |
| `## Parent` | The KN this claim belongs to. | One WikiLink. Optional one-liner if the claim's relationship to the parent needs elaboration (e.g. "narrows claim 2 in the parent"). |
| `## Contradicted by` | Records that argue against this claim. | Bullet list of WikiLinks, each with a one-sentence summary of *how* the contradiction lands. Empty `_None._` is valid; a non-empty list with `ClaimConfidence=high` is audit-blocked. |

A worked example for the `composable-enterprise` claim:

```markdown
---
title: "Composable enterprise is one of MuleSoft's eight named trends"
PKIM_ID: CL-20260517-0001
DocRole: claim
ClaimType: fact
ClaimConfidence: high
Review_State: approved
ParentKN_ID: KN-20260517-0002
---

# Composable enterprise is one of MuleSoft's eight named trends

## Statement

MuleSoft names "composable enterprise" — composing business capabilities
from existing APIs rather than building applications top-down — as one of
eight digital-transformation trends shaping 2021. This is a claim about
how the source classifies the trend, not a claim about whether the
strategy is correct or widely adopted; those are separate inferences
captured in sibling claims.

## Reasoning

The source's executive summary explicitly enumerates eight trends and
places composable enterprise first. The framing is presented as a
strategic posture for IT leaders rather than a tooling recommendation,
and the report dedicates a section header and three paragraphs to
unpacking what "composable" means in practice. Because the claim is
about what the source *says*, not about whether the source is right,
confidence is `high` despite the single-source citation.

## Evidence

- [[EV-20260517-0001|Top 8 digital transformation trends shaping 2021]] — direct support (executive summary, opening list and "Composable enterprise" section)

## Parent

- [[KN-20260517-0002|MuleSoft 2021 digital transformation trends]] (claim-of)

This is the framing claim that anchors the more interpretive sibling
claims about microservices, API security, and democratisation.

## Contradicted by

_None._
```

The same skeleton applies to non-`fact` claims, but the `## Reasoning` section carries different weight. A contrasting `inference` example:

```markdown
## Statement

The democratisation-of-innovation trend is presented by MuleSoft as an
IT-enablement problem (self-serve APIs for line-of-business users)
rather than as a governance problem (controlling who can ship what).
This framing is a vendor-positioning choice; other corpus sources are
likely to reframe it around governance and risk.

## Reasoning

The report's section on democratisation focuses entirely on enablement
mechanics: API gateways, low-code surfaces, and developer experience.
Risk, audit, change management, and approval workflows do not appear in
the section. MuleSoft's product line addresses the enablement framing
specifically, which is the reason for the low-confidence rating: the
framing is consistent with vendor incentive, so independent
corroboration is needed before raising confidence. The claim is recorded
now so a later audit pass surfaces it when a Capgemini or Gartner EV
lands in the corpus.

## Evidence

- [[EV-20260517-0001|Top 8 digital transformation trends shaping 2021]] — direct support (democratisation section, paragraphs 1–3)

## Parent

- [[KN-20260517-0002|MuleSoft 2021 digital transformation trends]] (claim-of)

## Contradicted by

_None recorded yet; expected once governance-framed sources are added._
```

And an `open-question` (no `## Evidence` required):

```markdown
## Statement

The "average enterprise runs 900 applications" figure cited in the
source generalises beyond MuleSoft's own customer base. The number is
load-bearing for the API-security trend's framing; if it is a
self-selecting figure, the trend's stated urgency softens
significantly.

## Reasoning

The source attributes the 900-applications figure to MuleSoft's
"Connectivity Benchmark Report" without referencing the sampling
method, the industry mix, or the company-size distribution. Industry
analyst figures (Gartner, IDC) typically report a wider range with
explicit segment cuts. Until one of those lands in the corpus, the
honest answer is that this figure cannot be verified — recording it as
an open question keeps it visible without forcing a premature
confidence label.

## Evidence

_None until a corroborating industry source is filed._

## Parent

- [[KN-20260517-0002|MuleSoft 2021 digital transformation trends]] (claim-of)

## Contradicted by

_None._
```

The body is the canonical surface for human reading inside DT. The mirror parses sections (`## Evidence`, `## Contradicted by`, `## Parent`) the same way it parses RL bodies today — see [17 Offline-First Note Construction](17-offline-first-note-construction.md). The `## Statement` and `## Reasoning` sections are prose: the mirror preserves them verbatim but does not index them as graph data.

## Edge model

Each CL record participates in four edge classes:

| Edge | From → To | Carrier | Meaning |
| --- | --- | --- | --- |
| `claim-of` | CL → KN | WikiLink in `## Parent` section | this claim belongs to that KN |
| `cites` | CL → EV (or KN) | WikiLink in `## Evidence` section | this evidence supports the claim |
| `contradicts` | CL → CL (or CL → KN/EV) | WikiLink in `## Contradicted by` section | the linked record contradicts this claim |
| `supports` | CL → CL | WikiLink in `## Supported by` section (optional) | one claim corroborates another |

Notes:

- The reverse edge `has-claim` (KN → CL) is derived by the mirror from `claim-of`; it does not need a body entry on the KN. The KN's body still gets a `## Claims` section, but that section is now a **list of WikiLinks to CL records**, not a YAML block:

  ```markdown
  ## Claims

  - [[CL-20260517-0001|Composable enterprise is one of MuleSoft's eight named trends]] — fact / high
  - [[CL-20260517-0002|Microservices appears as a discrete trend distinct from composable enterprise]] — fact / high
  - …
  ```

  The trailing `— type / confidence` is human-reading sugar; the mirror reads metadata from the CL record, not from the KN's bullet text.

- `contradicts` is bidirectional in the mirror graph. A CL flagged as contradicting another CL automatically populates the reverse view.

- `supports` is a new optional edge type. It is not the same as `cites` (which targets EV). `supports` lets two claims corroborate each other inside the synthesis graph — useful when one KN's `inference` is grounded in another KN's `fact`.

## Mirror graph impact

The mirror schema (`src/pkim/mirror/graph.py`) needs:

- **New node class** `claim` in the `nodes` table — already supported by a string `class` column; no schema change needed if `class` is open.
- **Edge types** `claim-of`, `cites`, `contradicts`, `supports` — already supported by string `edge_type`.
- **New audit detectors** for the CL class:
  - `orphan-claim` — CL with no `claim-of` edge.
  - `unbacked-claim` — CL with `ClaimType ∈ {fact, inference}` and no `cites` edge.
  - `dangling-contradiction` — CL with `contradicts` to a retired record.
  - `mismatched-confidence` — CL with `ClaimConfidence=high` but `contradicts` is non-empty (existing rule from doc 18, applied per-record now).
- **`Claim_Backed` derivation moves to a graph query** rather than YAML parse: a KN is `Claim_Backed=yes` if every `claim-of` predecessor has resolved `cites` edges and no dangling contradictions.

## Workflow impact

### Workflow 3 — Evidence to Knowledge

Pass 3 (Triangulate) changes shape:

- The `claim-ledger.md` run-artefact remains as a **scratchpad**, not authoritative. It still uses the YAML schema for readability during ledger construction.
- After the ledger is accepted, `dt-build-claim-ledger` now writes **one CL record per accepted entry** instead of injecting YAML into a KN's body.
- `dt-build-knowledge-note` becomes claim-record-aware: it creates the KN with a `## Claims` section listing WikiLinks to the CL records (not YAML).

The operator-facing flow is unchanged: build a ledger, accept it, the KN appears. The plumbing differs.

### Workflow 7 — Periodic Claim Audit

Becomes a pure mirror-graph traversal. No body parsing. Audit detectors enumerated above run as SQL.

## Skill impact

| Skill | Change |
| --- | --- |
| `dt-build-claim-ledger` | Output target changes from YAML-in-KN to N×CL records + WikiLink list in KN. |
| `dt-build-knowledge-note` | Consumes CL list rather than ledger YAML; writes `## Claims` as bullet list of WikiLinks. |
| `dt-detect-contradictions` | Pure mirror SQL; no body parsing. |
| `dt-audit-claim-evidence` | Pure mirror SQL; checks each CL's `cites` edges resolve and EVs are not retired. |
| `dt-sweep-zombie-knowledge` | Includes orphan-CL and unbacked-CL detectors. |

## Tooling impact (`pkim` CLI / `dt-pkim-mcp`)

New surface:

- `pkim mint-id --class CL` — already works if the minter is class-agnostic; verify.
- `pkim create-claim --parent <KN_ID> --type <t> --confidence <c> --evidence <EV_ID> [--evidence <EV_ID>] …` — new command. Mints `CL-…`, creates the record under `/Notes/Claims`, sets tags + metadata + alias, writes the body, adds the WikiLink bullet to the parent KN.
- `pkim apply-metadata` — already field-agnostic; just needs `ClaimType`, `ClaimConfidence`, `ParentKN_ID` added to `ALLOWED_FIELDS` and `_INTERNAL_KEYS` (same shape as the WP1.4 patch).
- `pkim audit-discipline` — new detectors as above.

The MCP tool surface gets a `create_claim` tool wrapping the CLI.

## Migration from YAML claims

Current state: KNs exist with YAML `## Claims` blocks. After this brief lands and tooling exists, a one-shot migration converts them:

1. `pkim migrate-claims-to-nodes --database PKIM-Knowledge --dry-run` enumerates every KN with a parsable `## Claims` YAML block, prints the claims that would be promoted, and writes a plan to `runs/`.
2. `pkim migrate-claims-to-nodes --database PKIM-Knowledge --execute` mints one CL per entry, sets tags + metadata + alias, writes the CL body, rewrites the KN's `## Claims` section as a bullet list of WikiLinks, and records the mapping in `runs/<run-id>/claim-migration.json`.
3. Validation: audit-discipline must run clean on the database after migration. The original YAML is preserved in `runs/<run-id>/claim-migration-backup/` for rollback.

KN-20260517-0002 (the MuleSoft note written today) is a natural pilot — 6 fact/inference claims, all citing one EV; small enough to verify the migration end-to-end before bulk runs.

## Cross-database links

DEVONthink's WikiLink alias index is **per-database**. A `[[PKIM_ID|Name]]` link in a PKIM-Knowledge record cannot resolve a target that lives in PKIM-Pilot (or any other database) — the alias simply isn't in the destination's index. This is a DT behaviour, not a PKIM design choice.

The two-form link rule therefore extends with a database-scope axis:

| Same database as the source | Different database from the source |
| --- | --- |
| `[[PKIM_ID|Name]]` WikiLink — DT resolves via the alias index | `[Name](x-devonthink-item://UUID)` markdown link — DT resolves via the absolute item URL |

In practice this means evidence citations from `KN-…`/`CL-…` records (PKIM-Knowledge) to `EV-…` records (PKIM-Pilot or PKIM-Evidence-*) use the item-link form. Cross-claim citations within PKIM-Knowledge (e.g. one CL referencing a sibling CL in its `## Reasoning` prose) stay as WikiLinks.

The mirror's body parser handles both forms:

- `iter_wikilinks` extracts `[[PKIM_ID|Name]]` links and emits edges directly using the resolved PKIM_ID.
- `iter_item_links` extracts `[Name](x-devonthink-item://UUID)` links and emits edges after the ingest builds a UUID→PKIM_ID index from the record set. UUIDs that don't resolve are surfaced by the `dangling-item-link` audit detector (which re-reads the body via a `body_provider` callable).

`create-claim` chooses the form automatically: when the cited record's `database_name` differs from the parent KN's database, the renderer emits the item-link form; otherwise the WikiLink form.

## What DT reads from MMD headers (verified)

DEVONthink 4's MMD parser **only** populates the three native record properties from a markdown file's MMD header: `Title`, `Aliases`, and `Tags`. Custom-metadata fields (`PKIM_ID`, `DocRole`, `ClaimType`, `ClaimConfidence`, `ParentKN_ID`, `Review_State`, `KnowledgeStatus`, `KnowledgeConfidence`, etc.) are **not** read from MMD headers regardless of which spelling is used (`PKIM_ID:`, `mdpkim_id:`, etc.).

Empirically verified 2026-05-18 with a test markdown file carrying both human-form (`PKIM_ID:`) and internal-form (`mdpkim_id:`) fields; DT's resulting `custom_metadata` was `{}`. Behaviour confirmed by DEVONtechnologies staff on the Discourse forum ("no, only properties") with a feature request logged but not yet shipped.

Consequence: `create_indexed_markdown_record` is responsible only for getting the file on disk and a DT record reference back; the caller must follow up with `set_custom_metadata`, `set_tags`, and `set_aliases` for every authored field. DT also auto-derives tags from MMD-header *values* (e.g. `ClaimType: fact` produces tag `fact`); `set_tags` is a full replace, so it overwrites the auto-tag noise with the canonical hierarchical set.

## Indexed-mode for PKIM-Knowledge

PKIM-Knowledge's `/Archive/`, `/Notes/`, `/Operations/`, and `/Templates/` groups are indexed against an on-disk folder rather than imported into the database bundle. Markdown bodies live as files on disk; DT manages custom metadata, tags, aliases, and group structure per record. WikiLinks resolve via DT's alias index exactly as for imported records.

The indexed root is configured in code:

```python
from pkim.runtime import pkim_knowledge_indexed_root

# Default: $HOME/Library/Mobile Documents/com~apple~CloudDocs/PKIM/Knowledge
# Override:  PKIM_KNOWLEDGE_INDEXED_ROOT environment variable
root = pkim_knowledge_indexed_root()
```

Helpers `pkim_knowledge_notes_root()` and `pkim_knowledge_claims_root()` compose against the root.

Indexed-mode implications for the CL workflow:

- **Body edits go through the filesystem.** `Read` / `Edit` / `Write` against `<root>/Notes/Claims/<filename>.md` is the canonical edit path; bridge `set_body` calls are still possible but redundant.
- **Metadata, tags, aliases still go through the bridge.** Custom metadata is per-record DT state, not body content.
- **Group = folder.** Filing a CL means writing it to `<root>/Notes/Claims/`. No separate `move_record` step.
- **Two-way sync risk.** If a body is edited on disk (e.g. operator changes `Review_State: approved` → `Review_State: needs-human` in the MMD header), DT's custom metadata doesn't auto-update. The `pkim sync-metadata-from-frontmatter` command (deferred) closes this gap by reading the file's MMD header and applying it to DT's custom metadata.

## Open items

- **Record-count inflation.** A KN with 8 claims produces 9 records (1 KN + 8 CL). Across ~200 mature KNs that is ~1,800 records. DT handles this fine (the corpora today are larger), but list-views in DT need a smart-group preset (`pkim/claim` tag) so claims don't visually dominate the navigation pane. Add `/Smart Groups/Claims` and `/Smart Groups/Knowledge (claims-hidden)` as part of this work.
- **`supports` vs `cites` distinction.** Today `evidence` targets EV. With CL records, a fact-claim from KN-A can be the support for an inference-claim in KN-B. Should KN-B's CL cite KN-A's CL via `supports`, or via `cites` (treating the source CL as evidence)? Recommend `supports` (preserves the EV vs KN distinction in the graph), but watch how it feels in practice.
- **Claim deduplication.** When two operators (or two LLM runs) generate near-identical claims from the same EV set, we don't want two CL records for the same statement. The mirror should flag textual near-duplicates within the same parent KN (audit detector `duplicate-claim`). Cross-KN duplicates are not a bug — they are corroboration.
- **Confidence rollup to KN.** `KnowledgeConfidence` on a KN should still be derived (worst-case ladder across child CLs), but now derivation runs over the mirror graph rather than YAML parse. Verify the existing `apply_claim_backed` writeback machinery generalises.
- **Body parsing strictness.** CL bodies use Markdown section headers (`## Evidence`, `## Contradicted by`) the same way RL bodies do. Reuse the RL body parser; do not invent a third parser.

## Acceptance criteria for the work that follows this brief

1. `CL-…` records exist as a recognised DocRole; `pkim apply-metadata` accepts the new fields; tags are registered in the canonical vocabulary.
2. `pkim create-claim` mints + writes + tags + aliases a CL record and links it to the parent KN in one call.
3. Mirror audits emit `orphan-claim`, `unbacked-claim`, `dangling-contradiction`, `mismatched-confidence`, `duplicate-claim` findings.
4. `Claim_Backed` derivation works from the mirror graph (no YAML parsing).
5. `migrate-claims-to-nodes` converts KN-20260517-0002 cleanly (8 CL records, KN body rewritten, audit clean).
6. `dt-build-claim-ledger` and `dt-build-knowledge-note` produce CL-as-nodes output by default; YAML-in-body becomes a fallback path tagged for removal.
7. Smart Groups `/Smart Groups/Claims` and `/Smart Groups/Knowledge (claims-hidden)` exist in the canonical DT setup.
8. Doc 18 gets an "implementation note" pointing here for the carrier format; doc 19 (uplift plan) gets a Phase 5 row tracking this work.

## Relationship to existing design docs

- **[08 Record And Note Specification](08-record-and-note-specification.md)** — adds `claim` to `DocRole` vocabulary, adds the CL section spec.
- **[15 Supersession And Retirement Policy](15-supersession-and-retirement-policy.md)** — CL records participate in supersession propagation via their `cites` edges; same machinery as KN.
- **[18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md)** — schema unchanged; carrier moves from YAML-in-KN to CL records.
- **[19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md)** — this brief is a direct application: claims belong in the graph, not in YAML inside a record body.
- **[20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md)** — `create_claim` is a new MCP tool; no architectural change.

The next concrete step after this brief is approved is a Phase 5 entry in [19](19-synthesis-uplift-plan.md) with WPs covering: DocRole + tag registration, `create-claim` CLI + MCP tool, mirror audits, migration command, pilot migration of KN-20260517-0002, then bulk migration.
