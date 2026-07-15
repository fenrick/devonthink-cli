---
name: dt-review-metadata-overview
description: Review one or more PKIM metadata-overview reports to determine coverage quality, identify the highest-value metadata gaps, and decide whether dashboard output is operationally useful or misleading. Make sure to use this skill whenever the user asks about metadata coverage, dashboard quality, missing field patterns, or what to fix next in the corpus metadata layer.
compatibility: Works in any runtime that can call the shared `pkim metadata-overview` command and read the emitted JSON/dashboard note content.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-review-metadata-overview

This skill exists because a metadata dashboard can be technically correct and still operationally useless. The job is not to admire coverage percentages. The job is to decide what the numbers mean and what to fix next.

## What this skill is for

Use it to answer:

- what metadata coverage looks like for a selected slice
- which missing fields actually matter
- whether the dashboard scope is clean enough to trust
- what the next corrective metadata work should be

The result should be a short operational reading of the dashboard, not just a dump of counts.

## Why this matters

Coverage without scope discipline produces noise. Good review requires:

- the right slice
- the right fields
- examples of missing records
- a clear read on which gaps are real blockers

Without that, dashboards become decorative honesty.

## Workflow

1. Generate or read the relevant report:
   ```bash
   pkim metadata-overview --database PKIM-Pilot --doc-role evidence --format json
   ```
2. Check the slice definition first:
   - database
   - doc-role filter
   - exclusions for operations and test seeds
3. Read:
   - `coverage_by_field`
   - `by_doc_role`
   - `by_review_state`
   - `missing_examples`
4. Identify:
   - high-value missing fields
   - false-noise caused by bad scoping
   - next corrective action
5. If the user wants a live dashboard note, rerun with `--live`.

## How to know you are doing it right

You are doing this skill correctly when:

- you separate scope problems from metadata problems
- you prioritize missing fields that block workflow
- you use missing examples, not just percentages

You are doing it badly when:

- you quote coverage with no interpretation
- you treat an unfiltered database-wide count as useful by default
- you recommend fixing low-value fields first

## What not to do

- Do not confuse a full-database dashboard with an operational slice.
- Do not recommend decorative dashboard changes before fixing scope or metadata quality.
- Do not assume an empty slice is a bug; sometimes the database is actually empty.

## Output

Produce a short review with:

- slice reviewed
- top metadata gaps
- whether the dashboard is trustworthy
- next corrective action

## Preferred tool path

```bash
pkim metadata-overview --database PKIM-Pilot --doc-role evidence --format json
```
