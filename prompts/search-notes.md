# Search Notes — Command Surface

Read-only search across one DEVONthink database. Returns matching records as a structured list. Used by reconciliation and audit skills to locate notes by field value, metadata state, or text query.

The project-level skill contracts that use this command are:
- `skills/dt-resolve-canonical-note/SKILL.md` — alias and title search for duplicate detection
- `skills/dt-reconcile-relation-edge/SKILL.md` — Source_Item and Target_Item lookup
- `skills/dt-inspect-graph-neighbourhood/SKILL.md` — neighbourhood mapping in both directions
- `skills/dt-identify-knowledge-gaps/SKILL.md` — evidence with no knowledge link
- `skills/dt-audit-graph-corpus/SKILL.md` — corpus-wide failure pattern queries

## Command

```bash
scripts/pkim search-notes \
  --database "<db-name>" \
  [--field "<field-name>" --value "<value>"] \
  [--query "<text>"] \
  [--doc-role <role>] \
  [--review-state <state>] \
  [--format json]
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `--database` | yes | Target database name (e.g. `PKIM-Knowledge`, `PKIM-Evidence-Work`) |
| `--field` | conditional | Metadata field name to match exactly. Requires `--value`. |
| `--value` | conditional | Value to match for `--field`. Empty string matches unset or blank fields. |
| `--query` | no | Free-text search against record name and content. Supports DEVONthink native search syntax. |
| `--doc-role` | no | Filter results to a specific `DocRole` value: `evidence`, `knowledge`, `relation`, `annotation`, `project`, `topic`, `operation` |
| `--review-state` | no | Filter results to a specific `Review_State` value |
| `--format` | no | `json` (default) or `text` |

`--field` + `--value` and `--query` may be combined. Filters are applied after the query. If neither `--field` nor `--query` is provided, the command returns all records in the database that match the active filters — use caution on large databases.

## Pre-conditions

- DEVONthink must be running and the target database must be open.
- No write permissions needed or used.

## Expected output

```json
{
  "run_id": "RUN-2026-04-17T16-05-00Z",
  "database": "PKIM-Knowledge",
  "query": { "field": "Source_Item", "value": "x-devonthink-item://03CF4017-..." },
  "total": 2,
  "records": [
    {
      "pkim_id": "RL-20260417-0004",
      "dt_uuid": "AB12CD34-...",
      "dt_item_link": "x-devonthink-item://AB12CD34-...",
      "name": "Relation - problem framing supports local-first PKIM",
      "doc_role": "relation",
      "review_state": "proposed",
      "location": "/Notes/Relations/",
      "existing_metadata": {
        "Source_Item": "x-devonthink-item://03CF4017-...",
        "Target_Item": "x-devonthink-item://9A2B3C4D-...",
        "Relation_Type": "supports",
        "RelationStatus": "proposed"
      }
    }
  ]
}
```

## Common query patterns

Find all relation notes where a record is the source:

```bash
scripts/pkim search-notes \
  --database "PKIM-Knowledge" \
  --field "Source_Item" \
  --value "x-devonthink-item://03CF4017-..." \
  --format json
```

Find all relation notes where a record is the target:

```bash
scripts/pkim search-notes \
  --database "PKIM-Knowledge" \
  --field "Target_Item" \
  --value "x-devonthink-item://03CF4017-..." \
  --format json
```

Find knowledge notes by title similarity:

```bash
scripts/pkim search-notes \
  --database "PKIM-Knowledge" \
  --query "Tickler File date commitment" \
  --doc-role knowledge \
  --format json
```

Find approved evidence records with no knowledge link:

```bash
scripts/pkim search-notes \
  --database "PKIM-Evidence-Work" \
  --doc-role evidence \
  --review-state approved \
  --field "Knowledge_Link_State" \
  --value "" \
  --format json
```

Find all retired relation notes (for audit):

```bash
scripts/pkim search-notes \
  --database "PKIM-Knowledge" \
  --doc-role relation \
  --field "RelationStatus" \
  --value "retired" \
  --format json
```

## Hard rules

- No write operations. This command is permanently read-only.
- Do not use without `--database` — cross-database search is not supported.
- Empty `--value ""` matches records where the field is absent or blank; it does not match records where the field is explicitly set to `"none"` or similar sentinel values.
- Large result sets from filter-only queries (no `--query`, no `--field`) should be paginated. Check `total` before processing all records.

## Failure modes

| Error | Cause | Resolution |
|---|---|---|
| `Database not found` | Database name wrong or not open | Confirm name; open database in DEVONthink |
| `Field not recognised` | Field name not in canonical metadata schema | Check field name against docs/design/08 |
| `result: error` | JXA query failure | Read `message` field; confirm DEVONthink is running |
