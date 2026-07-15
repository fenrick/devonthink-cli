# Broken RL endpoints

An RL's job is to be a first-class edge. If its `Source_Item` or `Target_Item` doesn't resolve, the edge is broken and the RL is misleading — it looks like graph structure but points at nothing.

## Detection

For each RL in `PKIM-Knowledge`:

1. Fetch custom metadata:
   ```
   mcp__devonthink__get_record_custom_metadata uuid: <RL-uuid>
   ```
2. Extract `source_item` and `target_item`. Both are item links: `x-devonthink-item://<UUID>`.
3. For each endpoint, extract the UUID (the part after `://`).
4. Resolve:
   ```
   mcp__devonthink__get_record_properties uuid: <endpoint-uuid>
   ```
5. Broken conditions:
   - `get_record_properties` errors with "record not found" → the endpoint is deleted or in `Trash`.
   - Response's `location` starts with `/Trash` → the endpoint is trashed (soft-deleted).
   - Response is missing (silent no-record) → broken.

## Finding shape

```json
{
  "class": "broken-endpoint",
  "uuid": "<RL-UUID>",
  "pkim_id": "RL-20260601-0003",
  "endpoint": "source" | "target",
  "broken_uuid": "<UUID that didn't resolve>",
  "reason": "not-found" | "trashed"
}
```

## Common causes

- Target record was retired via `trash_record` without the RL being updated.
- Target moved to a different database and the item-link UUID is stale (rare — DT UUIDs are stable across moves).
- The RL was authored with a placeholder UUID that never got filled.

## Triage guidance for the operator

- **Target trashed deliberately** → trash the RL too (`mcp__devonthink__trash_record`). The edge no longer exists.
- **Target retired but the relation matters** → point the RL at the successor (search for supersession chain in RLs; update `source_item`/`target_item`).
- **Broken due to authoring error** → update the endpoint via `mcp__devonthink__set_record_custom_metadata mode="merge"` with the correct UUID.

## Not in scope

The audit doesn't auto-fix broken endpoints. Even the "obvious" case (target trashed → trash the RL) requires human judgement — the operator may want to preserve the RL as historical record of a relation that once existed.
