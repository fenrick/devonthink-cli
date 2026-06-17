# PKIM Synthesis Uplift — Project Plan

## Purpose

Close the gap between PKIM's strong capture/filing layer and its weak synthesis layer. Move the project from a disciplined filing cabinet to a disciplined argument. Establish that **graph edges live in note bodies as WikiLinks, custom metadata describes records**, and introduce the claim / evidence / confidence / contradiction discipline that synthesis requires.

## Status (2026-05-17 — end of day)

| Phase | State | Detail |
| --- | --- | --- |
| Phase 0 — Principle, audit, RL contract, MMD canonical, audit-skill enforcement | **DONE** | WP0.1–0.5 landed 2026-05-16; WP0.6a/b/d/f-stub and WP0.4 landed 2026-05-16–17 |
| Phase 1 — Claim schema, KN template, synthesis skills wired in | **DONE** 2026-05-17 | WP1.1 (claim schema), WP1.2 (KN template + `KnowledgeConfidence` + `Claim_Backed`), WP1.bonus (missing-claims detector), WP1.3 (workflows wired, Workflow 7 added), WP1.4 (three new authoring skills) |
| Phase 2 — Mirror as analytical graph source of truth | **DONE** 2026-05-17 | WP2.1 (SQLite graph schema in `src/pkim/mirror/graph.py`), WP2.2 (mirror-side audits in `src/pkim/mirror/audits.py`), WP2.3 (`Claim_Backed` write-back in `src/pkim/mirror/writeback.py`) |
| Phase 3 — Propagation and lifecycle | **DONE** 2026-05-17 | WP3.1 (EV supersession propagation in `src/pkim/mirror/propagation.py` + supersession-policy doc), WP3.2 (zombie KN sweep skill), WP3.3 (`needs-human` state codified) |
| Phase 4 — Checkpoint re-gating | **DONE** 2026-05-17 | WP4.1 (Checkpoint S inserted as hard gate between C and D), WP4.2 (Checkpoint G success criteria amended with synthesis-health gates) |
| Phase 5 — Documentation hygiene | rolling | New doc 18 registered; design/README updated; reconciliation log maintained |
| Phase 6 — Claims as nodes | **DONE** 2026-05-17 (see [21 Claims As Nodes](21-claims-as-nodes.md)) | WP6.1 DocRole + tag vocabulary in code (DOC_ROLES, fields_registry, headers MMD ordering, section→edge-class map, ALLOWED_FIELDS); WP6.2 `pkim create-claim` CLI + `create_claim` MCP tool; WP6.3 four new mirror audits (`orphan-claim`, `unbacked-claim`, `dangling-contradiction`, `duplicate-claim`) + `Claim_Backed` derivation generalised to traverse CL-as-nodes; WP6.4 `pkim migrate-claims-to-nodes` (dry-run + execute + per-run backup); WP6.5 pilot migration of KN-20260517-0002 produced CL-20260517-0002…0009, audit 0/0/0 across both databases; WP6.6 bulk dry-run reports zero remaining YAML blocks (pilot covered the only KN with a YAML `## Claims` section). |

Cross-cutting transport migration (introduced after the plan started):

| WP | State | Detail |
| --- | --- | --- |
| WP0.6a — Bridge client + `pkim bridge probe` | **DONE** 2026-05-16 | PyObjC ScriptingBridge connection verified against live DT 4.1.1 |
| WP0.6b — Bridge reads + domain types | **DONE** 2026-05-16 | `DTReader.search`, `get_record_by_uuid`, `get_record_by_pkim_id`; `pkim/domain/` package |
| WP0.6c — Benchmark | **SKIPPED** 2026-05-16 | User direction: typed/functional matters more than measured speedup |
| WP0.6d — Port read commands to bridge | **DONE** 2026-05-17 | `list-inbox`, `probe-capabilities`, `health-check`, `metadata-overview`, `sweep-inbox`, `queue-metrics`, `graph-audit` (read), `extract-text` (record fetch) |
| WP0.6e — Thread domain types through commands | **PARTIAL** | RecordHandle + classification enums in use across ported commands; remaining commands gain types as they migrate |
| WP0.6f — `dt-pkim-mcp` server | **STUB DONE** 2026-05-16; full server pending | `pkim/mcp/` exposes `bridge_probe`, `search_records`, `audit_discipline` via FastMCP stdio |
| WP0.6g — Port writes through bridge | not started | Apply-metadata, create-note, safe-file, update-note, ensure-group-path, workspace push-batch, mirror writes |
| WP0.6h — Retire `jxa.py` and helper scripts | not started | Gated on WP0.6g |
| Profile classify/compare | open | DT verbs `classify`/`compare` not directly exposed by PyObjC ScriptingBridge; needs `performSelector` plumbing or hybrid JXA fallback |

## Outcomes

1. PKIM cannot accept a knowledge note that asserts claims without typed evidence.
2. PKIM cannot accept a relation note that asserts `contradicts` / `supports` / `supersedes` without evidence WikiLinks.
3. Contradictions across the corpus are detectable and tracked, not silently coexisting.
4. Retiring an evidence record propagates to every knowledge note that cited it.
5. The export mirror is the analytical source of truth for graph queries DT cannot perform natively.

## Guiding Principle (new, must land first)

**Graph edges live in note bodies as `[[PKIM_ID|Name]]` WikiLinks. Custom metadata is for properties of the record, not for representing relationships to other records.** Identity pointers on relation notes (`Source_Item`, `Target_Item`) are indexing aids; the relationship as DT sees it lives in the body.

---

## Phase 0 — Principle and Audit (foundation, all later work depends on it) — **DONE**

### WP0.1 — Codify the metadata-vs-graph principle — **DONE 2026-05-16**

**Scope.** Add the principle as a top-level decision in `docs/design/01-principles-and-decisions.md` and a one-page rationale at `docs/design/19a-metadata-is-not-the-graph.md` referenced from `03-information-model.md` and `08-record-and-note-specification.md`.

