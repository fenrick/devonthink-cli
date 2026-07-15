# Dangling WikiLinks

`[[Name|Display]]` references in KN/CL bodies that DT can't resolve. Cause: either the target moved and the name is stale, the target was retired, or the WikiLink is being used for a cross-database reference (which never resolves — see [../../pkim-primer/references/wikilink-and-item-link.md](../../pkim-primer/references/wikilink-and-item-link.md)).

## Detection

DT MCP does the resolution for us:

```
mcp__devonthink__get_record_unlinked_wiki_links
  uuid: <KN or CL UUID>
```

Returns the list of `[[...]]` references in the body that don't resolve. Loop this over every KN and CL in `PKIM-Knowledge`.

Batch-friendly: pass `uuids: [...]` for parallelism.

## Finding shape

```json
{
  "class": "dangling-wikilink",
  "uuid": "<record-UUID>",
  "pkim_id": "KN-20260503-0002",
  "wikilink_text": "[[EV-20260101-0007|MuleSoft trends report]]",
  "target_name_guess": "EV-20260101-0007",
  "likely_cause": "cross-database" | "renamed" | "retired" | "typo"
}
```

## Common causes

### Cross-database usage (most common)

The author used `[[EV-...|Name]]` for an evidence citation. WikiLinks don't resolve across databases; the correct form is `[Name](x-devonthink-item://<UUID>)`.

**Auto-fix routing:** if the `EV-YYYYMMDD-NNNN` in the WikiLink resolves via `search_records query: "mdpkim_id:<the-ev-id>"`, we can build the correct item link and patch the body. Route to auto-fix only when:
- The WikiLink target is unambiguously an EV (starts with `EV-`).
- Search returns exactly one record with that PKIM_ID.
- The operator has authorised discipline auto-fix.

Otherwise → `needs-human`.

### Renamed target

The target KN/CL still exists but was renamed. DT can't resolve the WikiLink because it looks up by name. Fix: update the WikiLink text to the current name (or use the current PKIM_ID form).

**Auto-fix routing:** none — we'd need to guess the new name.

### Retired target

The target was retired / trashed. Either the WikiLink should be removed, or replaced with a reference to the successor.

**Auto-fix routing:** none.

### Typo

The author wrote `[[Composable Enteprise]]` (missing `r`). DT can't resolve; there's no fuzzy match.

**Auto-fix routing:** none.

## Patch mechanics

For the cross-database auto-fix class:

1. Read the body:
   ```
   mcp__devonthink__get_record_text uuid: <UUID>
   ```
2. Locate the exact `[[EV-...|Name]]` occurrence.
3. Look up the EV: `mcp__devonthink__search_records query: "mdpkim_id:EV-YYYYMMDD-NNNN"`. Get the UUID.
4. Build a unified-diff patch that replaces the WikiLink with `[Name](x-devonthink-item://<UUID>)`.
5. Apply: `mcp__devonthink__update_record_content uuid: <UUID> mode: "patch" patch: <patch>`.
6. Log the auto-fix in the audit summary.

The patch must be built from the *exact* output of `get_record_text` — DT's patch mode does strict line-number matching, no fuzzy tolerance.

## Anti-patterns

- **Auto-fixing a WikiLink whose target is a KN.** Within-database WikiLinks are supposed to work; if one doesn't, the *target* moved or renamed — a mechanical fix would guess wrong.
- **Trying to interpret the human-readable "Display" text.** DT resolves by the "Name" part, not the "Display" part. The Display text is prose.
- **Fixing without reading.** Always `get_record_text` first; never build a patch from remembered content.
