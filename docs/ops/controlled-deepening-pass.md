# Controlled Deepening Pass

## Purpose

Stress-test the PKIM operating model on a harder but bounded corpus before a full deep pass.

This pass exists because the first 22 notes shaped the current workflow but are not enough evidence for scale. The controlled deepening pass must test the workflow against denser, messier, and overlapping sources before full-corpus work begins. Do not treat early success as full readiness.

## Corpus shape

Select sources that exercise the full range of processing difficulty:

- 5–10 dense PDFs or framework documents
- 5–10 ordinary articles
- 2–3 overlapping sources on the same topic
- 1 already-processed source (rerun)
- 1 source expected to produce multiple candidate notes
- 1 source expected to produce mostly supporting detail

## Required sequence

Run each step in order. Do not skip steps or collapse them. Skills are the operating method at every step; the command surface is the deterministic support layer the skills use internally.

0. **Pre-flight: verify DEVONthink field vocabulary** — before any relation work, confirm that all 8 closed-list relation types (`contradicts`, `exemplifies`, `extends`, `precedes`, `references`, `summarizes`, `supersedes`, `supports`) are present in the DEVONthink `Relation_Type` Selection field. A missing value will silently write an empty field at create time, producing `relation_missing_fields` errors in the graph audit with no write-time warning. Fix vocabulary gaps before starting.
1. `dt-health-check` — confirm runtime is clean before starting
2. `dt-health-check` / `dt-review-queue-health` — confirm capability probe passes and queue state is understood
3. `dt-profile-record` on each source — produce a concept set and candidate ledger entry
4. Review candidate triage — apply the candidate triage checkpoint before any write
5. `dt-resolve-canonical-note` per ready candidate — one at a time, in dependency order
6. `dt-build-knowledge-note` / `dt-build-relation-note` per resolved candidate
7. `dt-reconcile-relation-edge` — materialise and reconcile edges after note work
8. `dt-inspect-graph-neighbourhood` — confirm graph neighbourhood is sane
9. `dt-sync-export-mirror` — sync and validate mirror output
10. `dt-audit-graph-corpus` — run graph audit and review findings
11. Record findings in a run summary including the documentation debt section below

## Candidate ledger requirement

Every multi-concept profile run in this pass must produce or update a candidate ledger.

The ledger must record for each source:

- source record
- candidate IDs
- candidate fingerprints
- candidate class
- triage outcome
- resolution result
- note mutation result
- edge materialisation result
- deferred candidates
- blocked edges
- operator decisions

A pass without a candidate ledger has no traceability.

## Stop conditions

Stop the pass and do not continue until the cause is understood if:

- candidate notes are being over-minted (more than the concept set justifies)
- relation edges become mostly weak or duplicative
- mirror output becomes unreliable
- candidate fingerprints are unstable on rerun
- repair or audit outputs are too noisy to act on
- workflows require undocumented operator memory to execute

## Rerun stability requirement

At least one already-processed source must be rerun during this pass.

For that rerun:

1. Rerun `dt-profile-record`
2. Compare candidate fingerprints against the previous run
3. Confirm main candidates are stable
4. Confirm existing notes are resolved rather than duplicated
5. Confirm existing edges are recognised rather than duplicated
6. Record differences in the candidate ledger

The full deep pass must not begin until one rerun has completed without duplicate note creation or relation-note duplication.

## Mirror validation requirement

Before closing this pass, confirm mirror validation:

- every approved knowledge note has valid YAML frontmatter
- every mirrored note includes `PKIM_ID`, `DocRole`, `Review_State`, and source links where applicable
- relation notes export with `Source_Item`, `Target_Item`, `Relation_Type`, and rationale
- stale mirror records are explainable
- no exported file is missing required graph or provenance fields

Mirror validation failure blocks the full deep pass.

## Run summary template

Record findings in `runs/<pass-id>/controlled-pass-summary.md`.

### Pass summary sections

**Sources processed** — list each source with its `SourceCoverageStatus`.

**Candidate ledger reference** — `runs/<pass-id>/candidate-ledger.json`.

**Evaluation scores** — complete the rubric from `docs/ops/controlled-pass-evaluation-rubric.md` for each source.

**Stop conditions triggered** — list any stop conditions hit and what was done.

**Documentation debt** — see section below.

## Documentation debt

For every step in the pass, record where the operator relied on tacit knowledge rather than documented process.

For each item:

- what happened
- where it should be documented
- whether it blocks scale
- proposed doc update

This is not optional. If the documentation debt section is empty after a real pass, it means the operator was not paying attention.