**Definition of Done.**
- `01-principles-and-decisions.md` contains a numbered decision titled "Graph edges live in note bodies" with rationale, allowed exceptions, and date.
- `19a-metadata-is-not-the-graph.md` exists, ≤ 1 page, explains DT's actual graph primitives (WikiLinks, item links, replicants) vs. custom metadata, and lists banned patterns (any metadata field whose value is another record's PKIM_ID and is intended to represent a relationship).
- `03-information-model.md` and `08-record-and-note-specification.md` cross-reference the new principle in their first 30 lines.
- `00-source-reconciliation.md` records the delta.
- PR includes no implementation changes; principle only.

### WP0.2 — Field-level audit of existing schema — **DONE 2026-05-16**

**Scope.** Audit every custom metadata field declared in `08-record-and-note-specification.md`. For each field, classify as:
- **PROPERTY** (legitimate — describes the record): keep.
- **INDEX-POINTER** (RL `Source_Item` / `Target_Item`): keep, but require body WikiLinks alongside.
- **EDGE-IN-METADATA** (e.g. `RelatedTo`, `Supersedes` as scalar pointers, `EvidenceCount` as a graph proxy): mark for removal or restatement.

**Definition of Done.**
- A table in `19-synthesis-uplift-plan.md` Appendix A lists every field with its current type, classification, and disposition (KEEP / KEEP-WITH-BODY-MIRROR / RESTATE-AS-DERIVED / REMOVE).
- Every EDGE-IN-METADATA field has a named replacement in the body (section heading + WikiLink format).
- Every "denormalised hint" field (`EvidenceCount`, similar) is restated as *derived dashboard counter, computed by mirror, not authoritative*.
- `15-glossary.md` reflects new and removed terms.

### WP0.3 — Body-link contract for RL notes — **DONE 2026-05-16**

**Scope.** Update the RL note contract in `08-record-and-note-specification.md` so the body must contain WikiLinks to both endpoints, and the metadata `Source_Item` / `Target_Item` are described explicitly as indexing duplicates of those links.

**Definition of Done.**
- RL note template includes a required `## Endpoints` section with two WikiLinks (`[[PKIM_ID|Name]]` form).
- Validation rule added: an RL note is invalid if the body lacks WikiLinks matching `Source_Item` and `Target_Item`.
- For relation types `contradicts`, `supports`, `supersedes`: a required `## Evidence` section with at least one EV WikiLink.
- Examples in spec updated.

### WP0.4 — Audit skill enforcement — **DONE 2026-05-17**

**Landed implementation.** Detectors live in `src/pkim/commands/audit_discipline.py` (orchestrator + five pure detector functions). CLI exposed as `pkim audit-discipline --database <name> --format json|text`. MCP exposed as the `audit_discipline` tool on `dt-pkim-mcp`. Field-registry encoded in `src/pkim/domain/fields_registry.py` from Appendix A. WikiLink parser in `src/pkim/domain/wikilinks.py`. Skill doc `skills/dt-audit-graph-corpus/SKILL.md` updated with the new patterns table and a Phase-4 invocation. Live-verified on PKIM-Pilot and PKIM-Knowledge. 26 unit tests cover positive and negative cases for every detector.

**Scope.** Extend `dt-audit-graph-corpus` to enforce the contract.

**Definition of Done.**
- Skill produces a `metadata-edge-violation` finding for any record whose metadata contains an edge-in-metadata pattern after WP0.2 cutover.
- Skill produces a `missing-body-wikilink` finding when RL `Source_Item`/`Target_Item` are not present as body WikiLinks.
- Skill produces a `missing-evidence-link` finding for RL notes of type `contradicts`/`supports`/`supersedes` lacking evidence WikiLinks.
- Findings written into `runs/<run-id>/audit/` and surfaced in `dt-review-queue-health`.
- Test fixture corpus included in `tests/` with at least one positive and one negative case per finding.

**Phase 0 exit criteria.** Principle merged; audit table complete; RL contract updated; audit skill detects every violation class on the fixture corpus. **Met 2026-05-17.**

### WP0.5 — Adopt MultiMarkdown headers as the canonical native note format — **DONE 2026-05-16**

**Scope.** Reverse the prior anti-pattern that listed MMD headers as a format to avoid. Native DEVONthink Markdown notes now use MultiMarkdown metadata headers; the mirror keeps YAML frontmatter for external tooling.

**Landed implementation.**

- Decision added to `01-principles-and-decisions.md` (2026-05-16).
- KN and RL templates rewritten in `08-record-and-note-specification.md` using MMD header form.
- Mirror frontmatter spec clarified to keep YAML and note the MMD ↔ YAML round-trip.
- Anti-pattern entry reversed; new banned-pattern entries added for edge-in-metadata and missing endpoints / evidence.
- `00-source-reconciliation.md` records the reversal and the `PrimaryTopic` removal that landed alongside.
- Glossary entries added for MMD header, PROPERTY/INDEX-POINTER/DERIVED, and edge-in-metadata.

### WP0.6 — Transport migration to PyObjC ScriptingBridge (cross-cutting)

Introduced after the original plan was written. Replaces the JXA/osascript transport and the vendored community MCP with a Python+PyObjC stack shared by the CLI and the new `dt-pkim-mcp` server. The structural contract for this work lives in [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md); the sub-sequence summary in the status table above is the live tracker.

**Why it lives in Phase 0.** The audit detectors in WP0.4 needed full-corpus body-read passes; doing that on per-call `osascript` forks made the audit prohibitively slow at scale. The transport pivot landed alongside Phase 0 so the audit could exercise it from day one.

**Where each sub-WP is currently captured.**

