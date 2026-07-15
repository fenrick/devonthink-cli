---
name: dt-intake
description: The inbox-to-filed-record walk. Sweeps a database's /Inbox, dispatches one subagent per record for profile + enrichment + optional KN/RL authoring + filing, aggregates results. Use this when the operator says "process the inbox", "triage what's queued", "did you move the source files out of the inbox", or names a specific record they've just captured.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. Read [`pkim-orient-and-setup`](../pkim-orient-and-setup/SKILL.md) first — this skill assumes you know the record classes, tag axes, metadata schema, and cross-database WikiLink rule.

# dt-intake

## Purpose

Turn incoming material into properly-classified, tagged, enriched, filed records. This is the main day-to-day PKIM workflow: everything from "there's a PDF in the inbox" to "it's an EV in `/Sources/Imported`, tagged and metadata-stamped, with a linked KN authored from it if warranted."

Per-record work is dispatched to a **subagent per record** — Sonnet tier is sufficient. The parent orchestrates the batch, keeps a ledger, and aggregates results. Each subagent gets one record, one workflow, one outcome, and returns.

## When to use

- Any time the operator asks about the inbox or triage.
- After a batch capture (web clips, imported files, scanned pages).
- When the `Needs Filing`, `Needs Profile`, or `Needs Knowledge Note` smart groups are non-empty.

## Overview

```
parent (this skill)
├── enumerate /Inbox records via search_records (or accept an explicit list)
├── build a ledger row per record
├── for each record → spawn subagent (Sonnet):
│      brief: this record's UUID + intake-per-record.md rules + dt-mcp-cheatsheet.md
│      subagent returns: {uuid, verdict, actions_taken, notes, needs_human?}
├── aggregate; write summary
└── surface any needs_human records to the operator
```

## Preflight (parent)

Run `pkim-orient-and-setup` §Preflight. Abort if any check fails. Do not proceed if `PKIM-Pilot` is missing on a scratch run, or if the target evidence database isn't open.

## Parent workflow

### 1. Scope the batch

Either the operator has named a specific record (skip enumeration), or you're processing an inbox:

```
mcp__devonthink__search_records
  query: "location:/Inbox/"        # or a specific smart group like /Needs Profile
  database_uuid: <target-db-uuid>
  limit: 50                        # cap batch size; loop for more
```

Record the returned UUIDs into a ledger (in memory or a scratch file under `tmp/`, your choice — no runtime-required manifest).

### 2. Dispatch subagents

For each record UUID, spawn a subagent (Sonnet tier). Use the Agent tool with a **per-record brief** — see [references/per-record-agent-brief.md](references/per-record-agent-brief.md) for the exact prompt template.

Recommended: **run subagents in parallel** for a batch (single message, multiple Agent tool calls). Sonnet is fast; a batch of ~10 records completes in wall-clock time comparable to running one serially.

Cap parallel spawn at ~8 to avoid MCP-server contention.

### 3. Aggregate

Each subagent returns a structured summary (see the brief). Aggregate into:

- `filed`: records that reached `Review_State: filed`.
- `enriched`: records that got metadata + tags but need human review.
- `needs_human`: records where the subagent hit a decision it couldn't make (ambiguous class, ambiguous destination, cross-DB confusion).
- `errors`: records the subagent couldn't process (MCP tool errors, missing custom metadata field, etc.).

### 4. Surface + report

Report to the operator:

- Counts per bucket.
- The specific `needs_human` list (name, DT UUID, one-line reason).
- Any `errors` with the tool error message.

If `Needs Filing` smart group is still non-empty after the run, either continue with the next batch or hand off.

## What subagents do (per record)

See [references/intake-per-record.md](references/intake-per-record.md) for the full per-record workflow. Summary:

1. Read the record (`get_record_properties`, `get_record_text` or `extract_record_content` for PDFs, `get_record_tags`, `get_record_custom_metadata`).
2. Classify: EV / KN / RL / CL (usually EV in the inbox — anything else has come in wrong).
3. Mint PKIM_ID if not already present (see `../pkim-orient-and-setup/references/record-classes.md` §PKIM_ID minting).
4. Enrich metadata: `docrole`, `pkim_id`, `evidencestatus`, `capturetype`, `origin_uri`, `primarytopic`. Use `set_record_custom_metadata mode="merge"`.
5. Apply tags: structural + topical per `../pkim-orient-and-setup/references/tag-axes.md`.
6. Author a KN if warranted (see [references/kn-authoring.md](references/kn-authoring.md)) — for evidence that genuinely calls for a KN, not routinely.
7. Author an RL if the KN cites another record (see [references/rl-authoring.md](references/rl-authoring.md)).
8. Move to the correct filing destination via `mcp__devonthink__move_record` (see [references/safe-file-rules.md](references/safe-file-rules.md)).
9. Set `review_state` to `filed` (or `needs-human` if stuck).
10. Return the structured summary.

## Stop conditions

The parent stops the batch (does not spawn more subagents) when:

- Any DT MCP call from the parent's own orchestration returns an unrecoverable error.
- The `needs_human` count exceeds a soft threshold (default: 3 per batch) — surface those first.
- The operator has said "stop" or the session is being wrapped up.

Individual subagents stop and return `needs_human` when:

- The record's class is genuinely ambiguous.
- The filing destination isn't in the safe-file allowlist.
- A KN candidate would duplicate an existing KN (`lookup_records` finds a match) — the operator decides merge vs supersede.
- Any cross-database step requires judgement about the item-link target.

## Anti-patterns

- **Batching too big.** Cap at ~50 records per batch; larger runs lose ledger legibility.
- **Serial subagents.** Parallel is faster and each subagent's context is independent — no reason to serialise.
- **Parent doing per-record work directly.** The parent orchestrates; per-record judgement is the subagent's job. If the parent starts calling `get_record_text` on individual records, the design has drifted.
- **Skipping the RL step.** A KN that cites two EVs and no RL was authored is incomplete. See [references/rl-authoring.md](references/rl-authoring.md).
- **Filing without enrichment.** Records get moved out of `/Inbox` only after metadata and tags are applied.

## References

- [references/per-record-agent-brief.md](references/per-record-agent-brief.md) — the exact prompt template for subagents
- [references/intake-per-record.md](references/intake-per-record.md) — the per-record workflow subagents follow
- [references/kn-authoring.md](references/kn-authoring.md) — when + how to author a KN
- [references/rl-authoring.md](references/rl-authoring.md) — when + how to author an RL
- [references/safe-file-rules.md](references/safe-file-rules.md) — filing destinations + allowlist
- [references/merge-vs-create.md](references/merge-vs-create.md) — canonical-note resolution when a candidate KN already exists
- [../pkim-orient-and-setup/SKILL.md](../pkim-orient-and-setup/SKILL.md) — orientation + setup (read first)

## Related skills

- [`pkim-orient-and-setup`](../pkim-orient-and-setup/SKILL.md) — prerequisite; establishes vocabulary and installs missing config.
- [`dt-audit`](../dt-audit/SKILL.md) — the periodic-audit counterpart. Intake is per-record ingestion; audit is corpus-wide health.
