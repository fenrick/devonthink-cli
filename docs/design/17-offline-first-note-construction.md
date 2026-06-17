# Offline-First Note Construction

## Purpose

This document specifies the architectural shift from online-first to offline-first note construction in PKIM.

It answers:

- Why the current model has a sequencing problem
- What the offline-first model replaces it with
- What changes are required across the operating system, skills, scripts, and working surface

## The Problem with the Current Model

Notes are currently created directly in DEVONthink one at a time. UUIDs only exist after DT creation, so cross-references between notes must use `x-devonthink-item://UUID` links — which require the target to already exist in DT before the reference can be written.

This creates three compounding problems:

1. **Sequencing dependency.** Relation notes cannot reference knowledge notes until those knowledge notes have been created. Creation order is a constraint on authoring order.
2. **`## Related Notes` is always empty at creation.** There is no way to pre-populate it because the related note UUIDs are not known yet. A separate backfill pass is required.
3. **No graph coherence check before writes.** Notes go into DT as they are created. A broken reference is only detectable after the fact.

## The Offline-First Model

Authoring happens entirely offline. Notes are built as markdown files in a local staging area before any DT writes occur. All cross-references use `[[PKIM_ID]]` WikiLinks, which DT resolves via the alias registered on each record.

The creation step becomes a push: records are created in DT in a defined order, aliases are set at creation time, and `dt_item_link` is written into frontmatter at that moment. Because knowledge notes are pushed before relation notes, all alias targets are already registered by the time relation notes are created — making `[[PKIM_ID]]` links immediately resolvable with no write-back pass needed.

### Why `[[PKIM_ID]]` Links Work

DEVONthink resolves WikiLinks against document names and aliases. When a record has alias `KN-20260429-0001`, any note body containing `[[KN-20260429-0001]]` will link to that record. DT counts these as outgoing/incoming links in its link graph, identical to `x-devonthink-item://UUID` links. PKIM_IDs are unique by construction, so alias collision is not a risk.

### Role of `x-devonthink-item://` Links

`x-devonthink-item://UUID` links remain in use for one purpose only: **external entry into DT from outside the knowledge base** — CLI tools, other applications, and any system navigating into a specific DT record by direct reference. These belong in the `dt_item_link` frontmatter field, written at push time. They do not appear in note bodies.

## Link Format by Location

WikiLinks (`[[alias|display]]`) only resolve within the same database. Since evidence records live in PKIM-Pilot and notes live in PKIM-Knowledge, cross-database links must use the full `x-devonthink-item://` URL format.

| Location | Format | Example |
|---|---|---|
| `## References` in relation notes | `[[PKIM_ID\|Name]]` | `[[KN-20260429-0003\|Market Place Design]]` |
| `## Related Notes` in knowledge notes | `[[RL-PKIM_ID\|Title]] rel_type [[KN-PKIM_ID\|Name]]` | `[[RL-20260429-0013\|...]] supports [[KN-20260429-0001\|Business Design Framework]]` |
| `## Interpretation` narrative cross-refs | `[[PKIM_ID\|Name]]` | `[[KN-20260429-0001\|Business Design Framework]]` |
| `## Evidence Links` in knowledge notes | `[Name — Author (Year)](x-devonthink-item://UUID)` | `[This Is Business Design — Aitken (2025)](x-devonthink-item://UUID)` |
| Frontmatter `dt_item_link` | `x-devonthink-item://UUID` | External handle; written at push time |
| Frontmatter `source_item` / `target_item` | `x-devonthink-item://UUID` | Relation record metadata for CLI lookup |

### Why two formats

Same-database graph links use `[[PKIM_ID|display]]`: the alias resolves within PKIM-Knowledge, the display name is human-readable, and DT can auto-update the display name if a note is renamed via its built-in link maintenance tool.

Cross-database evidence links use `[Name](x-devonthink-item://UUID)`: WikiLinks do not resolve across databases in DEVONthink. The UUID link works cross-database and DT's link update tool can maintain the display name when the evidence document is renamed.

