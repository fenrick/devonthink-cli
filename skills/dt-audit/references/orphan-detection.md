# Orphan records

Records that structurally exist but aren't connected to the graph the way their class implies.

## Orphan CLs

A CL should always have a resolvable parent KN. The `mdparentkn_id` custom metadata field points to the parent; the body's `## Parent` section is the authoritative edge.

Walk:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:claim"
```

For each CL:

1. Read `mdparentkn_id` from custom metadata. If missing → orphan (structural).
2. Look up the parent: `mcp__devonthink__search_records query: "mdpkim_id:<parentkn_id>"`. If not found → orphan (broken pointer).
3. Read the CL body and check the `## Parent` section resolves to the same KN.

Finding shape:

```json
{
  "class": "orphan-cl",
  "uuid": "<CL-UUID>",
  "pkim_id": "CL-...",
  "reason": "missing-parent-metadata" | "parent-not-found" | "body-parent-does-not-match-metadata"
}
```

## Orphan KNs

A `literature` or `synthesis` KN should cite at least one EV (via `## Evidence links` item links or via an incoming RL with the KN as target and an EV as source). `topic` and `project` KNs may have zero EVs — they define concepts or state, not synthesised material.

Walk:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:knowledge mdnotetype:literature OR mdnotetype:synthesis"
```

For each KN:

1. Read the body via `get_record_text`. Find `## Evidence links` section. Count item links.
2. Look up incoming RLs: `search_records query: "mddocrole:relation mdtarget_item:x-devonthink-item://<KN-UUID>"`. Count RLs whose source resolves to an EV.
3. If total = 0 and `notetype` ∈ {literature, synthesis} → orphan.

Finding:

```json
{
  "class": "orphan-kn",
  "uuid": "<KN-UUID>",
  "pkim_id": "KN-...",
  "notetype": "literature",
  "reason": "no-cited-evidence-and-no-incoming-rl"
}
```

## Malformed RLs

An RL's endpoints should be records of *different* classes in the general case. Common malformed shapes:

- Both endpoints are EVs — evidence-to-evidence relations are unusual (usually `supersedes` or `precedes`; anything else is probably wrong).
- Both endpoints are RLs — meta-relations aren't part of the model.
- Endpoints in the same class where `Relation_Type` is `supports` / `extends` / `contradicts` between KNs — legal, but worth surfacing so the operator can confirm it's intentional.

Walk RLs and check endpoint classes:

```json
{
  "class": "malformed-rl",
  "uuid": "<RL-UUID>",
  "pkim_id": "RL-...",
  "source_class": "EV",
  "target_class": "EV",
  "relation_type": "supports",
  "reason": "evidence-to-evidence-supports-is-unusual"
}
```

## Auto-fix

None across the board. Orphan detection is diagnostic; the operator decides whether to trash, re-link, or leave.

## Triage guidance

- **Orphan CL with missing parent** → either the CL was authored without a parent (mint the parent KN, add the `## Parent` link), or the CL is misfiled (should be a standalone KN).
- **Orphan literature KN** → probably a synthesis-in-waiting; author the evidence citations, or reclassify as `topic`/`project`.
- **Malformed RLs** → almost always an authoring error. Usually the fix is to correct one endpoint or delete the RL.
