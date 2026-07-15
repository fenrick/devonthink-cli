---
name: dt-detect-contradictions
description: Mirror-side audit that detects corpus-level contradictions — two KNs citing the same EV with opposing edge classes, or two claims about the same subject with mutually exclusive truth values. Output is a contradiction register that feeds the periodic claim audit (Workflow 7). Use this whenever you want to know "where does our published synthesis disagree with itself", or as part of the periodic claim audit cadence.
compatibility: Read-only against the export mirror's parsed graph (SQLite/DuckDB per WP2.1). Does not require DEVONthink to be running. Writes only to runs/<run-id>/contradiction-register.md.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-detect-contradictions

This skill exists because contradictions inside a single KN are caught at
authoring time (via `contradicted_by` on the claim block), but contradictions
*across* KNs are invisible at the per-note level. Two knowledge notes can both
cite the same evidence and reach opposing conclusions without either author
knowing. The mirror's parsed graph makes this detectable.

See [18 Evidence Discipline And Claims](../../docs/design/18-evidence-discipline-and-claims.md) §Contradiction handling for the three shapes of contradiction and how this skill fits.

## What this skill is for

Use it when:

- running the monthly periodic claim audit (Workflow 7)
- after a large EV supersession or revision (a wave of opposing-edge re-classifications is likely)
- before a publish wave that promotes many KNs from `reviewed` to `published`

Do not use it for:

- within-KN contradictions — those are caught by the authoring discipline and the audit chain: `mcp__devonthink__search_records` + `get_record_text` + `get_record_properties`; findings emitted by the skill
- conflict resolution itself — this skill detects and reports; remediation is human-driven

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `--mirror-db` | optional | Path to the mirror's SQLite DB; defaults to `runs/latest/mirror.sqlite`. |
| `--scope` | optional | `published` (default), `reviewed-or-published`, or `all`. Controls which KNs participate. |
| `--run-id` | yes | Output goes to `runs/<run-id>/contradiction-register.md`. |

## Outputs

- `runs/<run-id>/contradiction-register.md` — append-only persistent log.
  - One entry per detected contradiction with date of detection, the involved records, the shared evidence, and current status (`open` / `acknowledged` / `resolved`).
- `runs/<run-id>/contradictions.json` — same content machine-readable.

## Preconditions

- The mirror SQLite DB exists and has been refreshed within the audit window.
- `pkim.bridge` is reachable if the skill needs to back-fill body text for any record the mirror has not yet parsed.

## Postconditions

- The contradiction register exists and lists every detected case.
- No corpus state has been mutated.
- A summary line is emitted: `N open, M acknowledged, X resolved`.

## Workflow

1. Query the mirror for KNs in scope.
2. For each pair `(KN_A, KN_B)` that cites a shared EV, compare the edge class on the RL connecting EV→KN_A vs EV→KN_B. Opposing edge classes (one `supports`, one `contradicts`) produce a `corpus-contradiction` finding.
3. For each KN in scope, parse its `## Claims` block. Check every claim's `contradicted_by` set against other KNs' claim texts in the corpus for near-duplicates with the opposite confidence sign.
4. Cross-reference findings against the prior contradiction register; carry forward `acknowledged` and `resolved` statuses.
5. Write the register; emit the summary.

## Failure modes

- **`mirror-stale`** — the mirror DB is older than the most recent KN write timestamp; skill aborts and asks the operator to re-sync the mirror.
- **`no-mirror`** — the mirror DB does not exist. The skill is read-only against the mirror; without it there is no work to do.
- **`schema-mismatch`** — the mirror schema does not match WP2.1's contract; skill reports the version delta and aborts.

## How to know you are doing it right

- the register's `open` count is small and roughly stable across runs (chronic open items mean the discipline is not closing the loop)
- new contradictions show up after EV revisions
- the register survives across runs; you are not regenerating it from scratch each time

## How to know you are doing it wrong

- the `open` count grows unbounded — remediation is not happening
- the register reports zero contradictions on a mature corpus — usually a sign that the mirror's edge classification is too generous
- every contradiction routes to `needs-human` and nothing ever resolves — the discipline has become a backlog

## Related skills

- [`dt-build-claim-ledger`](../dt-build-claim-ledger/SKILL.md) — upstream; writes the claim blocks this skill cross-references
- [`dt-audit-graph-corpus`](../dt-audit-graph-corpus/SKILL.md) — composes with this skill as part of the periodic claim audit
- [`dt-resolve-canonical-note`](../dt-resolve-canonical-note/SKILL.md) — used downstream when a contradiction routes to "retire one note in favour of another"