## Push Ordering and Write-Back Avoidance

Push in this order to ensure alias targets exist before references are created:

1. **Knowledge notes** — pushed first; alias set to PKIM_ID at creation; `dt_item_link` recorded in frontmatter immediately
2. **Relation notes** — pushed second; all `[[PKIM_ID]]` references in body are already resolvable because step 1 registered the aliases

No post-push write-back pass is required. `dt_item_link` for each note is populated at the moment of creation in the push response, not after a separate resolution step.

## Working Surface Changes

### New: `workspace/` Folder

A local staging area for offline note construction. Gitignored. Contains:

```
workspace/
  drafts/          — notes under construction (not yet validated)
  batches/         — validated note sets ready to push
    <batch-id>/
      manifest.json        — batch metadata: IDs, types, push order
      knowledge/           — knowledge note markdown files
      relations/           — relation note markdown files
```

`workspace/` is ephemeral. Once a batch is pushed, the canonical state is in DT. The staging files can be discarded or archived to `runs/`.

Add to `.gitignore`:

```
/workspace
```

### `inputs/` Remains Local-Only

No change. Source material remains in `inputs/`, untracked.

## Script and Command Changes

### New Commands

| Command | Purpose |
|---|---|
| `pkim build-knowledge-note` | Build a knowledge note markdown file offline into `workspace/drafts/`; accepts same arguments as current `create-knowledge-note` but writes to disk rather than DT |
| `pkim build-relation-note` | Build a relation note markdown file offline into `workspace/drafts/`; uses `[[PKIM_ID]]` links throughout |
| `pkim validate-batch` | Check all `[[PKIM_ID]]` references in a batch resolve to notes in the same batch or already in DT; report broken references before any writes |
| `pkim push-batch` | Push a validated batch to DT in correct order (knowledge first, then relations); sets alias at creation; writes `dt_item_link` to frontmatter |

### Changed Commands

| Command | Change |
|---|---|
| `create-knowledge-note` | Remains for single-note interactive use; gains `--to-workspace` flag to write offline instead of pushing live |
| `create-relation-note` | Remains for single-note interactive use; switches References section to `[[PKIM_ID]]` format |
| `update-relation-note` | Already fixed for WikiLink bug; ensure `source_item` / `target_item` in customMetaData still use UUID for CLI lookup, but body uses `[[PKIM_ID]]` |
| `sync-mirror` | No structural change; mirror export reflects note bodies as-is (containing `[[PKIM_ID]]` links) |

### `mint-id` Promotion

PKIM ID minting is currently internal to `create_note.py` (`_mint_pkim_id`). Promote to a first-class CLI command:

```bash
scripts/pkim mint-id --type knowledge   # → KN-20260430-0001
scripts/pkim mint-id --type relation    # → RL-20260430-0001
```

This is the entry point for offline authoring. IDs are allocated before any DT interaction.

## Note Format Changes

### Relation Notes

`## References` section changes from:

```markdown
## References

- Source: [Operating Model Design](x-devonthink-item://UUID-1)
- Target: [Business Design Framework](x-devonthink-item://UUID-2)
```

To:

```markdown
## References

- Source: [[KN-20260429-0015]]
- Target: [[KN-20260429-0001]]
```

