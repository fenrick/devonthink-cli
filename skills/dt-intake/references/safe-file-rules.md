# Filing rules

Where records go after enrichment. Move via `mcp__devonthink__move_record`. Never `replicate_record` unless the operator has explicitly asked — replicating creates a second instance which is almost never what you want.

## Filing destinations by class

### EV — evidence

| Situation | Destination |
|---|---|
| Imported record (file lives inside `.dtBase2` package; `indexed: false`) | `/Sources/Imported` |
| Indexed record (file lives on disk; `indexed: true`) | `/Sources/Indexed` |
| Web capture | `/Captures/Web` |
| Bookmark | `/Captures/Bookmarks` |
| Scanned page (typically PDF from a scanner) | `/Captures/Scans` |
| Actively being reviewed / mid-processing | `/Working` |
| Ready for human sign-off | `/Review` |
| Retired / archived | `/Archive` |

Check `indexed` in `get_record_properties` before deciding between Imported and Indexed.

### KN — knowledge note

| NoteType | Destination |
|---|---|
| `literature` | `/Notes/Literature` |
| `synthesis` | `/Notes/Synthesis` |
| `topic` | `/Notes/Topics` |
| `project` | `/Notes/Projects` |

### RL — relation note

Always `/Notes/Relations`.

### CL — claim

Always `/Notes/Claims`. Sub-grouping by parent KN name (`/Notes/Claims/<parent-KN-name>`) is optional; the mirror doesn't depend on location.

## The allowlist

The above are the **only** valid filing destinations. If the intake process wants to move a record somewhere that isn't on this list — for example a subgroup the human created ad-hoc — that's `needs-human`.

## Move mechanics

```
mcp__devonthink__move_record
  uuid: <record-UUID>
  destination: <group-UUID>
```

Get the destination group's UUID by:

1. `mcp__devonthink__lookup_records location: "<database>/<path>"` — exact match, one call.
2. Or from `mcp__devonthink__get_databases` for special groups (root, inbox, tags, trash).
3. Or, if the group doesn't exist yet, create it via `mcp__devonthink__create_group_path` (idempotent).

`move_record` moves the record; it doesn't leave a replicant behind.

## After moving

Update `review_state` to `filed` via `set_record_custom_metadata mode="merge"`:

```json
{ "review_state": "filed" }
```

If the record still needs human review before it's genuinely done (unclear class, ambiguous KN authoring decision, etc.), set `review_state` to `needs-human` instead — the `Needs Human Review` smart group will surface it.

## Anti-patterns

- Filing to `/Inbox/Sources/...` (nested Sources under Inbox). Sources live at the database root. Fix the tree in `dt-bootstrap`.
- Filing an indexed EV to `/Sources/Imported`. The classification of Imported vs Indexed is not about intent — it's about where the file physically lives.
- Filing into `PKIM-Knowledge`'s `/Sources/*` — that path doesn't exist there. Evidence lives in evidence databases.
- Replicating instead of moving. `replicate_record` is not for filing.