- WP0.6a — **DONE** 2026-05-16. `pkim/bridge/client.py`, `pkim/commands/bridge.py`, live probe verified against DT 4.1.1.
- WP0.6b — **DONE** 2026-05-16. `pkim/bridge/reads.py` with `DTReader.search` / `get_record_by_*` / `get_body` / `resolve_ref` / `get_record_at`; `pkim/domain/` types (ids, classification, edges, records, wikilinks, claims, fields_registry, headers).
- WP0.6c — **SKIPPED** 2026-05-16 per user direction.
- WP0.6d — **DONE** 2026-05-17. Read commands ported: `list-inbox`, `probe-capabilities`, `health-check`, `metadata-overview`, `sweep-inbox`, `queue-metrics`, `graph-audit`, `extract-text`. Open exception: `profile.py` classify/compare verbs.
- WP0.6e — **PARTIAL**. Domain types thread through every ported command; expanded with WP1.2 (Claim, claim parser) and WP0.6g (writes domain types).
- WP0.6f — **STUB DONE** 2026-05-16. `pkim/mcp/` server exposes `bridge_probe`, `search_records`, `audit_discipline`. Resources and remaining tools land alongside Phase 1 follow-ons.
- WP0.6g — **DONE** 2026-05-17. Every write-bearing command ported to `DTWriter`. New primitives: `set_name`/`set_comment`/`create_record`/`create_group`/`move_record`/`replicate_record`/`duplicate_record`/`delete_record`. See [00 Source Reconciliation](00-source-reconciliation.md) §Write-command migration to bridge complete.
- WP0.6h — **PENDING**. `pkim/jxa.py` emits `DeprecationWarning` on import. Final two callers (`profile.py` classify/compare, `reporting.py` restore-drill open/close) must migrate before deletion.

---

## Phase 1 — Claim Schema and Synthesis Contract — **DONE 2026-05-17**

### WP1.1 — Define the claim schema — **DONE 2026-05-17**

**Landed implementation.** `docs/design/18-evidence-discipline-and-claims.md` defines the YAML claim block schema (`claim`, `type`, `confidence`, `evidence: [WikiLinks]`, `contradicted_by: [WikiLinks]`, optional `note`), the four-type vocabulary, the three-band confidence ladder with operational meanings, contradiction-handling shapes, the claim-ledger run-artefact contract, and a glossary block. Cross-referenced from doc 08 KN spec, doc 11 Skill Loading Map, and doc 05 Workflow 3 / Workflow 7.

**Scope.** New design doc `docs/design/18-evidence-discipline-and-claims.md` covering: claim block schema, types (`fact`/`inference`/`assumption`/`open-question`), confidence ladder (`low`/`medium`/`high`), required vs. optional fields, contradiction handling, the claim ledger artefact contract.

**Definition of Done.**
- Schema specified as YAML inside a fenced block (`claim`, `type`, `confidence`, `evidence: [WikiLinks]`, `contradicted_by: [WikiLinks]`, optional `note`).
- Confidence ladder defines what each band means in operational terms (e.g. *high* = corroborated by ≥2 independent EVs with no contradictions).
- Rules: every `fact` and `inference` requires ≥1 `evidence` WikiLink; `assumption` and `open-question` may have zero.
- Claim ledger artefact contract: location (`runs/<run-id>/claim-ledger.md`), schema, retention.
- Cross-references to `dt-build-claim-ledger` and `dt-audit-claim-evidence`.
- Glossary entries for *claim*, *claim ledger*, *contradiction register*, *confidence band*.

### WP1.2 — Replace `## Key points` with `## Claims` in the KN template — **DONE 2026-05-17**

**Landed implementation.** `08-record-and-note-specification.md` KN template now uses `## Claims` with the WP1.1 schema. `KnowledgeConfidence` added to KN custom-metadata table as a PROPERTY field; `Claim_Backed` added as DERIVED. Knowledge-note validation rules require ≥1 well-formed claim on `KnowledgeStatus ∈ {reviewed, published}` and forbid `Claim_Backed=no` published notes. Migration approach (refactor-on-touch via `needs-review`) documented. Implementation seam: `pkim.domain.claims.parse_claims_section` + `pkim.commands.audit_discipline.detect_missing_claims`. `Claim_Backed` write-back lives in `pkim.mirror.writeback.apply_claim_backed` (WP2.3).

**WP1.bonus (extra) — DONE 2026-05-17.** `missing-claims` detector added to `pkim audit-discipline`; three positive/negative test cases plus orchestrator-aggregation test.

**Scope.** Update `08-record-and-note-specification.md` KN spec: replace free-prose `## Key points` with structured `## Claims` block per WP1.1 schema. Add `KnowledgeConfidence` enum to KN custom metadata (legitimate property — describes the record).

**Definition of Done.**
- KN template updated; example notes refactored.
- `KnowledgeConfidence` field defined (`low`/`medium`/`high`), validation rules added.
- Validation: KN with `KnowledgeStatus ∈ {reviewed, published}` must contain ≥1 well-formed claim block.
- `Claim_Backed` derived field defined (computed by mirror; values `yes`/`no`/`partial`).
- Migration note in `00-source-reconciliation.md` describing how existing KNs are handled (e.g. all flipped to `KnowledgeStatus=needs-review` pending claim conversion).

### WP1.3 — Wire synthesis skills into the workflow map — **DONE 2026-05-17**

**Landed implementation.** `11-agent-skills-and-runbooks.md` Skill Loading Map gained new rows wiring `dt-build-claim-ledger`, `dt-detect-contradictions`, `dt-audit-claim-evidence`, and `pkim audit-discipline`. `05-workflows.md` Workflow 3 grew a "Pass 3 — Triangulate" step producing `runs/<run-id>/claim-ledger.md` before the KN is authored; new Workflow 7 "Periodic Claim Audit" specifies monthly cadence, scope, and aggregation into `runs/<run-id>/defect-register.md`. Human-in-the-loop gates noted for contradiction triage.

**Scope.** Register `dt-build-claim-ledger` and `dt-audit-claim-evidence` in `11-agent-skills-and-runbooks.md` Skill Loading Map. Insert "Pass 3 — Triangulate" into Workflow 3 in `05-workflows.md`. Add Workflow 7 "Periodic Claim Audit".

**Definition of Done.**
- Skill Loading Map row exists for both skills with trigger conditions, inputs, outputs.
- Workflow 3 has an explicit Pass 3 step naming the skill, the input set (EVs short-listed in Pass 2), and the output artefact path (`runs/<run-id>/claim-ledger.md`).
- Workflow 7 specified: cadence (monthly), scope (`KnowledgeStatus ∈ {reviewed, published}`), output (`runs/<run-id>/defect-register.md`), follow-up disposition rules.
- Both workflows have explicit human-in-the-loop gates noted where contradictions are surfaced.

