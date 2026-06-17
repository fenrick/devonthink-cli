---
name: dt-build-relation-note
description: Create one explicit PKIM relation note that states why two resolved notes are connected, not just that they are. In staged concept-set sessions, use this only after candidate edges have been rebound to concrete note identities.
compatibility: Works in any runtime that can read both records and create a relation note through an approved write path. The local `scripts/pkim create-relation-note` command is the preferred deterministic tool path when available.
---

# dt-build-relation-note

This skill exists because relation notes are not pointers. They are arguments for why an edge exists. If the rationale is weak, the graph becomes decorative clutter.

Your job is to create one relation note that explains a real connection between concrete resolved notes.

## What this skill is for

Use it for explicit, typed links between two records:

- support
- contradiction
- extension
- summary/compression
- precedence
- supersession
- exemplification
- structural reference

The result should make the relationship understandable to a later reader.

If either linked record also needs to be relocated after the relation is captured, hand off that work to `skills/dt-safe-file/SKILL.md`. Relation-note creation does not own filing.

## Why this matters

A knowledge graph without explanatory edges becomes noise fast. The value of a relation note is not that it says two things are related. The value is that it explains how and why.

## Workflow

Follow this sequence.

1. Confirm both endpoints are already concrete note identities with registered PKIM_IDs.
2. Read enough of each record to understand what each one is saying or representing.
3. Decide whether there is a relationship worth preserving.
4. Choose the narrowest honest relation type from the closed list: `supports`, `contradicts`, `extends`, `summarizes`, `references`, `exemplifies`, `precedes`, `supersedes`. Do not invent types outside this list.
   - **Before writing**: verify that the chosen type exists in DEVONthink's `Relation_Type` Selection field vocabulary. If it is missing, the field will silently write an empty string and the graph audit will flag the note as `relation_missing_fields`. Fix the vocabulary first, then write the note.
5. Write the rationale before attempting any write:
   - what in the source connects to what in the target
   - what kind of relation it is
   - why the relation matters
6. Mint a PKIM_ID for the relation note:
   ```bash
   scripts/pkim mint-id --type relation
   ```
7. Build the relation note draft offline using PKIM_IDs for both endpoints:
   ```bash
   scripts/pkim build-relation-note \
     --pkim-id RL-YYYYMMDD-NNNN \
     --source-pkim-id KN-YYYYMMDD-NNNN \
     --target-pkim-id KN-YYYYMMDD-NNNN \
     --relation <type> \
     --rationale "<specific rationale>" \
     --interpretation "<reader-oriented interpretation>" \
     --format json
   ```
   The draft is written to `workspace/drafts/`. References section uses `[[PKIM_ID]]` links automatically — do not manually add `x-devonthink-item://` links to the body.
8. Review the draft: the `## Why This Relation Exists` section must contain the rationale and `## References` must show `[[source-pkim-id]]` and `[[target-pkim-id]]`.
9. Push via `dt-push-batch` (see that skill) or directly:
   ```bash
   scripts/pkim create-relation-note \
     --source "<source-ref>" --target "<target-ref>" \
     --relation <type> --rationale "<rationale>" --live --format json
   ```
10. After a successful push, aliases are set automatically by `push-batch`. For direct `create-relation-note` writes, apply tags and alias manually:
    - Tags must include at minimum: `relation-note`, the primary domain tag (e.g. `business-design`), and the relation type (e.g. `supports`, `precedes`).
    - Alias must be set to the PKIM_ID (e.g. `RL-20260429-0022`).
    - Use JXA: `rec.tags = [...]` and `rec.aliases = ["<title>", "<pkim_id>"]`. DEVONthink smart groups and tag-based views depend on these being set.
11. Record the materialised edge result back into the staged session artifact.
12. If the user wants one of the underlying records filed, switch to `dt-safe-file` after the relation note succeeds.

## How to think about relation quality

### Relation type

Choose the type that best describes the actual logic:

- `supports`
- `contradicts`
- `extends`
- `summarizes`
- `references`
- `exemplifies`
- `precedes`
- `supersedes`

If two types seem plausible, say why in the rationale instead of pretending certainty.

### Rationale

A good rationale:

- names the relevant claim or content
- explains the logical connection
- would still make sense to someone reading it later

A bad rationale:

- says only that both records are “about the same thing”
- restates the relation type without evidence
- avoids naming the actual substance

## Relation lifecycle

### Duplicate detection before creating

Before creating any relation note, check whether a note for the same source+target+type triplet already exists. Use `scripts/pkim search-notes --field Source_Item --value <source-link>` and filter the results for matching target and type. If a duplicate triplet exists:

