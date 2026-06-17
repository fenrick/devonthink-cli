---
name: dt-sweep-zombie-knowledge
description: Find knowledge notes whose only cited evidence has been retired or superseded — "zombie" knowledge that still looks authoritative but rests on a dead foundation. Use this when you want to surface KNs that need to be re-grounded, retired, or rewritten, especially after a wave of EV supersessions, or as part of the periodic claim audit (Workflow 7).
compatibility: Read-only against the export mirror's parsed graph (per WP2.1) with optional fall-back to live DEVONthink reads via the PyObjC ScriptingBridge transport. Writes only to runs/<run-id>/zombie-kns.json.
---

# dt-sweep-zombie-knowledge

This skill exists because retiring an evidence record does not, by itself,
retire the knowledge built on top of it. A KN authored last year may still
cite three EVs that have since been superseded or archived; without an
explicit sweep, the KN sits in `published` state looking trustworthy long
after its grounding has gone.

`dt-audit-claim-evidence` runs the same check on a single KN. This skill runs
it across the whole corpus and surfaces the worst offenders first.

See [19 Synthesis Uplift Plan](../../docs/design/19-synthesis-uplift-plan.md) WP3.2 for the work package this skill implements, and [18 Evidence Discipline And Claims](../../docs/design/18-evidence-discipline-and-claims.md) for the claim/evidence model it walks.

## What this skill is for

Use it when:

- a wave of EV records has just been retired or superseded (e.g. after a vendor refresh)
- the periodic claim audit (Workflow 7) is running its monthly pass
- before a publish wave that promotes many KNs from `reviewed` to `published`
- an operator wants to triage "what knowledge needs re-grounding?"

Do not use it for:

- contradictions between live KNs — use `dt-detect-contradictions`
- per-claim grounding on a specific KN — use `dt-audit-claim-evidence`
- structural-discipline checks — use `pkim audit-discipline`

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `--mirror-db` | optional | Path to the mirror's SQLite DB; defaults to `runs/latest/mirror.sqlite`. |
| `--threshold` | optional | What fraction of a KN's evidence must be retired/superseded for it to count as a zombie. Default 1.0 (all evidence dead). Lower values widen the net to "weakening". |
| `--scope` | optional | `published` (default), `reviewed-or-published`, or `all`. |
| `--run-id` | yes | Output goes to `runs/<run-id>/zombie-kns.json`. |

## Outputs

- `runs/<run-id>/zombie-kns.json` — list of zombie KN records:
  - `pkim_id`, `name`, `knowledge_status`, `knowledge_confidence`
  - `claims_total`, `claims_zombie` (all-dead-evidence count)
  - `evidence_total`, `evidence_retired`, `evidence_dangling`
  - `severity`: `dead` (all evidence retired/dangling) / `weakening` (some retired but not all) / `clean`
  - recommended action route
- stdout summary: `N zombie KNs, M weakening, X clean`

## Preconditions

- The mirror SQLite DB exists and has been refreshed within the audit window.
- The mirror's edge and claim parsing covers the KNs in scope (Phase 2 must be live).
- `pkim.bridge` is reachable for fall-back when the mirror does not yet hold a retirement status for some EV.

## Postconditions

- The output JSON exists at the documented path.
- No DEVONthink records have been mutated.
- Each zombie KN is left in its current `KnowledgeStatus` — flipping to `needs-review` is a separate, authorised step (see WP3.1 and `dt-recover-failed-write`).

## Workflow

1. Resolve the KN set in scope via the mirror.
2. For each KN, parse its `## Claims` block (use the same parser as `dt-audit-claim-evidence`).
3. For each `evidence` WikiLink across all claims, resolve the target record's current status:
   - active EV with `Review_State ∉ {archived, error}` and `EvidenceStatus ∉ {archived}` → live
   - matching the above but `Review_State=archived` or `EvidenceStatus=archived` → retired
   - target does not resolve at all → dangling
4. For each KN, compute `evidence_retired / evidence_total` and `evidence_dangling / evidence_total`.
5. Classify severity:
   - `dead` — every claim's evidence is retired or dangling
   - `weakening` — `(retired + dangling) / total >= threshold` for at least one claim
   - `clean` — neither condition holds
6. Sort by severity (`dead` first, then `weakening`) and write the JSON.
7. Emit the summary line.

## Failure modes

- **`mirror-stale`** — mirror DB older than the latest KN write; skill aborts and asks for a re-sync.
- **`no-claims-blocks`** — the corpus has no `## Claims` sections to walk. Skill returns an empty result and reports that Phase 1 has not been adopted yet.
- **`scope-empty`** — the requested scope returns zero KNs.

## How to know you are doing it right

- `dead` count grows after an EV retirement wave, then shrinks as KNs are remediated
- `weakening` is a stable backlog at small percentage — too large means the discipline isn't keeping up
- the recommended actions name specific repair skills, not "human review" as a blanket

## How to know you are doing it wrong

- you find zero zombies after a major EV supersession — the retirement signal isn't propagating
- you find many zombies but no action ever lands — the sweep is being run for show
- the severity classification has too many `clean` entries — the threshold is set too lenient

## Related skills

- [`dt-audit-claim-evidence`](../dt-audit-claim-evidence/SKILL.md) — per-KN counterpart
- [`dt-detect-contradictions`](../dt-detect-contradictions/SKILL.md) — adjacent corpus-wide audit
- [`dt-build-claim-ledger`](../dt-build-claim-ledger/SKILL.md) — used to re-ground a zombie KN
- [`dt-recover-failed-write`](../dt-recover-failed-write/SKILL.md) — used when flipping a zombie KN to `needs-review`
