# Discipline violations

Records that structurally exist but don't obey PKIM's authoring rules. Lower severity than the graph checks (broken endpoints, zombies, contradictions), but they're the friction the corpus accumulates when discipline slips.

## Untagged records

Every PKIM record must carry structural + topical tags per [../../pkim-primer/references/tag-axes.md](../../pkim-primer/references/tag-axes.md).

Walk:

```
mcp__devonthink__search_records
  database_uuid: <any PKIM database>
  query: "mdpkim_id:*"
```

For each record, read tags via `get_record_tags`. Check:

1. At least one `pkim/<class>` structural tag matching `docrole`.
2. At least one class-specific structural tag (e.g. `claim/type/*` for CLs, `evidence/status/*` for EVs).
3. At least one topical tag from `domain/`, `concept/`, `source/`, `year/`, `entity/`, or `method/` axes.

Finding shape:

```json
{
  "class": "discipline-untagged",
  "uuid": "<UUID>",
  "pkim_id": "...",
  "missing_layer": "structural" | "topical",
  "current_tags": [...]
}
```

**Auto-fix (limited):** for CLs inheriting from a parent KN, the topical set can be copied from the parent's tags. If the CL's `mdparentkn_id` resolves and the parent has topical tags, apply them via `set_record_tags` (merging with the CL's existing structural tags).

For RLs with both endpoints resolved and tagged, the topical set is the union of endpoint tag sets. Same auto-fix.

For EVs and standalone KNs, do not auto-tag — topical tag inference is content-based and needs an LLM read. Route to `needs-human`.

## Missing required metadata

Per `../../pkim-primer/references/metadata-schema.md`, each class has required fields:

| Class | Required |
|---|---|
| EV | `pkim_id`, `docrole`, `evidencestatus`, `capturetype`, `review_state` |
| KN | `pkim_id`, `docrole`, `notetype`, `review_state`, `knowledgestatus` |
| RL | `pkim_id`, `docrole`, `relation_type`, `source_item`, `target_item`, `relationstatus` |
| CL | `pkim_id`, `docrole`, `claimtype`, `claimconfidence`, `parentkn_id` |

Walk and check per-class. Missing field → finding.

**Auto-fix:** none. Missing metadata usually means the record was authored outside the workflow; the human needs to backfill.

## RL without prose rationale

Every RL body has a mandatory `## Why this relation exists` section. If it's absent or empty, the RL is invalid — it's an edge with no reason.

Walk RLs, `get_record_text`, check for a `## Why this relation exists` heading with non-empty content beneath.

Finding shape:

```json
{
  "class": "discipline-rl-no-rationale",
  "uuid": "<RL-UUID>",
  "pkim_id": "RL-..."
}
```

**Auto-fix:** none. The rationale is the point of the RL; only a human can supply it.

## Published KN without `## Claims`

KNs with `mdknowledgestatus: published` should carry a `## Claims` block. If missing, the KN is published without structured claims — the synthesis discipline slipped.

Walk KNs where `mdknowledgestatus: published`, `get_record_text`, check for `## Claims` heading.

**Auto-fix:** none.

## Aliases don't include PKIM_ID

Every record's DT `aliases` field should include its PKIM_ID (semicolon-joined with the display name). Missing PKIM_ID alias makes `lookup_records name:` unreliable.

Walk all PKIM records, check aliases via `get_record_properties`.

**Auto-fix routing:** yes — if PKIM_ID is set in custom metadata but missing from aliases, append it. `mcp__devonthink__update_record uuid: <UUID> aliases: "<Display>; <PKIM_ID>"`. Low risk.

## Cross-database WikiLinks

WikiLinks referencing EV records from a KN body — this violates the cross-DB rule. Detection is covered by [dangling-wikilinks.md](dangling-wikilinks.md); the discipline audit just tallies the count as a separate finding class.

## Severity + surface

All discipline violations are `low` severity. Aggregate the counts by class; don't list every occurrence in the audit summary (that would flood the report). List the counts and the top 5 examples per class.