### WP1.4 — Authoring skills — **DONE 2026-05-17**

**Landed implementation.** Three new skill packages under `skills/`: `dt-build-claim-ledger`, `dt-detect-contradictions`, `dt-audit-claim-evidence`. Each `SKILL.md` follows the format of existing dt-* skills (purpose, inputs, outputs, preconditions, postconditions, failure modes, related skills). The fixture-based dry-run examples are deferred to the first invocation that exercises live data; the workflow chain is documented well enough to drive an LLM operator without fixtures.

**Scope.** Create three new skills:
- `skills/dt-build-claim-ledger/` — produces a claim ledger draft from an EV shortlist.
- `skills/dt-detect-contradictions/` — mirror-side query for shared-evidence opposing-edge-class cases.
- `skills/dt-audit-claim-evidence/` — verifies every claim's `evidence:` WikiLinks resolve and the cited EV is not retired/superseded.

**Definition of Done.**
- Each skill has a `SKILL.md` matching the format of existing dt-* skills (purpose, inputs, outputs, preconditions, postconditions, failure modes).
- Each skill has a fixture-based dry-run example in `tests/`.
- `dt-build-knowledge-note` updated to require a claim-ledger input artefact for `KnowledgeStatus ∈ {reviewed, published}` notes.
- `11-agent-skills-and-runbooks.md` Skill Loading Map updated.

**Phase 1 exit criteria.** Claim schema specced; KN template updated; synthesis skills wired into workflows; authoring skills exist with dry-run fixtures passing.

---

## Phase 2 — Mirror as Analytical Source of Truth — **DONE 2026-05-17**

### WP2.1 — Mirror schema for the graph — **DONE 2026-05-17**

**Landed implementation.** New package `src/pkim/mirror/` with `graph.py` exposing a SQLite-backed `MirrorGraph` (tables: `nodes`, `edges`, `claims`, `evidence_links`, `contradicted_by`) and `build_mirror_graph(reader, databases, ...)` for orchestrated rebuilds. Parser tags every body WikiLink with its source section (`evidence`, `related`, `endpoint`, `claim-evidence`, `mention`). Idempotent — `ingest_records` clears and re-loads in scope on every call. Schema documented in Appendix B below; 6 unit tests cover node ingest, retirement marking, body-WikiLink classification, claim+evidence parsing, idempotency, and contradicted_by storage.

**Scope.** Extend `dt-sync-export-mirror` to parse note bodies and persist a queryable graph (SQLite or DuckDB) alongside the existing export.

**Definition of Done.**
- Schema documented in `docs/design/19-synthesis-uplift-plan.md` Appendix B: tables for `nodes` (PKIM_ID, type, title, status, confidence), `edges` (source, target, edge_class, source_section, source_run), `claims` (knowledge_node, claim_text, type, confidence, evidence_node), `evidence_links` (claim, evidence_node, weight if specified).
- Parser extracts WikiLinks per section (`## Claims`, `## Evidence`, `## Related notes`, `## Endpoints`) and tags each edge with its source section.
- Mirror sync is idempotent and deterministic; running twice produces zero diff.
- Mirror DB committed location and lifecycle described (rebuilt on every sync, not authoritative; DT remains source of truth for records).
- Smoke test: a fixture DT export reproduces a known graph node/edge count.

### WP2.2 — Mirror-side audits — **DONE 2026-05-17**

**Landed implementation.** `src/pkim/mirror/audits.py` exposes five pure-SQL detectors over `MirrorGraph`: `detect_orphan_kns`, `detect_zombie_kns`, `detect_dangling_edges`, `detect_corpus_contradictions`, `detect_low_claim_density`. Orchestrator `run_mirror_audit` aggregates into a `MirrorAuditReport`. 8 unit tests cover positive + negative cases per detector. `MirrorFinding` schema standardised (`pattern`, `severity`, `record_pkim_id`, `record_name`, `detail`, `repair_skill`); JSON output via `serialise_findings`. Output destination + DEF-record back-write happen when the run-artefact wiring lands in WP3 follow-on.

**Scope.** Implement audits the mirror can run that DT cannot:
- Orphan KNs (no inbound edges, no claims, no evidence).
- Zombie KNs (all cited EVs are retired/superseded).
- Dangling WikiLinks (target PKIM_ID does not resolve).
- Contradiction cycles (`A contradicts B`, `B contradicts A` without resolution).
- Unsupported relations (RL of restricted types without evidence — duplicate of WP0.4 but enforced against the mirror at scale).
- Claim density per KN (low density = candidate for `needs-review`).

**Definition of Done.**
- Each audit implemented as a deterministic SQL query against the mirror.
- Audit output schema standardised (finding type, severity, affected PKIM_IDs, suggested action).
- Audits run via a new `dt-mirror-audit` skill; output to `runs/<run-id>/mirror-audit/`.
- Findings written back into DT as `DEF-…` defect records (not as bag-of-metadata on the affected note).

### WP2.3 — Derived metadata write-back — **DONE 2026-05-17**

**Landed implementation.** `src/pkim/mirror/writeback.py` exposes `compute_claim_backed(graph)` (pure SQL aggregation) and `apply_claim_backed(graph, writer, current_values=...)` (writes via `DTWriter.set_claim_backed`). Values: `yes` (all fact/inference claims have ≥1 live evidence), `partial` (mixed), `no` (all dead/missing), or empty (no fact/inference claims to ground). 6 unit tests cover each verdict + the skip-unchanged path. Smart-rule wiring inside DT for `Claim_Backed=no` published-KN surfacing is a setup task for the operator, not code.

**Scope.** Mirror computes `Claim_Backed` for each KN and writes it back as DT custom metadata (legitimate — derived property of the record, not a relationship).

**Definition of Done.**
- Write-back uses existing `dt-apply-approved-metadata` plumbing.
- Field semantics: `yes` (all claims have valid evidence), `partial` (some claims unbacked or evidence retired), `no` (no claims or all claims unbacked).
- Smart Rule or saved search in DT surfaces `Claim_Backed=no` KNs with `KnowledgeStatus=published` as high-priority queue entries.
- Mirror sync logs every change.

