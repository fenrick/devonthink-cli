# Controlled Pass Evaluation Rubric

Score each processed source from 0–2 on each dimension after processing is complete.

## Candidate quality

Does the concept set capture the right ideas from the source?

- 0 = missed key concepts or over-produced weak concepts
- 1 = usable but needs correction
- 2 = captures the right concept set with sensible triage

## Note quality

Are the knowledge notes produced clear and graph-worthy?

- 0 = bloated, vague, or duplicate
- 1 = useful but needs editing
- 2 = clear, canonical, graph-worthy

## Edge quality

Are the relation edges meaningful and well-typed?

- 0 = mostly weak, duplicate, or unclear
- 1 = plausible but needs review
- 2 = meaningful, traceable, and well typed

## Mirror quality

Are the exported mirror files complete and parseable?

- 0 = missing or malformed export or frontmatter
- 1 = usable with minor gaps
- 2 = complete and parseable

## Operator burden

How much correction was required after processing?

- 0 = heavy correction needed
- 1 = moderate correction
- 2 = light correction only

## Rerun stability

Does a second pass produce stable candidates without graph damage?

- 0 = duplicate notes or unstable candidates
- 1 = mostly stable but needs repair
- 2 = stable candidates and no graph damage

---

## Readiness threshold

Do not start the full deep pass unless the controlled pass averages at least **1.5** across candidate quality, note quality, edge quality, mirror quality, and rerun stability, with **no category scoring below 1**.

Operator burden is tracked but does not block the threshold. It informs documentation and skill work.

The threshold can be explicitly revised, but any revision must be recorded in `docs/design/00-source-reconciliation.md` with a rationale.

## How to apply the rubric

Score each source row individually. Then compute the column average across all sources. A single source scoring 0 in any blocking category does not automatically fail the pass — the average and minimum rules are across the whole corpus sample. A pattern of 0s in one category across most sources is a clear signal to stop.

Record all scores in the controlled pass summary at `runs/<pass-id>/controlled-pass-summary.md`.
