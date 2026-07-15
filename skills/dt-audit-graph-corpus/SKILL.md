---
name: dt-audit-graph-corpus
description: Scan the full PKIM knowledge graph for known failure patterns across notes, edges, metadata, and mirror state, then produce a prioritised issue report. Make sure to use this skill whenever the user asks for a graph health check, wants to find all zombie edges, wants to know what's broken across the corpus, asks for a full audit, or wants to find problems they don't already know about before beginning a reconciliation pass.
compatibility: Works in any runtime that can run multiple search-notes queries across PKIM databases and read the results. This skill is read-only — it diagnoses and prioritises but does not execute repairs. All repairs route through the appropriate sub-skills.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-audit-graph-corpus

This skill exists because neighbourhood-level reconciliation can only fix problems you know about. If you start a reconciliation pass on a specific record, you find the problems in its neighbourhood. You do not find the zombie edges three hops away, the orphaned note with no relations, or the approved record whose mirror file was never written.

Your job is to scan the corpus for the known failure patterns that individual record inspection cannot surface, then produce a prioritised issue report that feeds into targeted repair.

## What this skill is for

Use it when:

- you want to find problems you do not already know about
- repeated runs may have produced accumulated drift across the graph
- a pre-repair audit is needed before a large reconciliation pass
- the user wants a health check across the whole knowledge graph
- you suspect the corpus has degraded but do not know where

The result is a structured issue report, not a repair execution. Repairs route to the appropriate sub-skills.

## Why this matters

Individual skills are bounded by design. `dt-reconcile-relation-edge` works from a focal record outward. `dt-inspect-graph-neighbourhood` covers 1-hop. Neither can find zombie edges where both endpoints are in different neighbourhoods, nor orphaned notes that no focal record would naturally surface.

Corpus-level audit answers the question the record-centric skills cannot: what is the state of the graph as a whole, and where is it broken?

## Scope

A full corpus audit covers:

- `PKIM-Knowledge` — all knowledge and relation notes
- All configured evidence databases — for evidence-specific checks

Some checks are expensive on large corpora. The audit runs checks in priority order and can be stopped after any phase. Phase results are independently useful even if later phases are skipped.

## Failure pattern catalogue

These are the known failure patterns the audit checks for. Each has a severity and a repair skill.

| Pattern | Severity | Repair skill |
|---|---|---|
| Zombie edges — relation notes where one or both endpoints are archived or missing | High | `dt-reconcile-relation-edge` |
| Duplicate triplets — multiple relation notes with the same source+target+type | High | `dt-reconcile-relation-edge` |
| Records in `error` Review_State | High | `dt-recover-failed-write` then `dt-apply-approved-metadata` |
| **Metadata-edge violation** — scalar custom metadata field carries a PKIM_ID pointer to another record (banned by `19a-metadata-is-not-the-graph.md`) | High | `dt-apply-approved-metadata` |
| **Missing body WikiLink** — relation note body has no `## Endpoints` section with PKIM_ID WikiLinks matching `Source_Item`/`Target_Item` | High | `dt-reconcile-relation-edge` (single record) or `pkim repair-rl-endpoints --database <name>` (bulk) |
| **Missing evidence link** — relation note of type `supports`/`contradicts`/`supersedes` body has no `## Evidence` section with WikiLinks | High | `dt-reconcile-relation-edge` |
| **Missing claims** — KN with `KnowledgeStatus ∈ {reviewed, published}` has no `## Claims` section, or has claims of type `fact`/`inference` without evidence WikiLinks | High | `dt-build-claim-ledger` (re-ground from EV set) |
| **Legacy YAML header** — native note body starts with YAML frontmatter instead of the canonical MultiMarkdown header (WP0.5 contract) | Medium | `pkim migrate-mmd --database <name>` |
| Orphaned knowledge notes — no inbound or outbound relation notes | Medium | `dt-build-relation-note` or human review |
| Approved evidence with no knowledge link | Medium | `dt-identify-knowledge-gaps` |
| Approved notes with stale or absent mirror state | Medium | `dt-sync-export-mirror` |
| Knowledge notes missing `PKIM_ID` | Medium | `dt-apply-approved-metadata` |
| Relation notes missing mandatory rationale text | Medium | `dt-reconcile-relation-edge` strengthen |
| **Dangling WikiLink** — body WikiLink to a PKIM_ID that doesn't resolve to any known record | Medium | `dt-resolve-canonical-note` |
| **Unclassified custom-metadata field** — a field present on records but absent from the canonical registry in `19-synthesis-uplift-plan.md` Appendix A | Medium | Human review — classify (PROPERTY/INDEX-POINTER/DERIVED) or remove |
| Notes with `Review_State=approved` but `DocRole` unset | Low | `dt-apply-approved-metadata` |
| Notes with `RelationStatus=proposed` older than 30 days | Low | `dt-reconcile-relation-edge` advancement |
| Mirror files without a live canonical note | Low | Human review — may be intentional exports |