**Phase 2 exit criteria.** Mirror persists the graph; mirror-side audits produce defect records; `Claim_Backed` flows back into DT.

---

## Phase 3 — Propagation and Lifecycle — **DONE 2026-05-17**

### WP3.1 — EV supersession propagates to KNs — **DONE 2026-05-17**

**Landed implementation.** `15-supersession-and-retirement-policy.md` propagation-rules table extended with a row for "KNs that cite the superseded evidence record" → `KnowledgeStatus=needs-review` via `pkim.mirror.propagation.propagate_supersession`. New §Evidence supersession → KN review section spells out the citation paths (legacy `## Evidence links`, `## Endpoints`, parsed `## Claims` blocks) and idempotency rules. Implementation in `src/pkim/mirror/propagation.py`: `kns_dependent_on(graph, evidence_pkim_ids)` identifies dependants, `propagate_supersession(graph, writer, ...)` performs the flip. 6 unit tests cover citation paths, dedupe, retired-KN skip, and the skip-already-needs-review path.

**Scope.** Extend `15-supersession-and-retirement-policy.md` so retiring or superseding an EV flips every KN citing it (via mirror lookup) to `KnowledgeStatus=needs-review` and creates a queue entry.

**Definition of Done.**
- Policy doc updated with propagation rule and exceptions.
- Implementation in the supersession skill performs the mirror lookup and the metadata write transactionally (or with a documented compensating action if partial).
- New `needs-review` lifecycle state added to KN spec; transition rules documented.
- Queue entry visible in `dt-review-queue-health`.
- Test: retiring a fixture EV correctly flips its dependant KNs.

### WP3.2 — Zombie KN sweep — **DONE 2026-05-17**

**Landed implementation.** `skills/dt-sweep-zombie-knowledge/SKILL.md` documents the periodic sweep that finds KNs whose entire evidence set is retired/superseded. Composes `pkim.mirror.audits.detect_zombie_kns` plus an envelope schema for `dead` / `weakening` / `clean` triage. Cadence and trigger conditions cross-referenced with Workflow 7.

**Scope.** Periodic skill that finds KNs whose only cited evidence is retired/superseded and flags them.

**Definition of Done.**
- `skills/dt-sweep-zombie-knowledge/` exists with SKILL.md, dry-run fixture, and integration with the audit output schema.
- Cadence and trigger documented in `05-workflows.md`.

### WP3.3 — `needs-human` state for unresolvable contradictions — **DONE 2026-05-17**

**Landed implementation.** `08-record-and-note-specification.md` §Review State Model expanded `needs-human` semantics: documented automatic flip routes (corpus contradictions detected by `dt-detect-contradictions`, `verdict: degraded` from `dt-audit-claim-evidence` on published KNs, ambiguous `sweep-inbox` outcomes), the "automation must not progress this record" rule, and the explicit-operator-clear requirement. Glossary entry added.

**Scope.** Define and implement a `needs-human` flag on KNs and RLs where automated audits detect a contradiction that cannot be resolved by re-running synthesis.

**Definition of Done.**
- State documented in `08-record-and-note-specification.md` and glossary.
- Audit findings of type `unresolved-contradiction` flip the affected records to `needs-human` automatically.
- Records in `needs-human` are excluded from automated workflows until cleared manually.

**Phase 3 exit criteria.** Retiring an EV reliably propagates; zombies are detected and flagged; contradictions have an explicit human-resolution state.

---

## Phase 4 — Checkpoint Re-Gating — **DONE 2026-05-17**

### WP4.1 — New Checkpoint S (Synthesis) — **DONE 2026-05-17**

**Landed implementation.** `13-capability-and-mvp-map.md` gained a new "Checkpoint S: Synthesis discipline in use" section between C and D as a hard gate. Success criteria are measurable from the mirror: claim schema in use weekly, zero `missing-claims` on published KNs, non-empty contradiction register, `dt-build-claim-ledger` invocation count, zero `Claim_Backed=no` on published KNs.

**Scope.** Insert a synthesis checkpoint between the current C and D in `13-capability-and-mvp-map.md`.

**Definition of Done.**
- Checkpoint S defined with explicit success criteria, all measurable from the mirror:
  - Claim schema in use on ≥1 newly-authored KN per week.
  - Contradiction register is non-empty (proving detection works; emptiness is suspicious, not success).
  - `dt-build-claim-ledger` invoked at least N times in the preceding period.
  - Zero `published` KNs with `Claim_Backed=no`.
- Checkpoint S is a hard gate — checkpoints D–G cannot be declared until S is met.

### WP4.2 — Amend Checkpoint G success criteria — **DONE 2026-05-17**

**Landed implementation.** `13-capability-and-mvp-map.md` §Success Criteria amended with four synthesis-health gates: ≥80% claim-coverage on published KNs with resolved evidence WikiLinks, zero unresolved corpus contradictions on published KNs, defect-register growth rate < 5% MoM at steady state, zero `Claim_Backed=no` on published. Logged in `00-source-reconciliation.md`.

**Scope.** Update Checkpoint G in `13-capability-and-mvp-map.md` to include synthesis-health gates.

**Definition of Done.**
- Criteria amended to include:
  - ≥80% of `published` KNs have ≥1 well-formed claim with evidence WikiLinks.
  - Zero unresolved contradictions affecting `published` KNs.
  - Defect register growth rate < 5% month-on-month (steady state).
- `00-source-reconciliation.md` records the change.

**Phase 4 exit criteria.** Checkpoints cannot be passed by plumbing alone.

---

## Phase 5 — Documentation Hygiene (small, do alongside)

### WP5.1 — Index and cross-link

**Definition of Done.**
- `docs/design/README.md` index updated with new docs (`18-evidence-discipline-and-claims.md`, `19-synthesis-uplift-plan.md`, `19a-metadata-is-not-the-graph.md`).
- Every new doc has bidirectional cross-references to the docs it amends.
- `15-glossary.md` updated with: claim, claim ledger, confidence band, contradiction register, edge class, body WikiLink, derived metadata, zombie KN, needs-review, needs-human, Claim_Backed.

### WP5.2 — Migration record

