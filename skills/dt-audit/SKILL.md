---
name: dt-audit
description: Graph-health audit for the PKIM corpus. Finds broken RL endpoints, dangling WikiLinks, zombie claims (retired evidence still cited), corpus-level contradictions, orphan CLs, KN/RL discipline violations. Use this weekly, before scaling ingest, or after a batch of retirements/supersessions. Not for operational reports (queue depth, metadata coverage).
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. Read [`pkim-orient-and-setup`](../pkim-orient-and-setup/SKILL.md) first.

# dt-audit

## Purpose

Confirm the corpus's graph is still coherent. This is *not* a queue-depth or metadata-coverage report — it's a semantic-health check that finds broken links, retired-evidence citations, and contradictions.

Output is a findings list the operator can act on (or dispatch back through `dt-intake` for repair). The skill does not mutate records except when authorised for specific auto-fix classes.

## When to use

- Weekly, as part of a maintenance cadence.
- After a wave of EV retirements / supersessions (the ripple through KN/CL evidence links is easy to miss).
- Before scaling ingest — an audit-clean corpus is safer to grow.
- When something feels off: a KN links to a `Trashed` EV, a smart group empty when it shouldn't be, etc.

## What it checks

Six finding classes. Each has a dedicated reference doc.

| Class | Reference | What it detects |
|---|---|---|
| Broken RL endpoints | [references/broken-endpoints.md](references/broken-endpoints.md) | `Source_Item` / `Target_Item` item links that don't resolve to a live record |
| Dangling WikiLinks | [references/dangling-wikilinks.md](references/dangling-wikilinks.md) | `[[Name]]` references in KN/CL bodies that don't resolve inside `PKIM-Knowledge` |
| Zombie claims | [references/zombie-claims.md](references/zombie-claims.md) | Claims (in `## Claims` blocks or as CL records) supported only by retired EVs |
| Corpus contradictions | [references/contradictions.md](references/contradictions.md) | Two KNs citing the same EV with opposing edge classes; opposing CLs about the same subject |
| Orphan records | [references/orphan-detection.md](references/orphan-detection.md) | CLs without a resolvable parent KN; KNs without any cited EV; RLs with endpoints in the same class (usually a mistake) |
| Discipline violations | [references/discipline.md](references/discipline.md) | Untagged records; records missing required metadata fields; RLs without prose rationale; KNs without a `## Claims` block that are `KnowledgeStatus: published` |

## Overview

```
parent (this skill)
├── read the corpus (search_records for each class of concern)
├── run each check class in turn (some fan out; some inline)
├── aggregate findings
├── classify by severity (broken links + zombie claims: high; discipline nits: low)
├── decide routing:
│      auto-fixable → apply if authorised
│      human-triage → include in the surfaced report
├── write the audit summary
└── surface to operator
```

Unlike `dt-intake`, the audit doesn't need one subagent per record — most checks are corpus-level queries that don't benefit from fan-out. But specific per-record deep checks (e.g. "read the KN body and match every WikiLink") can be dispatched to Sonnet subagents in parallel if the finding count is large. Keep it simple: run the query first, fan out only when the finding count justifies it.

## Preflight

Run `pkim-orient-and-setup` §Preflight. Additionally check the smart-group set is intact — if the canonical smart groups are stale, the audit will miss things:

```
mcp__devonthink__lookup_records
  location: "/Needs Human Review"
  database_uuid: <PKIM-Knowledge>
```

Repeat for each canonical smart group. If any are missing, run `pkim-orient-and-setup` §Setup first.

## Workflow

### 1. Broken RL endpoints

For each RL in `PKIM-Knowledge`:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:relation"
  limit: 1000
```

For each RL, read `Source_Item` and `Target_Item` from custom metadata. Extract the UUID from each item link, then check resolution via `get_record_properties`. If either endpoint returns "record not found", the RL is broken.

Findings: `{class: broken-endpoint, uuid, pkim_id, endpoint: source|target, broken_uuid}`.

**Auto-fix routing:** none. Broken endpoints need human triage — the target may have been retired deliberately (and the RL should be trashed) or moved (needs re-linking).

### 2. Dangling WikiLinks

For each KN and CL body in `PKIM-Knowledge`, use DT MCP directly:

```
mcp__devonthink__get_record_unlinked_wiki_links
  uuid: <record-UUID>