The seven **bolded** patterns are the discipline checks introduced under WP0.4 plus WP1.bonus / WP0.5. They run as a single read-only phase via `pkim audit-discipline --database <name>` or the `audit_discipline` MCP tool, and produce findings in the same shape as Phases 1–3.

### Bulk-migration commands the audit may surface

When the audit returns a wave of the same pattern across many records, the operator should reach for a bulk converter before working through them one at a time:

| If the audit reports… | Run |
| --- | --- |
| many `legacy-yaml-header` findings | `pkim migrate-mmd --database <name>` (dry-run first) |
| many `missing-body-wikilink` findings on relation notes | `pkim repair-rl-endpoints --database <name>` |
| `[[EV-...\|Name]]` WikiLinks in `## Evidence Links` sections of KN records | `pkim migrate-evidence-links --database <name>` — converts them back to `[Name](x-devonthink-item://UUID)` item-link form. EV records are cross-database; item-links are correct and are already visible to the mirror graph. Do **not** convert item-links to WikiLinks. |
| any of the above when a per-record diagnosis is wanted before bulk action | `pkim deep-profile --record <ref>` for the dependency picture; reads bridge + mirror + audit overlays |

All converters are dry-run by default and gated by `PKIM_ALLOW_PRODUCTION_WRITES=true` for live execution.

## Workflow

Follow this sequence. Each phase produces results independently — stop after any phase if the issue count is high enough to act on.

### Phase 1 — High severity checks

1. **Zombie edges**: Query all relation notes in `PKIM-Knowledge`. For each, check whether both `Source_Item` and `Target_Item` resolve to active records. Flag any where an endpoint is archived, missing, or `Review_State=error`.

   ```bash
   pkim search-notes \
     --database "PKIM-Knowledge" \
     --doc-role relation \
     --format json
   ```

   Then for each relation note, profile both endpoints to check their current state.

2. **Duplicate triplets**: From the full relation note set, group by source+target+type. Flag any group with more than one member.

3. **Error state records**: Query all databases for `Review_State=error`.

   ```bash
   pkim search-notes \
     --database "PKIM-Knowledge" \
     --review-state error \
     --format json
   ```

Report Phase 1 results before continuing to Phase 2.

### Phase 2 — Medium severity checks

4. **Orphaned knowledge notes**: Query all knowledge notes. For each, check whether any relation note references it as `Source_Item` or `Target_Item`. Flag notes with no inbound or outbound relation notes.

5. **Knowledge gaps**: Query all evidence databases for approved evidence with empty `Knowledge_Link_State`. (See `dt-identify-knowledge-gaps` for full triage — the audit surfaces the count; the gap skill handles triage.)

6. **Mirror drift**: Query all knowledge notes where `Review_State=approved`. For each, check `Mirror_State`. Flag notes where `Mirror_State` is absent or `stale`.

7. **Missing PKIM_ID**: Query all databases for records where `DocRole` is set but `PKIM_ID` is empty.

Report Phase 2 results before continuing to Phase 3.

### Phase 3 — Low severity checks

8. **Unset DocRole on approved records**: Query for `Review_State=approved` with empty `DocRole`.

9. **Stale proposed relations**: Query relation notes where `RelationStatus=proposed`. Flag any where `LastProfiledAt` (or creation date) is older than 30 days.

10. **Mirror files without live notes**: Compare the export mirror directory listing against the live note set. Flag any mirror file whose `pkim_id` frontmatter field does not match a live note. (This check requires mirror root access.)

Report Phase 3 results.

### Phase 4 — Produce the issue report

11. Aggregate all flagged items across all phases.
12. De-duplicate: a record may appear in multiple checks (for example, an archived note that is also a zombie edge endpoint should appear once under each check, not as a single combined entry).
13. Prioritise by severity, then by count of issues touching the same record (records with multiple issues should be repaired first).
14. Produce the structured issue report.
15. Do not begin repairs. Surface the report and let the user direct which issues to address first.

## How to think about audit scope

### Stopping early

Phase 1 results alone are often enough to direct a full repair cycle. If Phase 1 surfaces more than 20 high-severity issues, stop there and work through those before running Phase 2. A large corpus in poor health should be repaired incrementally, not audited completely before touching anything.

### Sampling on large corpora

