---
name: dt-reconcile-relation-edge
description: Reconcile relation notes after candidate-edge materialisation, deciding per edge whether to leave, strengthen, supersede, or retire it. Make sure to use this skill after staged candidate sessions have created or updated notes and materialized candidate edges.
compatibility: Works in any runtime that can search for relation notes by Source_Item or Target_Item, read linked records, and call the shared write paths for bounded relation updates.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-reconcile-relation-edge

This skill now runs **after candidate-edge materialisation**, not before.

## What this skill is for

Use it when a staged candidate session has:

- resolved candidate notes to concrete note identities
- materialized new relation notes from `candidate_edges[]`
- changed focal notes enough that existing edges may now be stale or duplicated

## Why this matters

Materializing edges is not the same as proving the local relation layer is clean. Without a reconciliation step, the session can leave duplicate, weak, or obsolete relation notes behind and call that progress.

## Workflow

1. Start from one resolved focal note or one staged focal set.
2. Find all relation notes touching that resolved note.
3. Include any freshly materialized relation notes from the same session.
4. Assess each edge:
   - leave
   - strengthen
   - supersede
   - retire
5. Prefer reconciling edges created by the current session before widening scope.

## Required session context

- candidate-to-note resolution map
- edge materialisation queue/results
- list of newly affected focal notes

## How to know you are doing it right

You are doing this skill correctly when:

- the relation notes touching the focal set are explicitly reviewed
- duplicate or stale edges are classified rather than ignored
- you keep the scope bounded to the current focal session

You are doing it badly when:

- newly materialized edges are assumed correct by default
- stale edges are left in place because they are inconvenient
- the assessment drifts beyond the focal notes without reason

## What not to do

- Do not reconcile candidate edges that have not been materialized.
- Do not create batch mutations here.
- Do not inspect beyond the focal notes selected by the session orchestrator.

## Output

Produce an edge-reconciliation result with:

- focal note or focal set
- relation notes reviewed
- per-edge decision (`leave`, `strengthen`, `supersede`, `retire`)
- rationale for changed edges
- follow-on write actions if required

## Preferred tool path

```bash
# Typed metadata search via the PyObjC ScriptingBridge transport.
pkim search --database "PKIM-Knowledge" --metadata "Source_Item=<focal-item-link>" --format json
pkim search --database "PKIM-Knowledge" --metadata "Target_Item=<focal-item-link>" --format json

# Per-record dependency picture before edge work.
pkim deep-profile --record "<focal-ref>" --format json

# Single-relation update (rationale, status, normalize body to canonical shape).
pkim update-relation-note --note "<relation-ref>" --rationale "<text>" --format json
```

### Bulk repair: missing ## Endpoints body sections

When the discipline audit (the audit chain: `mcp__devonthink__search_records` + `get_record_text` + `get_record_properties`; findings emitted by the skill) reports a wave of `missing-body-wikilink` findings — relation notes whose `Source_Item`/`Target_Item` metadata is present but whose body has no `## Endpoints` section with PKIM_ID WikiLinks — reach for the bulk repair before working through them one at a time:

```bash
# Dry-run preview shows what would change.
pkim repair-rl-endpoints --database PKIM-Knowledge

# Live execution (gated).
PKIM_ALLOW_PRODUCTION_WRITES=true pkim repair-rl-endpoints --database PKIM-Knowledge --live
```

The repair resolves each `Source_Item` / `Target_Item` UUID to its PKIM_ID via the bridge, inserts a canonical `## Endpoints` section with `[[PKIM_ID|Name]]` WikiLinks immediately after the H1 heading, and verifies the rewrite by re-reading. Idempotent — records that already have the section are reported as `already-ok`.
