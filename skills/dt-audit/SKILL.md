---
name: dt-audit
description: Audit the PKIM graph for broken RL endpoints, dangling WikiLinks, zombie claims (retired evidence still cited), corpus-level contradictions, orphan CLs and KNs, and discipline violations. Use weekly, before scaling ingest, after a retirement or supersession wave, or when the user says 'audit the graph', 'check for zombies', 'are the RLs still resolving', 'find dangling links', 'run the health check'. Not for operational reports (queue depth, metadata coverage) — those aren't part of PKIM's discipline surface.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. Assumes [`pkim-primer`](../pkim-primer/SKILL.md) has been read.

# dt-audit

## Purpose

Confirm the corpus's graph is still coherent. Six finding classes — each detects a specific decay pattern that quietly accumulates as evidence retires, references break, and discipline slips. Output is a findings list the operator can act on (or that gets dispatched back through `dt-intake` for repair).

This is **not** operational reporting. Queue depth, metadata coverage, mirror drift, and scale-readiness are separate concerns — the audit is graph-health only.

## When to invoke

- Weekly maintenance cadence.
- After a wave of EV retirements or supersessions — the ripple through KN/CL evidence links is easy to miss otherwise; zombies get created quietly.
- Before scaling ingest — an audit-clean corpus is safer to grow.
- When something feels off: a KN links to a `Trashed` EV, a smart group is empty when it shouldn't be, an RL doesn't resolve when clicked.

## The six finding classes

Each has its own reference; walk them in order. Higher-severity classes come first so the audit's top-line report leads with what matters.

| Class | Reference | Detects | Severity |
|---|---|---|---|
| **Broken RL endpoints** | [references/broken-endpoints.md](references/broken-endpoints.md) | An RL's `Source_Item` / `Target_Item` UUID doesn't resolve (record deleted, trashed, missing) | High |
| **Zombie claims** | [references/zombie-claims.md](references/zombie-claims.md) | Claim's cited EVs are all `evidencestatus: retired` / `superseded` — the claim looks confidently backed but every citation is stale | High |
| **Corpus contradictions** | [references/contradictions.md](references/contradictions.md) | Two KNs cite the same EV with opposing edge classes; opposing CLs on the same subject | High |
| **Dangling WikiLinks** | [references/dangling-wikilinks.md](references/dangling-wikilinks.md) | `[[Name]]` in a KN or CL body doesn't resolve (usually a cross-database link that should be an item link) | Medium |
| **Orphan records** | [references/orphan-detection.md](references/orphan-detection.md) | CLs without a resolvable parent KN; literature/synthesis KNs with no cited evidence; RLs with malformed endpoints | Medium |
| **Discipline violations** | [references/discipline.md](references/discipline.md) | Untagged records; missing required metadata; RLs without prose rationale; published KNs without `## Claims` | Low |

Each reference is self-contained — detection walk, finding shape, triage guidance, auto-fix routing (if any). The parent workflow below just names when to invoke each, not what each does.

## Preflight

Primer's preflight, plus one canonical-smart-group spot check:

```
mcp__devonthink__is_running
mcp__devonthink__get_databases
mcp__devonthink__lookup_records location: "/Needs Human Review" database_uuid: <PKIM-Knowledge>
```

If the canonical smart groups are missing, the audit will miss things — run [`dt-bootstrap`](../dt-bootstrap/SKILL.md) first.

## Parent workflow

For each finding class, run its detection walk per the reference. Most classes are corpus-level `search_records` queries plus a follow-up per hit — they don't benefit from subagent fan-out because the queries themselves batch. Fan out to Sonnet subagents only when the follow-up count crosses ~50 records and the per-record read + judgement is substantial (only really applies to dangling-WikiLink and zombie-claim walks on a large corpus).

