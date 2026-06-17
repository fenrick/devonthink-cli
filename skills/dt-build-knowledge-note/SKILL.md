---
name: dt-build-knowledge-note
description: "Turn one resolved candidate concept into one canonical PKIM knowledge-note mutation path: create, update, merge, or supersede. Make sure to use this skill whenever a candidate concept has already passed canonical resolution and now needs a bounded note write."
compatibility: Works in any runtime that can read the source material and create or update a note through an approved write path. The local `scripts/pkim create-knowledge-note` and `scripts/pkim update-knowledge-note` commands are the preferred deterministic tool paths when available.
---

# dt-build-knowledge-note

This skill now works on **one resolved candidate concept**, not on a whole source document.

## What this skill is for

Use it when a candidate has already been triaged and resolved:

- `create` — mint one new note
- `update` — enrich one existing note
- `merge` — consolidate into one survivor note
- `supersede` — create successor note, then retire predecessor

The unit of work is one candidate concept with one concrete mutation outcome.

## Why this matters

The failure mode here is quiet graph damage through over-broad note writing. If one candidate write starts dragging in neighbouring candidates, the session loses traceability and later relation work stops making sense.

## Preconditions

Do not run this skill without:

- the source `ProfilePacket`
- one specific `candidate_notes[]` entry
- a candidate-scoped resolution packet from `dt-resolve-canonical-note`
- session context showing any upstream candidate dependencies already resolved
- **when the target `KnowledgeStatus` is `reviewed` or `published`:** a claim ledger artefact at `runs/<run-id>/claim-ledger.md` produced by [`dt-build-claim-ledger`](../dt-build-claim-ledger/SKILL.md). The `## Claims` section of the new note is authored from the accepted ledger entries; without a ledger the note can only land at `KnowledgeStatus=seed` or `active`.

See [18 Evidence Discipline And Claims](../../docs/design/18-evidence-discipline-and-claims.md) for the claim schema, confidence ladder, and contradiction-handling rules every claim block must follow.

## Workflow

### Creating a new note (offline-first path)

1. Read the candidate packet, not just the source record.
2. Confirm `candidate_class=canonical-note-candidate`.
3. Confirm all `dependency_type=depends-on-candidate` prerequisites are already resolved.
4. Read the resolution decision for this candidate.
5. Mint a PKIM_ID before touching DEVONthink:
   ```bash
   scripts/pkim mint-id --type knowledge
   ```
6. Build the note draft offline:
   ```bash
   scripts/pkim build-knowledge-note \
     --pkim-id <minted-id> \
     --title "<title>" \
     --note-type <type> \
     --source "<source-ref>" \
     --summary "<summary>" \
     --key-points "$(printf 'First point\nSecond point')" \
     --related-notes "$(printf '[[RL-YYYYMMDD-NNNN]] supports [[KN-YYYYMMDD-NNNN]]')" \
     --format json
   ```
   The draft is written to `workspace/drafts/`. All cross-references use `[[PKIM_ID]]` alias links — do not manually add `x-devonthink-item://` links to the body. The `## Related Notes` section is populated now, not backfilled later.
7. Execute exactly one mutation path:
   - `create` → build draft offline, then push via `dt-push-batch`
   - `update` → `scripts/pkim update-knowledge-note`
   - `merge` → update the survivor note and retire the fragments
   - `supersede` → create successor offline, push batch, then archive predecessor per policy
8. Record the candidate-to-note mapping back into the orchestration session.
9. After a successful push, aliases are set automatically by `push-batch`. For notes created via `create-knowledge-note` (direct write), apply tags and alias manually:
   - Tags must include at minimum: `knowledge-note`, the primary domain tag (e.g. `business-design`), at least one topic tag, and a location-type tag (`literature` for `/Notes/Literature/` notes, `synthesis` for `/Notes/Synthesis/` notes).
   - Alias must be set to the PKIM_ID (e.g. `KN-20260429-0001`).
   - Use JXA: `rec.tags = [...]` and `rec.aliases = ["<title>", "<pkim_id>"]`. DEVONthink navigation, smart groups, and tag-based retrieval all depend on tags being set. A note without tags is invisible to DT's classification layer.
