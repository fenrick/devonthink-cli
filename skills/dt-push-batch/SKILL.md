---
name: dt-push-batch
description: Validate and push a workspace batch of offline-built PKIM notes into DEVONthink in knowledge-first order, registering PKIM_ID aliases on each created record and writing dt_item_link back to the batch files. Use this skill whenever one or more notes have been built offline via build-knowledge-note or build-relation-note and need to be committed to DEVONthink as a coherent set.
compatibility: Works in any runtime that can execute the pkim CLI and resolve DEVONthink JXA calls. Requires PKIM_ALLOW_PRODUCTION_WRITES=true for live writes.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-push-batch

This skill closes the offline-first authoring loop. Notes are built in `workspace/drafts/` with `[[PKIM_ID]]` cross-references. This skill validates the batch, stages it, and pushes it to DEVONthink in the correct order — knowledge notes first so their aliases are registered before relation notes reference them.

## What this skill is for

Use it to push one coherent set of offline-built notes:

- knowledge notes built via `build-knowledge-note`
- relation notes built via `build-relation-note`
- mixed batches (the skill handles ordering)

The result is a set of live DT records with:

- PKIM_ID aliases registered (enabling `[[PKIM_ID]]` link resolution)
- `dt_uuid` and `dt_item_link` written into the batch file frontmatter
- `Source_Item` / `Target_Item` in relation note customMetaData resolved to `x-devonthink-item://` URLs

## Why this matters

Push ordering is what makes `[[PKIM_ID]]` links work without a write-back pass. If relation notes are pushed before their source/target knowledge notes have aliases registered, DT cannot resolve the WikiLinks. This skill enforces the ordering guarantee.

Aliases are what connect `[[PKIM_ID]]` links in note bodies to actual DT records. Without aliases, WikiLinks are dead text. This skill sets them at creation time, not as a separate pass.

## Workflow

1. Confirm all drafts for this batch are in `workspace/drafts/` (or a directory you specify).
2. Validate the batch — all `[[PKIM_ID]]` refs must resolve within the batch or to existing DT notes:
   ```bash
   pkim validate-batch --dir workspace/drafts/ --format json
   ```
3. Read the `broken` array in the result. If any refs are broken, stop and resolve them before pushing.
4. Stage the batch — creates `workspace/batches/BATCH-XXX/` with a manifest in knowledge-first order:
   ```bash
   pkim validate-batch --dir workspace/drafts/ --stage --format json
   ```
5. Note the `batch_dir` from the output.
6. Dry-run the push to confirm ordering and note count:
   ```bash
   pkim push-batch --batch <batch_dir> --format json
   ```
7. Review the `push_order` list — knowledge/evidence notes must appear before relation notes.
8. Confirm `PKIM_ALLOW_PRODUCTION_WRITES=true` is set.
9. Run the live push:
   ```bash
   PKIM_ALLOW_PRODUCTION_WRITES=true pkim push-batch --batch <batch_dir> --live --format json
   ```
10. Read `runs/<run-id>/mutation.json`. Verify:
    - `result` is `ok` (or `partial` with acceptable errors)
    - Each pushed note has a `dt_item_link`
    - `errors` array is empty
11. For any notes that need tags (not set automatically by push-batch), apply via JXA:
    ```javascript
    var rec = dt.getRecordWithUuid("<uuid>");
    rec.tags = ["knowledge-note", "business-design", "synthesis"];
    ```
    Tags are not set by push-batch — it handles aliases only. Apply tags per the domain conventions in `dt-build-knowledge-note` and `dt-build-relation-note`.
12. Run mirror sync if notes are `review_state=approved`:
    ```bash
    PKIM_ALLOW_PRODUCTION_WRITES=true pkim sync-mirror --scope changed --live --format json
    ```

## Link format reference

| Location | Format after push |
|---|---|
| Note body cross-references | `[[PKIM_ID]]` — DT resolves via alias |
| `## References` in relation notes | `[[PKIM_ID]]` — same |
| `## Related Notes` in knowledge notes | `[[PKIM_ID]]` — same |
| Frontmatter `dt_item_link` | `x-devonthink-item://UUID` — written by push-batch |
| `Source_Item` / `Target_Item` in customMetaData | `x-devonthink-item://UUID` — resolved during push |

## How to know you are doing it right

- `validate-batch` shows zero broken refs before you stage
- push-batch dry-run shows knowledge notes before relations in `push_order`
- after live push, every pushed note appears in DT with its alias visible
- `[[PKIM_ID]]` links in relation note bodies are clickable and resolve to the right records

## What not to do

- Do not push without validating first — a broken ref in a relation note will not resolve to a live DT link.
- Do not push relation notes before knowledge notes manually — always use `push-batch` which enforces ordering.
- Do not skip alias registration — without aliases, all `[[PKIM_ID]]` links are dead text.
- Do not assume tags are set by this skill. Tags must be applied separately per domain conventions.
- Do not push the same batch twice — check the mutation.json result and verify records don't already exist before retrying.

## Preferred tool path

```bash
# Validate
pkim validate-batch --dir workspace/drafts/ --format json

# Stage (creates manifest with ordering)
pkim validate-batch --dir workspace/drafts/ --stage --format json

# Dry-run
pkim push-batch --batch workspace/batches/<batch-id>/ --format json

# Live push
PKIM_ALLOW_PRODUCTION_WRITES=true pkim push-batch \
  --batch workspace/batches/<batch-id>/ \
  --live \
  --format json
```