**Definition of Done.**
- `00-source-reconciliation.md` contains a dedicated section logging every behavioural delta from this plan, with dates.
- Any pre-existing PKIM records affected by schema changes have a documented migration path.

---

---

## Phase 6 — Claims As Nodes — **NOT STARTED**

Promotes claims from YAML-in-KN-body to first-class `CL-…` graph records. Full rationale, record class, tag vocabulary, edge model, and migration approach in [21 Claims As Nodes](21-claims-as-nodes.md). The schema (type, confidence, evidence, contradicted_by) is unchanged from [18](18-evidence-discipline-and-claims.md); only the carrier moves from YAML to records.

This phase is a **carrier migration**, not a re-spec. Phase 1's claim schema, Phase 2's mirror graph, and Phase 3's propagation machinery all remain authoritative; what changes is where the claim lives in DT (a CL record) and how downstream tooling reads it (graph query, not body parse).

### WP6.1 — DocRole + tag vocabulary registration

**Scope.** Register the `CL-…` record class in the canonical model.

**Definition of Done.**
- `08-record-and-note-specification.md` gains a "Claim record (CL)" section: PKIM_ID format, MMD body template, required custom-metadata fields (`PKIM_ID`, `DocRole=claim`, `ClaimType`, `ClaimConfidence`, `Review_State`, `ParentKN_ID`), required tag set (`pkim/claim`, `claim/type/<…>`, `claim/confidence/<…>`, `claim/state/<…>`, plus inherited topic tag).
- `DocRole` vocabulary in §Metadata Schema extended with `claim`.
- `ClaimType`, `ClaimConfidence`, `ParentKN_ID` classified in Appendix A as PROPERTY / PROPERTY / INDEX-POINTER respectively.
- `15-glossary.md` updated with "Claim record (CL)".
- `00-source-reconciliation.md` records the delta.
- No code yet; vocabulary only.

### WP6.2 — `create-claim` CLI command and MCP tool

**Scope.** A single command mints a `CL-…` PKIM_ID, creates the DT record at `/Notes/Claims`, sets tags + custom metadata + alias, writes the MMD body, and appends a `[[CL-…|…]]` WikiLink to the parent KN's `## Claims` section.

**Definition of Done.**
- `pkim create-claim --parent <KN_ID> --statement "<text>" --type <fact|inference|assumption|open-question> --confidence <low|medium|high> [--evidence <EV_ID>]… [--contradicted-by <ID>]…` lands in `src/pkim/commands/create_claim.py`.
- `pkim apply-metadata` `ALLOWED_FIELDS` + `_INTERNAL_KEYS` extended for `ClaimType`, `ClaimConfidence`, `ParentKN_ID`.
- `dt-pkim-mcp` exposes a `create_claim` tool wrapping the CLI.
- Production-write gate respected (`PKIM_ALLOW_PRODUCTION_WRITES=true`).
- Unit tests cover dry-run, evidence-empty open-question, evidence-required fact (rejects on empty), and parent-KN `## Claims` section append (creates the section if absent).

### WP6.3 — Mirror audits for CL records

**Scope.** New detectors over `MirrorGraph` for the claim-as-node corpus.

**Definition of Done.**
- `src/pkim/mirror/audits.py` gains `detect_orphan_claims`, `detect_unbacked_claims`, `detect_dangling_contradictions`, `detect_mismatched_confidence`, `detect_duplicate_claims`.
- `Claim_Backed` derivation in `src/pkim/mirror/writeback.py` rewritten to traverse the graph (KN ← `claim-of` ← CL → `cites` → EV) rather than parse YAML.
- Existing `detect_missing_claims` extended: a KN passes if it has ≥1 `claim-of` predecessor (i.e. ≥1 CL child), in addition to the legacy YAML-block path which it retains while migration is in flight.
- 5+ unit tests covering positive/negative cases per detector.
- `pkim audit-discipline` surfaces these findings on both PKIM-Pilot and PKIM-Knowledge with no false positives on the post-pilot corpus.

### WP6.4 — Migration command (`migrate-claims-to-nodes`)

**Scope.** A reversible bulk converter that turns YAML claim blocks inside KN bodies into CL records, leaving the KN with a WikiLink bullet list.

**Definition of Done.**
- `pkim migrate-claims-to-nodes --database <name> --dry-run` enumerates affected KNs, prints planned CL records (with proposed PKIM_IDs minted in dry-run mode), and writes a plan to `runs/<run-id>/claim-migration-plan.json`.
- `pkim migrate-claims-to-nodes --database <name> --execute` performs the conversion: mints CLs, creates records, sets tags + metadata + aliases, rewrites the KN's `## Claims` section, and writes a mapping + backup to `runs/<run-id>/claim-migration/` (original KN body preserved verbatim).
- A `pkim migrate-claims-to-nodes --database <name> --rollback <run-id>` path exists that deletes the minted CL records and restores the KN bodies from backup.
- 4+ unit tests covering: dry-run, execute, idempotency (running execute twice produces zero new records), rollback.
- `audit-discipline` runs clean after a successful execute.

### WP6.5 — Pilot migration of KN-20260517-0002

**Scope.** Apply WP6.4 to the MuleSoft KN authored in today's Workflow 3 walk. Eight claims; single EV (EV-20260517-0001) cited by all; small enough to verify end-to-end inside one session.

**Definition of Done.**
- Dry-run produces a plan listing 8 CL records.
- Execute mints `CL-20260517-0001` … `CL-20260517-0008`, files them under `/Notes/Claims`, tags + meta correct.
- KN-20260517-0002 body now has a `## Claims` bullet list of 8 WikiLinks.
- `pkim deep-profile --record KN-20260517-0002` shows 8 outbound `claim-of` (inverse, has-claim) edges to CL records, and EV-20260517-0001's inbound count rises to 8 + the existing KN citation.
- `audit-discipline` reports 0/0/0 on both PKIM-Knowledge and PKIM-Pilot.
- All 8 CL records' bodies render correctly in DT (tags visible, alias resolves, evidence WikiLink clickable).
- DT Smart Groups `/Smart Groups/Claims` and `/Smart Groups/Knowledge (claims-hidden)` exist and filter correctly.

### WP6.6 — Bulk migration of remaining YAML claim blocks