For corpora above a few hundred knowledge notes, the zombie-edge and orphaned-note checks become expensive — they require profiling every endpoint of every relation note. On large corpora, sample: check a random 20% of relation notes for zombie endpoints rather than all of them, and note in the report that the check was sampled. A sampled audit is more useful than a skipped one.

### Mirror file check

The mirror-vs-live check (Phase 3, step 10) requires filesystem access to the export root. If the export root is not accessible from the current runtime, skip this check and note the omission in the report.

## How to know you are doing it right

You are doing this skill correctly when:

- you run phases in order and report between phases
- you do not begin repairs during the audit — the skill ends with a report, not actions
- you note sampled checks as sampled in the output
- you de-duplicate issues before prioritising — a record appearing in multiple checks is still one record
- the repair skill column in the issue report is specific enough that the next operator can act on it directly

You are doing it badly when:

- you start repairing while still auditing
- you run all phases even when Phase 1 has enough issues to stop and act
- you conflate the audit result with a completed repair
- you omit the repair skill reference from issues, leaving the user with a problem list but no path forward

## What not to do

- Do not execute repairs during an audit run. This skill ends with a report.
- Do not skip Phase 1 to get to lower-severity checks.
- Do not run the full audit on a corpus where Phase 1 already returned high issue counts — stop and repair first.
- Do not claim the corpus is healthy based on a sampled audit — report the sample coverage.
- Do not include issues without a corresponding repair skill reference.

## Output

Produce a structured issue report:

```json
{
  "run_id": "RUN-2026-04-17T16-20-00Z",
  "databases_audited": ["PKIM-Knowledge", "PKIM-Evidence-Work"],
  "phases_completed": ["phase-1", "phase-2"],
  "phases_skipped": ["phase-3"],
  "skip_reason": "Phase 1 returned 18 high-severity issues; stopped to allow repair",
  "summary": {
    "high": 18,
    "medium": 7,
    "low": 0
  },
  "issues": [
    {
      "severity": "high",
      "pattern": "zombie-edge",
      "record_pkim_id": "RL-20260412-0001",
      "detail": "Target endpoint KN-20260410-0002 is archived",
      "repair_skill": "dt-reconcile-relation-edge",
      "repair_action": "retire"
    },
    {
      "severity": "high",
      "pattern": "duplicate-triplet",
      "records": ["RL-20260417-0004", "RL-20260416-0009"],
      "detail": "Same source+target+type (supports). RL-20260417-0004 has stronger rationale.",
      "repair_skill": "dt-reconcile-relation-edge",
      "repair_action": "retire RL-20260416-0009"
    },
    {
      "severity": "medium",
      "pattern": "mirror-drift",
      "record_pkim_id": "KN-20260417-0021",
      "detail": "Mirror_State=stale; note content updated 2026-04-17, last export 2026-04-15",
      "repair_skill": "dt-sync-export-mirror",
      "repair_action": "re-export"
    }
  ],
  "sampled_checks": [],
  "result": "audit-complete"
}
```

## Preferred tool path

Phase 1 — all relation notes:

```bash
pkim search-notes \
  --database "PKIM-Knowledge" \
  --doc-role relation \
  --format json
```

Phase 1 — error state records:

```bash
pkim search-notes \
  --database "PKIM-Knowledge" \
  --review-state error \
  --format json
```

Phase 2 — all knowledge notes (for orphan and mirror checks):

```bash
pkim search-notes \
  --database "PKIM-Knowledge" \
  --doc-role knowledge \
  --format json
```

Phase 2 — knowledge gaps:

```bash
pkim search-notes \
  --database "PKIM-Evidence-Work" \
  --doc-role evidence \
  --review-state approved \
  --field "Knowledge_Link_State" \
  --value "" \
  --format json
```

Phase 4 — discipline audit (WP0.4):

```bash
# When auditing a database whose records cite records in other databases
# (e.g. PKIM-Knowledge KNs cite PKIM-Pilot EVs), pass --also-database for
# each evidence database so the dangling-wikilink detector doesn't
# false-positive on cross-database citations.
pkim audit-discipline \
  --database PKIM-Knowledge \
  --also-database PKIM-Pilot \
  --also-database PKIM-Evidence-Work \
  --also-database PKIM-Evidence-Personal \
  --also-database PKIM-Evidence-Server \
  --format json
```

The discipline audit covers the six WP0.4 patterns (metadata-edge violation, missing body WikiLink, missing evidence link, dangling WikiLink, unclassified field, plus relation-note structural checks). It runs over the PyObjC ScriptingBridge transport in-process — no `osascript` subprocess per record — and produces findings in the same shape as Phases 1–3. Aggregate the JSON output into the report before prioritising.
