---
name: dt-audit-claim-evidence
description: Per-record audit that walks a knowledge note's ## Claims block and verifies every claim's evidence WikiLinks resolve to live, non-retired EV or KN records. Surfaces zombie claims (claims supported only by retired evidence), dangling references, and structural violations. Use this when you want to know "is this specific KN's synthesis still grounded", before promoting a KN from reviewed to published, or as part of the periodic claim audit (Workflow 7).
compatibility: Read-only against DEVONthink via the PyObjC ScriptingBridge transport plus the export mirror for retirement-status lookups. Writes only to runs/<run-id>/claim-audit/<pkim_id>.json.
---

# dt-audit-claim-evidence

This skill exists because the existence of a claim's evidence WikiLink is not
the same as the evidence still being load-bearing. An EV can be retired,
superseded, or revised after a KN was authored, and unless someone checks, the
KN sits with a stale claim that looks well-grounded. This skill catches that.

It is the per-note counterpart to [`dt-detect-contradictions`](../dt-detect-contradictions/SKILL.md)
(which is corpus-wide). Both feed into [Workflow 7 — Periodic Claim Audit](../../docs/design/05-workflows.md#workflow-7-periodic-claim-audit).

## What this skill is for

Use it when:

- a single KN is about to be promoted from `reviewed` to `published`
- a KN has been touched after an EV supersession event
- the operator wants per-claim grounding confirmation rather than a corpus-wide summary
- you need a quick check against one note without re-running the mirror audit

Do not use it for:

- contradictions between KNs — use `dt-detect-contradictions`
- structural-discipline checks (missing endpoints, edge-in-metadata, etc.) — use `pkim audit-discipline`

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `--note` | yes | KN reference: PKIM_ID, DT UUID, or item link. Routed through `DTReader.resolve_ref`. |
| `--strict` | optional | If set, treat any unresolved `evidence` WikiLink as a fatal finding (default: medium-severity). |
| `--run-id` | yes | Output goes to `runs/<run-id>/claim-audit/<pkim_id>.json`. |

## Outputs

- `runs/<run-id>/claim-audit/<pkim_id>.json` per-note audit record:
  - `pkim_id`, `name`, `knowledge_status`, `knowledge_confidence`
  - `claims_total`, `claims_with_evidence`, `claims_missing_evidence`
  - per-claim breakdown: `claim_text`, `type`, `confidence`, `evidence_resolution` (one of `all-resolved` / `partially-resolved` / `none-resolved`), `retired_evidence_count`, `dangling_evidence_count`
  - top-level `verdict`: `ok` / `partial` / `degraded`
- stdout summary: `KN-… → verdict (N/M claims grounded)`

## Preconditions

- The KN reference resolves via `pkim bridge probe`.
- The mirror SQLite DB is fresh enough that retirement statuses are current; otherwise the skill emits a warning and falls back to live DT reads per cited EV (slower but accurate).

## Postconditions

- The per-note audit JSON exists at the documented path.
- No DEVONthink records have been mutated.
- The KN's own metadata is not changed; routing the verdict to `needs-review` is a separate decision step.

## Workflow

1. Resolve the KN reference. Fail-fast if not found.
2. Parse the `## Claims` block via `pkim.domain.claims.parse_claims_section`.
3. For each claim:
   - For each `evidence` WikiLink, resolve the target PKIM_ID against the corpus.
   - Classify resolution: `resolved-active` (target exists and not retired), `resolved-retired` (target exists but `Review_State ∈ {archived}` or `EvidenceStatus=archived`), `dangling` (target does not resolve).
4. Compute the per-claim `evidence_resolution` from the worst case across that claim's WikiLinks.
5. Compute the top-level verdict:
   - `ok` — every `fact` and `inference` claim is `all-resolved` with active evidence
   - `partial` — at least one such claim has `partially-resolved`
   - `degraded` — at least one `fact`/`inference` claim is `none-resolved` (zombie) or has `dangling` evidence
6. Write the per-note JSON and emit the summary line.

## Failure modes

- **`note-not-found`** — the `--note` ref does not resolve.
- **`no-claims-block`** — the KN has no `## Claims` section. The audit reports `verdict: degraded` with `reason: missing-claims` and routes to [`dt-build-claim-ledger`](../dt-build-claim-ledger/SKILL.md).
- **`unparseable-claims`** — the section exists but contains no parseable claim blocks. Reported as a high-severity finding; the operator needs to rewrite the section to the canonical YAML form.

## How to know you are doing it right

- `verdict=ok` corresponds to a note you would confidently publish
- `verdict=partial` always carries an actionable note: which evidence is partially-resolved and what to do about it
- the per-claim breakdown lets a reviewer see exactly which claim is the weakest link

## How to know you are doing it wrong

- every claim is `all-resolved` but the corpus has known retirements — the retirement signal isn't reaching the audit (probably mirror staleness)
- claims with `type: assumption` show up as `degraded` — assumptions are not supposed to require evidence; check the type vocabulary handling
- the JSON output gets too noisy for routine use — fold per-claim detail behind a `--verbose` flag and keep the top-level summary lean

## Related skills

- [`dt-build-claim-ledger`](../dt-build-claim-ledger/SKILL.md) — upstream; writes the claims this skill audits
- [`dt-detect-contradictions`](../dt-detect-contradictions/SKILL.md) — corpus-wide counterpart
- [`dt-resolve-canonical-note`](../dt-resolve-canonical-note/SKILL.md) — used downstream when a `degraded` verdict requires a note rewrite