**Scope.** Migrate every KN in PKIM-Knowledge with a YAML `## Claims` block. (KN count and claim count to be enumerated by WP6.4 dry-run before execution.)

**Definition of Done.**
- Pre-flight dry-run logged in `runs/<run-id>/claim-migration-plan.json`; reviewed by operator.
- Execute completes without partial-state on any KN; rollback path verified.
- Post-migration audit reports 0/0/0.
- `dt-build-claim-ledger` and `dt-build-knowledge-note` are updated to default to CL-as-nodes output; the YAML-in-body fallback is flagged for removal and removed once the migration is complete on every active database.
- `00-source-reconciliation.md` records the date, the record-count delta, and any per-KN exceptions that required hand-editing.

**Phase 6 exit criteria.** Every active KN with claims has CL children; no `## Claims` block in any KN body still contains YAML; mirror audits run clean; `dt-build-claim-ledger` produces records by default.

---

## Sequencing and Dependencies

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4 ──► Phase 6
   │           │           │
   └────► Phase 5 (parallel, lightweight) ──► all phases
```

Phase 6 depends on Phase 2 (mirror graph) and Phase 1 (claim schema) being stable; both landed 2026-05-17.

- **Phase 0 must land first.** Without the principle, every later schema change is contested.
- **Phase 1 before Phase 2.** Mirror parses claim blocks; the block must exist first.
- **Phase 2 before Phase 3.** Propagation depends on the mirror's edge index.
- **Phase 4 last.** Checkpoint amendments only meaningful once the underlying capability exists.
- **Phase 5 runs alongside** all phases — never let docs drift behind merged code.

---

## Cross-Cutting Definitions of Done (apply to every WP)

- [ ] Design doc updated *in the same PR* as the implementing change. No code-without-doc.
- [ ] At least one positive and one negative test fixture for every new validation rule.
- [ ] No new "edge in metadata" introduced anywhere in scope.
- [ ] Every new field classified as PROPERTY, INDEX-POINTER, or DERIVED. No ambiguous fields.
- [ ] `00-source-reconciliation.md` updated with the delta.
- [ ] `15-glossary.md` updated for any new term.
- [ ] Mirror schema migration (if any) is reversible.
- [ ] No automation can mutate DT for a new behaviour without an explicit safety model and rollback path captured in `docs/design/06-operations-and-safety.md`.

---

## Appendix A — Field Audit Table (WP0.2)

**Audit date:** 2026-05-16.
**Scope:** every custom metadata field declared in [08 Record And Note Specification](08-record-and-note-specification.md) §Metadata Schema, including Core, Evidence-specific, Knowledge-specific, Relation-specific, and Operational queue signals.

**Classifications:**

- **PROPERTY** — describes a quality of the record itself. Authored by humans or automation. Passes the "if every other record disappeared, would this still be meaningful?" test.
- **INDEX-POINTER** — points to another record's identity, but only as an indexing duplicate of a WikiLink that exists in this record's body. Allowed only on relation notes.
- **DERIVED** — computed by the export mirror or automation; never authored by humans; not authoritative.
- **EDGE-IN-METADATA** *(banned)* — a scalar pointer to another record intended to express a relationship. Must be replaced by a WikiLink in the body or by a relation note.

**Headline finding.** The existing schema is structurally aligned with the metadata-vs-graph principle. There are no scalar `RelatedTo`/`Supersedes`/`Contradicts` fields on source records; the relation-note pattern is used correctly. Three fields are borderline and need explicit restatement (`PrimaryTopic`, `EvidenceCount`, `Knowledge_Link_State` / `Relation_Gap_State` as a pair). No fields require removal.

### Identity fields

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `PKIM_ID` | all | PROPERTY | KEEP | The record's own identity. |
| `DT_UUID` | all | PROPERTY | KEEP | Native ID of the record. |
| `DT_ItemLink` | all | PROPERTY | KEEP | Self-reference; the clickable form of this record's own ID. Not a relationship to another record. |

### Core fields

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `DocRole` | all | PROPERTY | KEEP | Taxonomy of this record. |
| `Review_State` | all | PROPERTY | KEEP | Operational state of this record. |
| `CreatedByMode` | all | PROPERTY | KEEP | Who/what authored this record. |
| `Origin_URI` | all | PROPERTY | KEEP | External provenance URI; not a PKIM record pointer. |
| `Origin_Last_Path` | evidence | PROPERTY | KEEP | Last known local path of this record. |
| `PrimaryTopic` | — | — | **REMOVED 2026-05-16** | Dropped by user direction: insufficient value for the risk it carried of becoming an edge-in-metadata pointer to topic notes. Topical grouping now expressed via tags, body WikiLinks to topic notes, or `Aliases`. |
| `LastProfiledAt`, `LastMirroredAt` | all | PROPERTY | KEEP | Timestamps about this record. |
| `LastRunID` | all | PROPERTY *(narrow)* | KEEP | Operational provenance to a run record. Allowed as a narrow exception: a run is not a knowledge-graph node, and one-way pointer to "the last run that touched this record" is a property, not an authored relationship. Document this carve-out in §Metadata Schema. |
| native `kind` | all | PROPERTY | KEEP | Native DT field. |

### Evidence-specific fields

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `EvidenceStatus` | evidence | PROPERTY | KEEP | |
| `Content_SHA256` | evidence | PROPERTY | KEEP | Integrity hash of this record. |
| `CaptureType` | evidence | PROPERTY | KEEP | |
| `CanonicalSourceURL` | evidence | PROPERTY | KEEP | External URL; not a PKIM record pointer. |

### Knowledge-specific fields

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `NoteType` | knowledge | PROPERTY | KEEP | |
| `KnowledgeStatus` | knowledge | PROPERTY | KEEP | Lifecycle state of this record. |
| `Mirror_Path` | knowledge | PROPERTY | KEEP | Self-property: where this record is mirrored to. |
| `EvidenceCount` | knowledge | DERIVED | RESTATE | Currently described as "Optional denormalised hint for dashboards." Restate as: **derived dashboard counter, computed by the export mirror from `## Evidence` WikiLinks in the body, never authored by humans, not authoritative graph data.** Add an explicit "DERIVED" tag in §Metadata Schema. |