- If the existing note's rationale is weaker, `strengthen` it via `dt-reconcile-relation-edge` rather than creating a second note.
- If the existing note's relation type is wrong, `supersede` it: create the corrected note, then retire the old one.
- Do not create a second note for the same triplet.

A relation note is defined by its triplet: source + target + type. Two notes with the same triplet and different rationales are duplicates, not parallel edges.

### Inverse and semantically equivalent relations

Inverses are not duplicates. A → B `supports` and B → A `supports` are different claims. Both can be valid and both can exist.

However, check whether the inverse already covers the explanatory need. If A → B `supports` is already a strong edge, ask whether B → A `supports` adds distinct value or just mirrors it. If it mirrors, do not create it.

Semantically equivalent types in the same direction are duplicates. A → B `references` and A → B `extends` cannot coexist as separate notes — choose the more precise type and create one note.

### When to create vs strengthen vs supersede

| Situation | Action |
|---|---|
| No existing edge for this triplet | Create via this skill |
| Same triplet exists; rationale could be better | Switch to `dt-reconcile-relation-edge` to strengthen the existing note |
| Same triplet exists; relation type is wrong | Switch to `dt-reconcile-relation-edge` to supersede: create corrected note and retire old |
| Same source+target; a different type is also valid | Create a second note only if both types carry distinct explanatory value |
| One endpoint is archived | Do not create; there is nothing live to connect |

### RelationStatus lifecycle

| Status | Meaning | Set by |
|---|---|---|
| `proposed` | Created by automation or agent; not yet human-reviewed | Default on creation |
| `reviewed` | Both endpoints read carefully; relation type and rationale confirmed | Use `--reviewed` flag or explicit advancement via `dt-reconcile-relation-edge` |
| `accepted` | Human confirmed the edge is load-bearing in the graph | Explicit human action |
| `retired` | Superseded or invalidated; kept for audit trail | `dt-apply-approved-metadata` with `RelationStatus=retired` |

Do not delete relation notes. Retired notes stay in the graph as evidence of what was believed and why it changed. This is the audit trail that makes reconciliation trustworthy.

## How to know you are doing it right

You are doing this skill correctly when:

- the relation type is defensible
- the rationale is specific
- the note explains something real

You are doing it badly when:

- the rationale could apply to dozens of unrelated records
- the type is chosen by vibe
- the note is just an edge label with no reasoning

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## What not to do

- Do not create relation notes directly from unresolved candidate IDs.
- Do not create relation notes for weak thematic similarity.
- Do not write generic rationales.
- Do not go live until the rationale is strong enough to defend.
- Do not move or replicate source or target records inside this skill. Use `dt-safe-file` for that.

## Output

Produce a relation-note creation result with:

- source reference
- target reference
- relation type
- rationale
- created relation note reference if a live write occurred

Canonical shape for a dry-run result:

```json
{
  "run_id": "RUN-2026-04-17T15-22-00Z",
  "mode": "dry-run",
  "source": "x-devonthink-item://SOURCE-UUID",
  "target": "x-devonthink-item://TARGET-UUID",
  "relation_type": "supports",
  "rationale": "Allen's constraint that a Tickler File item must have a specific date...",
  "relation_status": "proposed",
  "draft_body": "...",
  "result": "proposal"
}
```

Canonical shape for a live result:

```json
{
  "run_id": "RUN-2026-04-17T15-22-00Z",
  "mode": "live",
  "result": "ok",
  "pkim_id": "RL-20260417-0004",
  "dt_uuid": "AB12CD34-...",
  "dt_item_link": "x-devonthink-item://AB12CD34-...",
  "relation_type": "supports",
  "relation_status": "proposed"
}
```

## Preferred tool path

**Offline build (preferred):**

```bash
# Step 1: mint ID
scripts/pkim mint-id --type relation

# Step 2: build draft
scripts/pkim build-relation-note \
  --pkim-id RL-YYYYMMDD-NNNN \
  --source-pkim-id KN-YYYYMMDD-NNNN \
  --target-pkim-id KN-YYYYMMDD-NNNN \
  --relation <type> \
  --rationale "<specific rationale>" \
  --interpretation "<reader-oriented interpretation>" \
  --format json

# Step 3: push via dt-push-batch (see that skill)
```

**Direct write (single note):**

```bash
scripts/pkim create-relation-note \
  --source "<ref>" \
  --target "<ref>" \
  --relation <relation_type> \
  --rationale "<specific rationale>" \
  --live \
  --format json
```

Add `--reviewed` only when you have read both records carefully and are confident in the relation type and rationale.