1. **Broken RL endpoints** — walk every RL; for each, extract endpoint UUIDs and resolve.
2. **Zombie claims** — walk every KN's `## Claims` block and every CL's `## Evidence`; check each cited EV's `evidencestatus`.
3. **Corpus contradictions** — build the shared-EV opposing-RL index; walk supersession chains; check same-subject opposing CLs.
4. **Dangling WikiLinks** — for each KN and CL, ask DT: `get_record_unlinked_wiki_links`.
5. **Orphan records** — check CL → parent-KN resolution, KN → cited-EV existence, RL → endpoint-class validity.
6. **Discipline violations** — tag completeness, required metadata presence, RL rationale prose, published-KN claim block.

Aggregate findings by class. Rank by severity from the table above.

## Auto-fix

Only two classes have any auto-fixable subset, and only when the fix is *mechanically obvious*:

- **Dangling WikiLinks** — `[[EV-YYYYMMDD-NNNN|Name]]` where the EV resolves via `search_records mdpkim_id:<id>` and returns exactly one hit → build the item-link form and patch the body via `update_record_content mode: "patch"`. Requires the operator to have authorised discipline auto-fix.
- **Discipline / untagged records** — for CLs and RLs where the topical tag set is inheritable from the parent KN or endpoints, apply the inherited set via `set_record_tags`. EVs and standalone KNs stay on the human-triage path — topical tags need content-reading judgement.

Everything else — broken endpoints, zombies, contradictions, orphans — routes to human triage. The audit surfaces; the operator decides.

## Completion criterion

The audit is complete when **all six** classes have been walked to their natural end:

1. Every RL in scope has had both endpoints resolved (or explicitly logged as broken).
2. Every KN's claim block and every CL's evidence section has been walked, and every cited EV has been checked for `evidencestatus`.
3. The shared-EV opposing-RL index has been built across every RL in scope; supersession chains walked to termination.
4. Every KN and CL has had `get_record_unlinked_wiki_links` called on it.
5. Every CL, literature-KN, synthesis-KN, and RL has had its structural expectations checked.
6. Every record in scope has had its tag set + required metadata checked.

Anything less is partial. Do not declare success on a subset — a partial audit that says "clean" is worse than no audit at all, because the operator trusts it. If time or budget requires a scoped run, state the scope explicitly in the report ("audited PKIM-Knowledge only; PKIM-Evidence-* deferred").

## Report

Emit a summary block:

```
dt-audit run 2026-07-15
--
Broken RL endpoints:     3
Zombie claims:           5
Corpus contradictions:   1
Dangling WikiLinks:      8
Orphan records:          6
Discipline violations:  17

Top-severity items (first 10):
  1. RL-20260601-0003 → source_item unresolved (target trashed 2026-06-15)
  2. KN-20260503-0002 → claim "..." backed only by EV-20260101-0007 (retired)
  ...

Auto-fixes applied this run:
  - 3 CLs re-tagged from parent KN topical set
  - 2 dangling WikiLinks converted to item links
```

If nothing was auto-fixed, omit that section rather than printing an empty one.

## Stop conditions

- A DT MCP call returns a hard error → stop and surface the exact call + response.
- The audit finds > 100 high-severity findings → stop; a corpus in that state needs targeted human triage before more scanning helps.
- The operator interrupts.

## Anti-patterns

- **Auto-fixing outside the sanctioned subsets.** Zombies, contradictions, broken endpoints all require human judgement; a "helpful" auto-retire of a zombie claim discards the author's intent.
- **Running against `PKIM-Pilot` as if it were the real corpus.** Pilot is scratch; findings there don't matter.
- **Producing operational reports inside the audit.** Queue depth, metadata coverage, mirror drift, scale-readiness — those are separate concerns. This skill is graph-health only.
- **Declaring success on a partial walk.** If you stopped early, say so.

## Related skills

- [`pkim-primer`](../pkim-primer/SKILL.md) — the vocabulary this audit's findings are expressed in. Prerequisite.
- [`dt-bootstrap`](../dt-bootstrap/SKILL.md) — repairs canonical smart groups if the audit's preflight surfaces one missing.
- [`dt-intake`](../dt-intake/SKILL.md) — per-record counterpart. Audit surfaces; intake fixes one record at a time.
