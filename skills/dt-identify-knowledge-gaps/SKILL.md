---
name: dt-identify-knowledge-gaps
description: Find approved evidence records that have no linked knowledge note, triage which ones genuinely warrant note creation, and hand off each candidate to dt-build-knowledge-note in priority order. Make sure to use this skill whenever the user asks what evidence has not been turned into a note yet, which approved records are waiting for synthesis, where the knowledge layer has gaps, or how to drain the evidence backlog.
compatibility: Works in any runtime that can search evidence databases by Review_State and Knowledge_Link_State, read record content to assess synthesis readiness, and hand off to dt-build-knowledge-note.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-identify-knowledge-gaps

This skill exists because the pipeline from approved evidence to knowledge note has no automatic drain. Records accumulate in the approved state, each one a potential knowledge note that was never created. Without a dedicated skill to surface and triage these gaps, the knowledge layer falls behind the evidence layer silently.

Your job is to find the gap, assess which evidence genuinely warrants a knowledge note, and hand off the candidates in the right order.

## What this skill is for

Use it when:

- evidence has been profiled and approved but the knowledge layer has not caught up
- the user wants to know what approved evidence is waiting for synthesis
- you want to drain the `Knowledge_Link_State` backlog across one or more databases
- a periodic review pass should check whether any approved evidence has been overlooked

The result should be a prioritised list of synthesis candidates and a handoff to `dt-build-knowledge-note` for each confirmed candidate.

## Why this matters

Not every approved evidence record needs a knowledge note. But every approved record that warrants a note and doesn't have one represents lost synthesis. The evidence was profiled, reviewed, and approved — the investment was made. The knowledge capture was not.

This gap grows silently because no queue explicitly surfaces it. `Needs Profile` clears when `Review_State=profiled` is set. `Needs Filing` clears when the record is filed. But there is no equivalent automatic queue for "approved evidence that should have generated a knowledge note." This skill is the manual drain for that queue.

## Workflow

Follow this sequence.

1. Identify the target databases. Default to all open evidence databases. Confirm scope with the user if processing more than one database.
2. Query for approved evidence records with no knowledge link:
   ```bash
   pkim search-notes \
     --database "<evidence-db>" \
     --doc-role evidence \
     --review-state approved \
     --field "Knowledge_Link_State" \
     --value "" \
     --format json
   ```
3. Also query for records where `Knowledge_Link_State` is explicitly `unlinked` (set but not resolved):
   ```bash
   pkim search-notes \
     --database "<evidence-db>" \
     --doc-role evidence \
     --review-state approved \
     --field "Knowledge_Link_State" \
     --value "unlinked" \
     --format json
   ```
4. Combine the results. Remove any records already linked (where `Knowledge_Link_State` is `linked` or carries a `KN-` reference).
5. For each candidate, read enough of the content to assess synthesis worthiness. Use the criteria below.
6. Classify each candidate:
   - `warrants-note` — contains a claim or insight worth preserving independently of the source document
   - `reference-only` — useful for citation but does not contain synthesis-worthy content; no note needed
   - `deferred` — warrants a note but requires more context or human decision before synthesis
7. Report the classified list to the user before proceeding. Show counts per class.
8. For each `warrants-note` candidate, in priority order:
   a. Switch to `skills/dt-build-knowledge-note/SKILL.md` (which will first gate through `dt-resolve-canonical-note`).
   b. After note creation, update `Knowledge_Link_State` on the source evidence record via `dt-apply-approved-metadata` to record the new note's `PKIM_ID`.
9. For `deferred` candidates, flag each with a reason and leave `Knowledge_Link_State` as `unlinked`.
10. For `reference-only` candidates, set `Knowledge_Link_State=reference-only` to prevent them from appearing in future gap queries.

## How to think about synthesis worthiness

### Warrants a note when

