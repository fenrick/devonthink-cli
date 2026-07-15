---
name: dt-inspect-graph-neighbourhood
description: Inspect graph consequences after a staged candidate session by walking each resolved focal note sequentially through a bounded 1-hop neighbourhood assessment. Make sure to use this skill after candidate note resolution and edge materialisation when the local graph state needs validation.
compatibility: Works in any runtime that can search for relation notes by Source_Item and Target_Item, read linked records, and consume the session’s candidate-to-note mapping and edge materialisation results.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-inspect-graph-neighbourhood

This skill still enforces a 1-hop boundary, but it now accepts a **focal session set** rather than assuming one source document produced one focal note.

## What this skill is for

Use it after a staged candidate session to:

- inspect each resolved focal note sequentially
- validate that newly created or updated notes sit cleanly in the graph
- check that freshly materialized edges did not create obvious duplicates or zombie paths
- confirm mirror and metadata consequences after local graph changes

## Why this matters

Local graph work can be internally consistent and still leave a damaged neighbourhood. This skill exists to catch the immediate structural consequences before that damage spreads into later reconciliation or mirror work.

## Workflow

1. Read the session artifact:
   - candidate-to-note resolution map
   - newly materialized edges
   - notes affected by create/update/merge/supersede
2. Build the focal note list from resolved candidates.
3. For each focal note, run the normal 1-hop neighbourhood assessment.
4. Report results per focal note, not as one unbounded graph walk.

## Scope discipline

- The session may contain many focal notes.
- Each focal note is still inspected independently with the existing 1-hop rule.
- Do not recursively widen from one focal note into another remote neighbourhood unless the session explicitly lists that remote note as another focal note.

## How to know you are doing it right

You are doing this skill correctly when:

- each focal note gets its own bounded assessment
- newly materialized edges are checked against existing local edges
- obvious duplicates, zombie paths, and missing follow-on actions are named explicitly

You are doing it badly when:

- the assessment turns into an unbounded graph crawl
- multiple focal notes are blurred into one result
- edge consequences are hand-waved instead of recorded per note

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

## What not to do

- Do not treat the whole concept set as one giant neighbourhood.
- Do not inspect candidate concepts that never resolved to note identities.
- Do not skip per-note sequencing; order matters because earlier reconciliation may change later focal contexts.

## Output

Produce a per-focal-note neighbourhood assessment with:

- focal note identity
- touching relation notes
- duplicate or zombie-edge findings
- metadata or mirror follow-up implications
- recommended next action

## Preferred tool path

```bash
pkim search-notes --field Source_Item --value "<focal-item-link>" --database "PKIM-Knowledge" --format json
pkim search-notes --field Target_Item --value "<focal-item-link>" --database "PKIM-Knowledge" --format json
pkim profile --record "<resolved-note-ref>" --format json
```
