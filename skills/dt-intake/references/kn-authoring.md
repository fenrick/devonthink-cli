# KN authoring during intake

Most inbox records do **not** need a KN. Only author one when the evidence genuinely calls for it.

## When to author a KN

Yes, author:

- The record is a substantive piece of primary or secondary source material with claims worth extracting.
- The record is closely related to an existing KN or existing topic, and reading it adds arguments or claims the corpus doesn't yet capture.
- The operator has explicitly asked for a KN off this record.

Not routinely:

- A short blog post that just repeats what other KNs already say.
- A raw PDF that's evidence for a future synthesis but doesn't yet have a defined synthesis around it.
- A reference the operator captured for later — captures without an angle don't need a KN yet.

## Which KN type

See `../../pkim-orient-and-setup/references/record-classes.md` §KN for the closed set. Rule of thumb:

- One EV, close reading → `literature`
- Many EVs → `synthesis`
- Defines what a concept means → `topic`
- Goal / context / status → `project`

## Steps

1. **Check for a canonical KN first.**
   `lookup_records name: "..."` and `search_records query: "kind:markdown docrole:knowledge mdprimarytopic:<topic>"` in `PKIM-Knowledge`. If a matching KN exists, read [merge-vs-create.md](merge-vs-create.md); usually the answer is "update the existing KN, don't create a new one".

2. **Mint the KN's PKIM_ID.**
   `KN-YYYYMMDD-NNNN` — see `../../pkim-orient-and-setup/references/record-classes.md` §PKIM_ID minting.

3. **Compose the body.**
   Frontmatter first (Title / PKIM_ID / DocRole / NoteType / Review_State / Aliases / PrimaryTopic), then:

   ```markdown
   # {{Title}}

   ## Summary

   One paragraph. What this KN says.

   ## Claims

   <!-- Structured per doc 18. Add claims here as you extract them. -->

   ## Evidence links

   - [<source-record-name>](x-devonthink-item://<source-EV-uuid>)

   ## Related notes

   - [[<related-KN-name>]]
   ```

   Item link for the EV (cross-database). WikiLinks for related KNs (within `PKIM-Knowledge`).

4. **Create the record.**
   Indexed create requires the write-then-index pattern. For the initial pass in an intake session, an imported create via `create_record` is acceptable — the file will still be visible in the mirror because `PKIM-Knowledge` is indexed against its on-disk root and DT keeps the imported file synchronised.

   ```
   mcp__devonthink__create_record
     database_uuid: <PKIM-Knowledge UUID>
     type: markdown
     name: "<Title>"
     content: <body>
     destination: <group UUID for /Notes/Literature or /Notes/Synthesis etc.>
   ```

5. **Stamp metadata.**

   ```json
   {
     "pkim_id": "KN-20260715-0001",
     "docrole": "knowledge",
     "notetype": "literature",  // or synthesis/topic/project
     "review_state": "inbox",
     "knowledgestatus": "active",
     "primarytopic": "<topic>"
   }
   ```

6. **Tag.** Structural + topical per `../../pkim-orient-and-setup/references/tag-axes.md`. Topical tags are inherited from the EV's tag set.

7. **Update aliases** to include the PKIM_ID.

8. **If the KN cites another KN or CL** in `PKIM-Knowledge`, author an RL — read [rl-authoring.md](rl-authoring.md).

9. **Return** the KN's UUID + PKIM_ID in the subagent's summary under `actions_taken: ["authored-kn:KN-..."]`.

## Anti-patterns

- **Authoring a KN with an empty `## Claims` block.** Draft even one placeholder claim; otherwise the KN is a stub that will drift.
- **Copying the EV's content verbatim.** The KN is *synthesis*, not a duplicate.
- **Skipping the `## Evidence links` section.** Every claim needs traceable evidence; the section is where that traceability lives.
- **Filing the KN before setting metadata + tags.** Same rule as intake overall.