- the record makes a specific claim that the knowledge layer would benefit from preserving
- the record provides evidence for or against an existing knowledge note
- the record introduces a concept, framework, or methodology that other notes reference or should reference
- the record is likely to be cited repeatedly without a note, which produces fragile inline references rather than stable graph edges
- the record has been linked by the profile as a neighbour to existing knowledge notes — that signal suggests the knowledge layer already needs it

### Reference only when

- the record is a raw dataset, table, or appendix with no interpretive content
- the record is a bibliography entry, bookmark, or citation stub
- the record is a duplicate of another evidence record that already has a linked note
- the record contains only operational or procedural content with no knowledge claim

### Deferred when

- the record is part of an ongoing project and the synthesis is not yet stable
- the record contradicts an existing knowledge note and the contradiction needs human resolution before a note is written
- the record requires context from other records not yet approved

### Priority ordering for handoff

Process in this order:

1. Records with existing compare neighbours in the knowledge database — these have the clearest graph context and the lowest resolution risk
2. Records with the highest word count among the `warrants-note` set — more content typically means more synthesis opportunity
3. Records where `LastProfiledAt` is oldest — they have waited longest

Do not process more than five candidates in a single session without re-confirming scope with the user. Gap draining is incremental, not a bulk operation.

## How to know you are doing it right

You are doing this skill correctly when:

- you read candidate content before classifying — not just titles and metadata
- `reference-only` and `deferred` candidates are explicitly accounted for, not silently dropped
- `Knowledge_Link_State` is updated on every processed record after the note is created
- you do not create notes for records classified `reference-only`
- the handoff to `dt-build-knowledge-note` includes the resolution gate, not bypassing it

You are doing it badly when:

- you create notes for every approved record without assessing synthesis worthiness
- you leave `Knowledge_Link_State` unset after creating a note
- you skip the classification step and hand off everything
- you process the entire backlog in one session without scope confirmation

## What not to do

- Do not create knowledge notes for reference-only evidence.
- Do not bypass `dt-resolve-canonical-note` inside `dt-build-knowledge-note` for gap candidates — the gap does not grant a creation exemption.
- Do not update `Knowledge_Link_State` before the note is verified created.
- Do not leave deferred candidates without a recorded reason.
- Do not process more than five candidates per session without user confirmation of continued scope.

## Output

Produce a gap assessment report before handoff:

```json
{
  "run_id": "RUN-2026-04-17T16-10-00Z",
  "databases_scanned": ["PKIM-Evidence-Work"],
  "candidates_found": 12,
  "classified": {
    "warrants-note": 6,
    "reference-only": 4,
    "deferred": 2
  },
  "warrants_note_candidates": [
    {
      "pkim_id": "EV-20260417-0007",
      "name": "Allen GTD Tickler File overview",
      "word_count": 3400,
      "last_profiled_at": "2026-04-17T10:00:00Z",
      "priority": 1,
      "synthesis_rationale": "Contains specific claim about date-constraint mechanics not yet in knowledge layer"
    }
  ],
  "deferred_candidates": [
    {
      "pkim_id": "EV-20260416-0003",
      "deferred_reason": "Contradicts KN-20260415-0003; requires human resolution before synthesis"
    }
  ]
}
```

After processing, produce a completion report showing which candidates were handled and how `Knowledge_Link_State` was updated for each.

## Preferred tool path

Query for gap candidates (run for each evidence database in scope):

```bash
pkim search-notes \
  --database "PKIM-Evidence-Work" \
  --doc-role evidence \
  --review-state approved \
  --field "Knowledge_Link_State" \
  --value "" \
  --format json
```

Update `Knowledge_Link_State` after note creation (via `dt-apply-approved-metadata`):

```bash
pkim apply-metadata \
  --record "<evidence-pkim-id>" \
  --file runs/<run-id>/knowledge-link-intent.json \
  --live \
  --format json
```

Where `knowledge-link-intent.json` contains `{ "Knowledge_Link_State": "KN-20260417-0021" }`.