10. Do not materialize edges here; that belongs after note resolution.

## How to know you are doing it right

- one candidate concept produces one bounded note outcome
- the resulting note can be mapped back to `candidate_id` and `candidate_fingerprint`
- no unrelated candidate is mutated in the same call
- merge/supersede paths leave explicit retirement state behind

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## MANDATORY: relation notes (RL) are part of every end-to-end walk

A Workflow-3 walk that produces a KN + N CLs but zero RLs is **incomplete**. Every cross-citation in a CL's reasoning prose, every KN-to-KN topical overlap, every claim that corroborates / contradicts / extends / exemplifies / supersedes an existing record must be expressed as a first-class RL record — not just hinted at in prose.

Why this matters:
- The mirror graph's edges, contradiction detection, and supersession propagation all run over RL records, not over prose hints.
- WikiLinks inside CL reasoning are informal; RLs are auditable, taggable, and survive refactor-on-touch.
- Without RLs, the corpus is a collection of independent literature notes; with RLs, it becomes the connected argument the project is for.

**How to apply** at every walk:
- For each CL whose reasoning cites another KN or CL, mint an RL with the appropriate `Relation_Type` (supports / contradicts / extends / exemplifies / summarizes / references / precedes / supersedes — closed vocabulary, see doc 08).
- For each KN pair sharing substantive topical overlap, mint an RL capturing the connection.
- File RLs at `/Notes/Relations/` (indexed alongside `/Notes/Claims/` and `/Notes/Literature/`).
- Tag RLs per the canonical axes: `pkim/relation`, `relation/type/<…>`, `relation/status/<proposed|reviewed>`, `relation/confidence/<low|medium|high>`, plus inherited topical tags from both endpoints.

If no cross-citations exist for a fresh CL set, that's a profiling gap — pause and surface to the operator rather than silently producing an isolated KN.

## What not to do

- Do not start from a raw source document alone.
- Do not batch-create notes for the whole concept set.
- Do not materialize relation notes from here.
- Do not ignore candidate dependency state.

## Output

Produce one candidate-scoped mutation result that makes the note outcome explicit:

- `candidate_id`
- `candidate_fingerprint`
- `mutation_mode` (`create`, `update`, `merge`, `supersede`)
- `note_ref`
- `session_mapping_update`
- `follow_on_work` for later edge materialisation or neighbourhood review

## Preferred tool path

**Offline build (preferred for new notes):**

```bash
# Step 1: mint ID
scripts/pkim mint-id --type knowledge

# Step 2: build draft
scripts/pkim build-knowledge-note \
  --pkim-id KN-YYYYMMDD-NNNN \
  --title "<title>" \
  --note-type <type> \
  --source "<ref>" \
  --summary "<summary>" \
  --key-points "$(printf 'First point\nSecond point\nThird point')" \
  --related-notes "$(printf '[[RL-YYYYMMDD-NNNN]] supports [[KN-YYYYMMDD-NNNN]]')" \
  --format json

# Step 3: push via dt-push-batch (see that skill)
```

`--key-points` and `--related-notes` each take a **single newline-separated string**. Multiple invocations or space-separated lists will fail with exit code 2.

**Direct write (single note, no batch):**

```bash
scripts/pkim create-knowledge-note \
  --source "<ref>" \
  --note-type <type> \
  --title "<title>" \
  --summary "<summary>" \
  --key-points "$(printf 'First point\nSecond point\nThird point')" \
  --live \
  --format json
```

Then apply tags and alias via JXA (not done automatically for direct writes).

**Update existing:**

```bash
scripts/pkim update-knowledge-note --note "<existing-ref>" --summary "<summary>" --key-points "<points>" --add-evidence-link "Name|x-devonthink-item://..." --format json
```

This skill must write the candidate-to-note result back into the session artifact after a successful mutation.