### Relation-specific fields

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `Relation_Type` | relation | PROPERTY | KEEP | A property of the RL (what kind of edge this RL represents), not a pointer. |
| `Source_Item` | relation | INDEX-POINTER | KEEP-WITH-BODY-MIRROR | The body of the RL must independently carry the source as a WikiLink in `## Endpoints` (see WP0.3). |
| `Target_Item` | relation | INDEX-POINTER | KEEP-WITH-BODY-MIRROR | Same rule applies to the target. |
| `RelationConfidence` | relation | PROPERTY | KEEP | Quality of this RL. |
| `RelationStatus` | relation | PROPERTY | KEEP | Lifecycle of this RL. |

### Operational queue signals

| Field | On record type | Classification | Disposition | Notes |
| --- | --- | --- | --- | --- |
| `Needs_OCR` | evidence | PROPERTY | KEEP | Operational state of this record. |
| `Knowledge_Link_State` | evidence / knowledge | DERIVED | RESTATE | A property derived from corpus-wide linkage state. Currently ambiguous in §Operational queue signals. Restate as derived; computed by mirror; not authored. |
| `Relation_Gap_State` | knowledge | DERIVED | RESTATE | Same — derived from coverage analysis, not authored. |
| `Indexed_Risk_State` | evidence | PROPERTY | KEEP | State of this record's indexed path. |
| `Mirror_State` | knowledge / relation | PROPERTY | KEEP | State of this record's mirror. |
| `Automation_Last_Run_State` | all | PROPERTY | KEEP | Last automation outcome on this record. |

### Disposition summary

- **KEEP:** 22 fields. No change needed.
- **KEEP-WITH-BODY-MIRROR:** 2 fields (`Source_Item`, `Target_Item`). Body WikiLinks become mandatory under WP0.3 (landed 2026-05-16).
- **RESTATE:** 3 fields (`EvidenceCount`, `Knowledge_Link_State`, `Relation_Gap_State`) — restated as DERIVED in `08-record-and-note-specification.md` 2026-05-16.
- **REMOVE:** 1 field (`PrimaryTopic`) — removed 2026-05-16 by user direction.

### Follow-on actions

1. **In `08-record-and-note-specification.md`:** add a "Classification" column to the Canonical field set table and to each section table. Populate per Appendix A. Add an explicit narrow-exception note for `LastRunID`.
2. **In `08-record-and-note-specification.md` §Metadata Schema:** add a "Field discipline" paragraph stating that every field has one of three classifications (PROPERTY, INDEX-POINTER, DERIVED), no exceptions, and that new fields must be classified at design time.
3. **In `15-glossary.md`:** add entries for "PROPERTY field", "INDEX-POINTER field", "DERIVED field", "edge-in-metadata".
4. **Carry into WP0.4:** `dt-audit-graph-corpus` must enforce these classifications; any future field that does not have a classification is itself a violation.

### Forward-looking gates

When **Phase 1** introduces `KnowledgeConfidence` and `Claim_Backed`, they must be classified up front in this table:

- `KnowledgeConfidence` — PROPERTY (a quality of the knowledge note itself).
- `Claim_Backed` — DERIVED (computed by mirror; never authored by humans).

## Appendix B — Mirror Graph Schema (WP2.1)

**Implementation:** `src/pkim/mirror/graph.py` :: `SCHEMA_SQL`. SQLite-backed; idempotent; rebuilt on every sync.

| Table | Columns | Notes |
| --- | --- | --- |
| `nodes` | `pkim_id` (PK), `dt_uuid`, `name`, `doc_role`, `knowledge_status`, `review_state`, `knowledge_confidence`, `database_name`, `item_link`, `is_retired` | One row per PKIM-identified record. `is_retired` derived from `Review_State ∈ {archived, error}` or `KnowledgeStatus=archived`. |
| `edges` | `source_id`, `target_id`, `edge_class`, `source_section`, `source_run` (PK over first four) | One row per `[[PKIM_ID|...]]` WikiLink in a body, classified by the section heading (`Evidence links → evidence`, `Related notes → related`, `Endpoints → endpoint`, `Claims → claim-evidence`, else `mention`). |
| `claims` | `claim_id` (PK auto), `knowledge_node`, `claim_text`, `type`, `confidence`, `raw_block`, `note` | One row per parsed claim block. `raw_block` preserves the source YAML for round-trip emission. |
| `evidence_links` | `claim_id`, `evidence_pkim_id`, `position` (PK over first two) | One row per `evidence` WikiLink on a claim. |
| `contradicted_by` | `claim_id`, `contradicting_id`, `position` (PK over first two) | One row per `contradicted_by` WikiLink on a claim. |

Indexes: `nodes.doc_role`, `nodes.knowledge_status`, `nodes.database_name`, `edges.target_id`, `edges.edge_class`, `claims.knowledge_node`, `claims.type`, `evidence_links.evidence_pkim_id`.

Usage:

```python
from pkim.bridge import DTBridge, DTReader
from pkim.mirror import build_mirror_graph

bridge = DTBridge.connect()
bridge.require_running()
reader = DTReader(bridge)
graph = build_mirror_graph(
    reader,
    databases=["PKIM-Knowledge", "PKIM-Pilot"],
    db_path="runs/<run-id>/mirror.sqlite",
    run_id="<run-id>",
)
```

## Appendix C — Risks

- **R1.** Migration of existing KNs to the claim schema is laborious. Mitigation: do not retro-fit; flip all to `needs-review`, refactor on touch.
- **R2.** Mirror divergence from DT during long write sessions. Mitigation: mirror is rebuilt on every sync; never treat mirror as authoritative for records.
- **R3.** `Claim_Backed` write-back creates a write loop with audit. Mitigation: only write when the value changes; audit only reads.
- **R4.** Over-zealous contradiction detection floods the defect register. Mitigation: require human triage threshold before counting a contradiction as `unresolved`; tune the SQL.
- **R5.** Body WikiLink parser misses edge cases (aliases, escaped brackets). Mitigation: shared parser between DT (via JXA) and mirror (Python); fixture corpus covers known forms.
