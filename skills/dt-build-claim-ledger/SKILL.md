---
name: dt-build-claim-ledger
description: Build a structured claim ledger from an evidence shortlist as Pass 3 of Workflow 3 (Evidence to Knowledge). Reads typed EV records and emits a run-artefact that subsequent KN authoring writes into the note's ## Claims section. Use this whenever a knowledge note is about to be created or updated from one or more EV records and the operator wants typed claims with evidence backing instead of free-prose key points.
compatibility: Read-only against DEVONthink via the PyObjC ScriptingBridge transport. Writes only to runs/<run-id>/claim-ledger.md on the filesystem. Does not mutate DEVONthink state.
---

# dt-build-claim-ledger

This skill exists because synthesis is a discipline, not a writing style. A
free-prose `## Key points` list rewards plausible-sounding writing; a structured
claim ledger forces the operator to be explicit about what kind of statement
each claim is, how confident they are in it, and what evidence supports it.

It is the Pass 3 step of [Workflow 3 — Evidence to Knowledge](../../docs/design/05-workflows.md#workflow-3-evidence-to-knowledge) and produces the run-artefact described in [18 Evidence Discipline And Claims](../../docs/design/18-evidence-discipline-and-claims.md).

## What this skill is for

Use it when:

- a KN is about to be authored or updated from a shortlist of EV records
- existing free-prose `## Key points` need to be converted into structured claims
- an operator wants the synthesis surface to be auditable

Do not use it for:

- free-text note authoring without evidence (use a project or topic note)
- single-record summarisation that does not need typed claims

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `--evidence` | yes | One or more EV PKIM_IDs or item links. Repeatable. The skill walks each via `DTReader.resolve_ref`. |
| `--target-note-type` | yes | `literature` / `synthesis` / `topic` / `project` — informs the ledger preamble. |
| `--run-id` | yes | The orchestrating run; controls the output path under `runs/`. |
| `--existing-note` | optional | A KN reference; the skill seeds the ledger with the note's current claims (or `## Key points` if the note is pre-WP1.2). |

## Outputs

- `runs/<run-id>/claim-ledger.md` — a single markdown file matching the claim-ledger contract in [18 Evidence Discipline And Claims](../../docs/design/18-evidence-discipline-and-claims.md):
  - YAML preamble (run_id, source_evidence, target_note_type, operator)
  - prose summary describing what was synthesised
  - one or more fenced YAML blocks of claim entries
- `runs/<run-id>/claim-ledger.json` — same content, machine-readable

## Preconditions

- DEVONthink reachable via the bridge (`pkim bridge probe` passes).
- All referenced EV records resolve to live records.
- The orchestrating run directory exists.

## Postconditions

- The claim ledger files exist at the documented paths.
- The ledger is a syntactically valid claim-block sequence parseable by `pkim.domain.claims.parse_claims_section`.
- No DEVONthink records have been mutated.

## Workflow

1. Resolve every `--evidence` reference. Fail-fast if any does not resolve.
2. Read each EV's plainText body via the bridge.
3. Run the synthesis pass over the EV set: produce candidate claims with `type`, `confidence`, `evidence`, and a reasoning note. A `fact` requires direct verbatim or near-verbatim support in at least one EV. An `inference` requires either corroboration across ≥2 independent EVs or a single EV plus an explicit reasoning chain. An `assumption` is a load-bearing belief the operator has not yet evidenced; an `open-question` is a known gap. Confidence bands: `high` (corroborated by ≥2 independent EVs, no contradictions), `medium` (one strong EV or two weak ones), `low` (single weak source or known counter-signal).
4. If `--existing-note` was passed, seed the ledger with the note's current claims as a base set; mark them as `inherited` in the preamble so the human reviewer can see the diff.
5. Write the ledger to `runs/<run-id>/claim-ledger.md` and `.json`.
6. Emit a one-line summary to stdout: `wrote N claims (M facts, X inferences, Y assumptions, Z open-questions)`.

## Failure modes

- **`evidence-resolve-failed`** — one or more `--evidence` refs do not resolve. Output names the failing refs; nothing is written.
- **`synthesis-empty`** — the synthesis pass produced zero candidate claims. The ledger is still written but with an explicit empty `claims: []` and the operator is alerted. Common when the EV records are pure data (tables, images) with no extractable assertions.
- **`mixed-corpus`** — the EV set spans more than 3 source databases; the skill warns the operator and asks them to confirm scope before proceeding (avoids accidentally synthesising across unrelated topics).

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## MANDATORY: relation notes (RL) are part of every end-to-end walk

A Workflow-3 walk that produces a KN + N CLs but zero RLs is **incomplete**. Every cross-citation in a CL's reasoning prose, every KN-to-KN topical overlap, every claim that corroborates / contradicts / extends / exemplifies / supersedes an existing record must be expressed as a first-class RL record — not just hinted at in prose.

Why this matters:
- The mirror graph's edges, contradiction detection, and supersession propagation all run over RL records, not over prose hints.
- WikiLinks inside CL reasoning are informal; RLs are auditable, taggable, and survive refactor-on-touch.
- Without RLs, the corpus is a collection of independent literature notes; with RLs, it becomes the connected argument the project is for.

**How to apply** at every walk:
- For each CL whose reasoning cites another KN or CL, mint an RL with the appropriate `Relation_Type` (supports / contradicts / extends / exemplifies / summarizes / references / precedes / supersedes — closed vocabulary, see doc 08).
- For each KN pair sharing substantive topical overlap, mint an RL capturing the connection.
- File RLs at `/Notes/Relations/` (indexed alongside `/Notes/Claims/` and `/Notes/Literature/`).
- Tag RLs per the canonical axes: `pkim/relation`, `relation/type/<…>`, `relation/status/<proposed|reviewed>`, `relation/confidence/<low|medium|high>`, plus inherited topical tags from both endpoints.

If no cross-citations exist for a fresh CL set, that's a profiling gap — pause and surface to the operator rather than silently producing an isolated KN.

## How to know you are doing it right

- the ledger names the EV set in the preamble, no `[[…|…]]` slots are empty
- every `fact` and `inference` claim has at least one resolved evidence WikiLink
- `assumption` and `open-question` claims have a one-sentence `note` explaining why
- the operator sees the ledger before any KN is written

## How to know you are doing it wrong

- the ledger has a single fact-typed claim with five EVs cited — usually a sign of a compound claim that should be split
- every claim is `inference` with `confidence: high` — implausibly clean; rerun with skepticism
- the prose summary describes what the *KN* says rather than what the *EV set* says — the ledger is upstream of the KN

## Related skills

- [`dt-audit-claim-evidence`](../dt-audit-claim-evidence/SKILL.md) — validates a written claim ledger or KN claim block
- [`dt-build-knowledge-note`](../dt-build-knowledge-note/SKILL.md) — the next step in Workflow 3; consumes this ledger