```

DT returns the list of `[[Name]]` references that don't resolve within the database. Anything returned is a dangling WikiLink.

Findings: `{class: dangling-wikilink, uuid, pkim_id, wikilink_text, likely_target?}`.

**Auto-fix routing:** if the WikiLink target is an EV (cross-database), the fix is to convert `[[EV-...|Name]]` to `[Name](x-devonthink-item://<uuid>)` — but only if the target UUID can be found. Route to `needs-human` when target is ambiguous.

### 3. Zombie claims

For each KN / CL with claim material:

- Read `## Claims` block (KN) or the claim's `## Evidence` section (CL).
- For each cited EV item link, extract the UUID and check its `evidencestatus`.
- If all citations are `retired` or `superseded`, the claim is a zombie.

See [references/zombie-claims.md](references/zombie-claims.md) for the exact walk.

Findings: `{class: zombie-claim, uuid, pkim_id, claim_text, retired_evidence_uuids}`.

**Auto-fix routing:** none. Zombies need human triage — either the claim needs new supporting evidence, or the claim itself retires.

### 4. Corpus contradictions

Detect via two paths:

- **Shared-EV opposing edges**: find EV → KN_A `supports` and EV → KN_B `contradicts` (or any two RLs with the same target EV and opposing types). SQL-like walk over RL records.
- **Same-subject opposing CLs**: CLs whose `primarytopic` matches and whose `claimtype`/text implies mutual exclusion.

See [references/contradictions.md](references/contradictions.md).

Findings: `{class: corpus-contradiction, records: [uuid_a, uuid_b], shared_evidence: uuid}`.

**Auto-fix routing:** none. Contradictions are the audit's whole point — they're for the operator to triage.

### 5. Orphan records

For each CL: is there a resolvable parent KN? Missing → orphan.

For each KN: is there ≥ 1 cited EV via item links or evidence-linked RLs? None → orphan candidate (allowed for `topic`/`project` KNs; not for `literature`/`synthesis`).

For each RL: are Source_Item and Target_Item both resolvable AND do they point at records of appropriate classes? An RL between two EVs, or two RLs, is usually wrong.

Findings per class in [references/orphan-detection.md](references/orphan-detection.md).

**Auto-fix routing:** none.

### 6. Discipline violations

For each record class:

- Untagged records (structural tags missing or topical tag count = 0).
- Records missing required metadata fields.
- RLs without prose in the `## Why this relation exists` section.
- KNs with `KnowledgeStatus: published` and no `## Claims` block.

See [references/discipline.md](references/discipline.md) for the exact per-class checks.

**Auto-fix routing:** untagged records where the topical set can be inherited from the parent (CL from KN, RL from endpoints) — auto-apply the inherited set and update `automation_last_run_state: ok`. Everything else → `needs-human`.

### 7. Aggregate

Group findings by class. Count. Rank by severity:

- **High**: broken-endpoint, zombie-claim, corpus-contradiction.
- **Medium**: dangling-wikilink, orphan-cl, orphan-kn (literature/synthesis).
- **Low**: discipline violations.

### 8. Report

Emit a summary block to the operator:

```
dt-audit run 2026-07-15
--
Broken RL endpoints:     3
Zombie claims:           5
Corpus contradictions:   1
Dangling WikiLinks:      8
Orphan CLs:              2
Orphan KNs:              4
Discipline violations:  17

Top-severity items (first 10):
  1. RL-20260601-0003 → source_item unresolved (record trashed 2026-06-15)
  2. KN-20260503-0002 → claim "..." backed only by EV-20260101-0007 (retired)
  ...
```

If any auto-fixes were applied (only in the discipline class), list them separately.

## Stop conditions

- Any DT MCP call returns a hard error → stop and surface.
- The audit finds > 100 high-severity findings → stop; the corpus needs targeted human triage before continuing.
- The operator interrupts.

## Anti-patterns

- **Auto-fixing outside the sanctioned classes.** Zombies, contradictions, broken links are all human-triage. Don't try to be clever.
- **Running the audit against `PKIM-Pilot`** as if it were the real corpus. Pilot is scratch; findings there don't matter.
- **Producing operational reports (queue depth, metadata coverage, mirror drift) inside the audit.** Those are separate concerns; this skill is graph-health only.

## References

- [references/broken-endpoints.md](references/broken-endpoints.md) — RL endpoint validation
- [references/dangling-wikilinks.md](references/dangling-wikilinks.md) — WikiLink resolution + item-link conversion
- [references/zombie-claims.md](references/zombie-claims.md) — retired-evidence detection
- [references/contradictions.md](references/contradictions.md) — corpus-level contradictions
- [references/orphan-detection.md](references/orphan-detection.md) — CL/KN/RL orphan rules
- [references/discipline.md](references/discipline.md) — per-class discipline checks
- [../pkim-orient-and-setup/SKILL.md](../pkim-orient-and-setup/SKILL.md) — orientation

## Related skills

- [`pkim-orient-and-setup`](../pkim-orient-and-setup/SKILL.md) — prerequisite.
- [`dt-intake`](../dt-intake/SKILL.md) — the per-record counterpart. Audit surfaces findings; intake fixes them one record at a time.
