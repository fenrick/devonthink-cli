---
name: dt-intake
description: Sweep a DEVONthink /Inbox and fan out one Sonnet subagent per record to profile, enrich metadata + tags, author any warranted KN or RL, and file it. Use when the user says 'process the inbox', 'triage the captures', 'sweep the inbox', 'did you move the source files out of /Inbox', or names a single record they've just captured. Ends only when the inbox is empty for the scoped database or every remaining record is surfaced as needs-human.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. Assumes [`pkim-primer`](../pkim-primer/SKILL.md) has been read.

# dt-intake

## Purpose

Sweep an `/Inbox` and turn its content into properly-classified, tagged, enriched, filed records. This is PKIM's day-to-day workflow: from "there's a PDF in the inbox" to "it's an EV in `/Sources/Imported`, tagged and metadata-stamped, with a linked KN authored from it if warranted."

The sweep is the parent's job. Per-record work fans out — one Sonnet subagent per record, one workflow, one outcome. The parent orchestrates the batch and aggregates.

## When to invoke

- The operator asks about the inbox: "process the inbox", "triage what's queued", "did you move the source files out of `/Inbox`".
- A batch capture just landed (web clips, imported files, scanned pages).
- The operator names a specific record they just captured — the sweep still runs, just scoped to one UUID.
- The `Needs Filing` / `Needs Profile` / `Needs Knowledge Note` smart groups are non-empty and the operator asks about them.

## Overview

```
parent (this skill)
├── enumerate the scoped inbox via search_records (or accept a specific UUID)
├── build a batch ledger, one row per record
├── fan out — for each record, spawn one Sonnet subagent with the per-record brief
├── aggregate returns; classify into filed / enriched / needs-human / error
└── surface any needs-human list to the operator
```

## Preflight

Run the primer's preflight (`is_running` + `get_databases`). Do not proceed if `PKIM-Pilot` is missing on a scratch run, or if the target evidence database isn't open. If the preflight surfaces a gap, invoke [`dt-bootstrap`](../dt-bootstrap/SKILL.md) first.

## Parent workflow

### 1. Scope the sweep

Either the operator has named a specific record (skip enumeration; the batch has one entry), or you're processing an inbox:

```
mcp__devonthink__search_records
  query: "location:/Inbox/"                # or /Needs Profile, /Needs Filing, etc.
  database_uuid: <target-db-uuid>
  limit: 50                                # cap batch size; loop for more
```

Record the returned UUIDs into a ledger. In memory or a scratch file — no runtime-required manifest.

### 2. Fan out

For each record UUID, spawn a subagent. See [references/per-record-agent-brief.md](references/per-record-agent-brief.md) for the exact prompt template — fill the UUID / database-name / current-location slots and dispatch.

**Sonnet tier, general-purpose agent.** Do not use Opus for per-record work — the per-record scope doesn't need it and burns budget.

**Fan out in parallel.** Batch subagent spawns in one message so they run concurrently. Cap simultaneous spawn at ~8 — the DT MCP server serialises some writes, and greater parallelism gets throttled rather than sped up.

### 3. Aggregate

Each subagent returns a structured JSON summary (shape defined in the brief). Bucket them:

- `filed` — reached `Review_State: filed`.
- `enriched-needs-review` — metadata + tags applied, but the operator should sign off before it's fully done.
- `needs-human` — the subagent hit a decision it deliberately didn't make.
- `error` — MCP tool errors or preconditions the subagent couldn't recover from.

### 4. Surface + report

Report to the operator:

- Counts per bucket.
- The specific `needs-human` list (name, DT UUID, one-line reason).
- Any `error` entries with the MCP tool error message verbatim.

## Completion criterion

The sweep is complete when **both**:

1. `search_records query: "location:/Inbox/"` returns zero results for the scoped database *or* every remaining record's `review_state` is `needs-human` (surfaced deliberately, not silently skipped).
2. Every subagent has returned; no dispatched UUID is still pending.

If the batch capped at 50 and the inbox has more, this run isn't complete — kick off the next batch or hand off to the operator with the current-batch summary. Do not declare success on a partially-swept inbox.

## Per-record work — read the references

The subagent's workflow is the substance of this skill. The parent's job is scope + dispatch + aggregate; every real decision (class, PKIM_ID minting, metadata, tags, KN/RL authoring, filing destination) happens in the subagent per the references.

| Reference | What it covers |
|---|---|
| [references/per-record-agent-brief.md](references/per-record-agent-brief.md) | The exact prompt template dispatched to each subagent — fill the slots and paste |
| [references/intake-per-record.md](references/intake-per-record.md) | The nine-step per-record workflow the subagent executes; the canonical shape of the returned JSON |
| [references/kn-authoring.md](references/kn-authoring.md) | When a KN is warranted; how to compose the body; the create + stamp + tag chain |
| [references/rl-authoring.md](references/rl-authoring.md) | When an RL is warranted; the closed `Relation_Type` vocabulary; endpoint handling |
| [references/safe-file-rules.md](references/safe-file-rules.md) | Filing destinations per class + kind; the allowlist |
| [references/merge-vs-create.md](references/merge-vs-create.md) | Canonical-note resolution when a candidate KN already exists — merge, supersede, or fresh |

## Stop conditions

The **parent** stops the sweep (does not spawn more subagents) when:

- A DT MCP call from the parent's own orchestration returns an unrecoverable error.
- The `needs-human` count exceeds ~3 per batch — surface those first before piling on more.
- The operator has said "stop" or the session is wrapping up.

Individual **subagents** stop and return `needs-human` when:

- The record's class is genuinely ambiguous.
- The filing destination isn't on the allowlist.
- A KN candidate would duplicate an existing canonical KN — merge-vs-create is an operator decision.
- A cross-database step needs judgement about the item-link target.

## Anti-patterns

- **Batching too big.** Cap at ~50 per sweep. Larger runs lose ledger legibility and produce reports the operator won't read.
- **Serial subagents.** Sonnet is fast; parallel fan-out is why this skill scales. Serialising for no reason turns a 30-second sweep into a 5-minute one.
- **Parent doing per-record work directly.** The parent orchestrates; per-record judgement is the subagent's job. If the parent starts calling `get_record_text` on individual records, the design has drifted — dispatch instead.
- **Skipping the RL step.** A KN that cites two EVs and no RL was authored is an incomplete walk. See `references/rl-authoring.md`.
- **Filing before enriching.** Records leave `/Inbox` only after metadata + tags settle. A record in `/Sources/Imported` with `mdreview_state: inbox` is a bug.

## Related skills

- [`pkim-primer`](../pkim-primer/SKILL.md) — prerequisite; the record classes, tag axes, and metadata schema referenced throughout the per-record workflow.
- [`dt-bootstrap`](../dt-bootstrap/SKILL.md) — install missing canonical config if preflight surfaces a gap.
- [`dt-audit`](../dt-audit/SKILL.md) — the periodic-audit counterpart. Intake is per-record ingestion; audit is corpus-wide graph health.