`source_item` and `target_item` in customMetaData remain as `x-devonthink-item://UUID` (CLI tooling uses these for record lookup, not DT's link graph).

### Knowledge Notes

`## Related Notes` is pre-populated at authoring time using a sentence-style format where the RL link wraps the **relation type word**, and the current note's name appears as plain text (either leading or trailing depending on perspective).

From the **source note** (current note is the source of the relation):

```markdown
## Related Notes

- Market Place Design [[RL-20260429-0025|precedes]] [[KN-20260429-0005|Operating Model Design]]
- Market Place Design [[RL-20260429-0011|supports]] [[KN-20260429-0001|Business Design Framework]]
```

From the **target note** (current note is the target of the relation):

```markdown
## Related Notes

- [[KN-20260429-0003|Market Place Design]] [[RL-20260429-0025|precedes]] Operating Model Design
```

Rules:
- The current note's name is always **plain text** (not a WikiLink) — you are already on that note.
- The other note is always a `[[PKIM_ID|Name]]` WikiLink so DT can auto-update the display name on rename.
- The RL link (`[[RL-PID|rel_type]]`) uses the relation type word as display text — DT can navigate from the link and update the display on rename.
- No inversion of relation type for target-perspective entries; the relation type word is always the original (e.g., "precedes", not "is preceded by").
- Use `note_format.format_related_note_entry()` to generate entries programmatically.

## Skills Changes

### `dt-build-knowledge-note`

- Step 1 becomes: `pkim mint-id --type knowledge` — get the ID before anything else
- Authoring steps write to `workspace/drafts/` using the offline builder
- Related Notes section is populated during authoring using known relation IDs from the current batch
- Push step uses `pkim push-batch` or the batch path of `create-knowledge-note --to-workspace`
- Tags and alias registration happen at push time (alias = PKIM_ID, set via JXA at creation)

### `dt-build-relation-note`

- Step 1: `pkim mint-id --type relation`
- References section uses `[[PKIM_ID]]` from the start — no UUID lookup required
- Validation step: confirm both source and target PKIM_IDs are registered in DT (aliases exist) or present in the current batch before push
- Push after knowledge notes are confirmed pushed

### New Skill: `dt-push-batch`

A new skill covering:

1. Validate batch (`pkim validate-batch`)
2. Push knowledge notes in order
3. Confirm aliases registered for each pushed note
4. Push relation notes
5. Verify link resolution for a sample of `[[PKIM_ID]]` references
6. Sync mirror if all notes have `review_state=approved`

### `dt-safe-file`, `dt-profile-record`, `dt-apply-approved-metadata`

No structural changes. These operate on already-created DT records and are not part of the authoring flow.

## Operating System Document Changes

| Document | Change |
|---|---|
| `05-workflows.md` | Add Workflow 6: offline batch construction and push; update Workflow 3 (evidence to knowledge) to show offline authoring path |
| `08-record-and-note-specification.md` | Update link format table; document `[[PKIM_ID]]` as canonical body link format |
| `09-automation-architecture.md` | Add `workspace/` to working surface; document push ordering constraint |
| `12-project-hygiene-and-work-surface.md` | Document `workspace/` lifecycle (draft → validated batch → pushed → archived to `runs/`) |

## What Does Not Change

- PKIM_ID format and minting logic
- customMetaData field names and values
- `review_state` lifecycle
- Mirror export format and path
- `dt_item_link` in frontmatter (still UUID, still written at push)
- `source_item` / `target_item` in relation customMetaData (still UUID, used by CLI)
- Safe-file, profile, and metadata skill workflows
- Graph audit and reconciliation tooling (reads customMetaData, not note body links)

## Transition: Existing Notes

The 55 notes currently in DT (31 knowledge + 24 relations) use `x-devonthink-item://UUID` links in `## References`. These continue to work — DT tracks both UUID links and alias WikiLinks. Backfilling them to `[[PKIM_ID]]` format is desirable for consistency but is not a blocker for adopting the new model going forward.

A single targeted JXA pass can rewrite existing relation note References sections when convenient.

## Success Criteria

- `pkim mint-id` works as a standalone CLI command
- A knowledge note can be fully authored offline with correct `[[PKIM_ID]]` links before any DT write
- `pkim validate-batch` catches broken references before push
- After a batch push, all `[[PKIM_ID]]` links in relation note bodies resolve in DT with no write-back step
- `## Related Notes` sections in pushed knowledge notes are populated, not empty
- `dt_item_link` frontmatter is written at creation time in the push response
