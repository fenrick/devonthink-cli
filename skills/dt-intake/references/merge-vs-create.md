# Canonical-note resolution — merge vs create

You're about to author a KN. Before creating a new one, check whether a canonical KN for this material already exists.

## Detection

Three shapes of check, cheapest first:

### 1. By URL / path (fastest)

If the source EV has a `url` or an `origin_uri`, look up KNs that already reference it:

```
mcp__devonthink__lookup_records url: "<the-url>" database_uuid: <PKIM-Knowledge>
```

If a KN comes back, you have a canonical match. Skip to §Resolution.

### 2. By topic

The source EV has (or should have) a `primarytopic` custom metadata field. Search KNs on the same topic:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:knowledge mdprimarytopic:<topic>"
```

If multiple KNs come back, look at their names + summaries via `get_record_text` and decide which (if any) covers this material.

### 3. By similarity

If the topic doesn't uniquely identify a canonical KN, DT's built-in similarity engine can help:

```
mcp__devonthink__find_similar_records
  uuid: <source-EV-UUID>
  database_uuid: <PKIM-Knowledge>
  limit: 5
```

DT proposes the top-N most similar KNs. Read the top hit's summary via `get_record_text`; decide.

## Resolution

### A — canonical KN already exists, this EV adds to it

**Don't create a new KN.** Instead:

1. Add the new EV to the canonical KN's `## Evidence links` via `update_record_content mode="patch"`.
2. Extract any new claims into the `## Claims` block (append; don't disturb existing claims).
3. If the KN was `KnowledgeStatus: published`, set it to `active` (needs re-review after content change).
4. Author an RL from the KN to the new EV (`supports` or `extends` typically).

Note in your subagent summary: `updated-existing-kn:<KN-PKIM_ID>` — not `authored-kn`.

### B — canonical KN exists but this EV contradicts / supersedes it

Do not silently overwrite. Two paths:

- **Contradicts**: author a new KN (or a CL) that captures the counter-argument. Author an RL from the new record to the canonical with `Relation_Type: contradicts`. Surface as `needs-human` so the operator triages the contradiction.
- **Supersedes**: this EV is a newer version of what the canonical KN was based on. Author an RL with `Relation_Type: supersedes`. Set the old KN's `evidencestatus`/`knowledgestatus` accordingly if the operator has authorised it; otherwise surface as `needs-human`.

### C — no canonical KN found; this EV genuinely warrants a new one

Follow [kn-authoring.md](kn-authoring.md).

### D — canonical KN found but this EV is redundant

If the canonical KN already cites this EV and the EV adds nothing new, do nothing at the KN level. File the EV to `/Sources/*` and stop.

## Stop conditions

Surface as `needs-human` when:

- Two or more canonical KNs each partially cover this material (choice between merge targets is ambiguous).
- The canonical KN is `KnowledgeStatus: published` and merging would materially change its argument (published KNs deserve human review before mutation).
- `find_similar_records` returns high-similarity hits but the topical tags don't overlap (the KN and EV are about superficially-similar-but-actually-different things).
- The operator has said "don't touch existing KNs in this batch."

## What NOT to do

- **Do not create a "notes about X" KN when a canonical topic KN for X already exists.** That's how duplicates start.
- **Do not silently merge into a published KN.** Published state is a review gate.
- **Do not blindly trust `find_similar_records`.** DT's similarity is content-based; two records on unrelated topics can score high if they share vocabulary. Always confirm topical tag overlap.
