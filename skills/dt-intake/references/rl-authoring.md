# RL authoring during intake

Relation notes (RLs) are first-class edge records. They exist because WikiLinks in prose are not queryable and are invisible to corpus-level audits. Every semantically load-bearing connection between two records becomes an RL.

## When to author an RL

Yes, author:

- A KN cites an EV and the citation is not just "referenced" — it `supports`, `contradicts`, `extends`, `summarizes`, `exemplifies`, `precedes`, or `supersedes` the target.
- Two KNs share substantive topical overlap and the connection is worth surfacing in graph audits.
- A CL contradicts another CL or KN.
- A KN or EV supersedes an earlier one (deprecates / replaces).

Not routinely:

- Every `[[…]]` WikiLink in a KN body. WikiLinks are for readable prose; RLs are for the graph.
- A KN listing several EVs in `## Evidence links` — that's evidence, not a semantic edge unless one EV specifically `contradicts` another or you'd want to surface the relation later.
- A KN mentioning a related concept in passing.

## Which `Relation_Type`

Closed vocabulary (see `../../pkim-orient-and-setup/references/record-classes.md` §RL):

| Value | Use for |
|---|---|
| `supports` | Target evidence corroborates the source claim |
| `contradicts` | Target evidence contradicts the source claim (or two KNs reach opposite conclusions from shared evidence) |
| `extends` | Target elaborates or generalises the source |
| `summarizes` | Source is a summary of the target |
| `references` | Weakest edge — target is cited but not load-bearing (use sparingly) |
| `exemplifies` | Target is a concrete case of the source's general claim |
| `precedes` | Temporal / causal precedence |
| `supersedes` | Source replaces target; target should now be treated as retired |

## Steps

1. **Check for existing RL** with the same `Source_Item`, `Target_Item`, `Relation_Type` triplet.
   ```
   mcp__devonthink__search_records
     database_uuid: <PKIM-Knowledge UUID>
     query: "docrole:relation mdsource_item:<source-item-link> mdrelation_type:<type>"
   ```
   If a duplicate triplet exists, do not create a new RL. Add a note to `actions_taken`: `rl-already-exists:<PKIM_ID>`.

2. **Mint the RL PKIM_ID.**
   `RL-YYYYMMDD-NNNN`.

3. **Compose the body.**
   ```markdown
   # Relation — {{source-title}} {{type}} {{target-title}}

   ## Why this relation exists

   One or more sentences of prose rationale. Mandatory — an RL without rationale is invalid.

   ## Interpretation

   Optional context, caveats, or conditions on this relation.
   ```

   Frontmatter carries the identity + endpoint metadata:
   ```
   Title: Relation — <source-name> <type> <target-name>
   PKIM_ID: RL-YYYYMMDD-NNNN
   DocRole: relation
   Relation_Type: supports
   Source_Item: x-devonthink-item://<source-uuid>
   Target_Item: x-devonthink-item://<target-uuid>
   Review_State: inbox
   RelationStatus: proposed
   ```

4. **Create the record.**
   ```
   mcp__devonthink__create_record
     database_uuid: <PKIM-Knowledge UUID>
     type: markdown
     name: "Relation — <source-name> <type> <target-name>"
     content: <body>
     destination: <group UUID for /Notes/Relations>
   ```

5. **Stamp metadata** (the frontmatter is human-readable; the custom-metadata fields are what smart groups and audits query):

   ```json
   {
     "pkim_id": "RL-20260715-0001",
     "docrole": "relation",
     "relation_type": "supports",
     "source_item": "x-devonthink-item://<source-uuid>",
     "target_item": "x-devonthink-item://<target-uuid>",
     "review_state": "inbox",
     "relationstatus": "proposed",
     "relationconfidence": "medium"
   }
   ```

6. **Tag.**

   Structural:
   - `pkim/relation`
   - `relation/type/<supports|contradicts|...>`
   - `relation/status/<proposed|reviewed>`
   - `relation/confidence/<low|medium|high>`

   Topical: inherit the union of the source and target records' topical tags. If source and target share no topical tags, the relation is probably spurious — surface as `needs-human`.

7. **Update aliases** to include the PKIM_ID.

8. **Return** the RL's UUID + PKIM_ID in the subagent's summary: `actions_taken: [..., "authored-rl:RL-..."]`.

## Cross-database endpoints

If the RL's source is a KN in `PKIM-Knowledge` and the target is an EV in `PKIM-Evidence-*` (typical), both endpoints use `x-devonthink-item://<uuid>` — cross-database references. The `Source_Item` and `Target_Item` metadata fields already store item links; no WikiLinks in the body.

## RL discipline (from doc 18 / doc 21)

- An RL body without prose rationale is invalid. `## Why this relation exists` is mandatory.
- The `Relation_Type` is a closed vocabulary. `strongly-supports` or `mostly-agrees` are not valid values. Use `supports` with `relationconfidence: high` instead.
- If you author two RLs with the same source + target + type between the same pair, one is a duplicate — dedupe first.
- If a KN + N CLs are authored without any RLs, the walk is incomplete. Cross-citations need to be RLs.
