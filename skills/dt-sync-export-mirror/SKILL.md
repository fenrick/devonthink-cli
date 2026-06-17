---
name: dt-sync-export-mirror
description: Export approved canonical PKIM notes from DEVONthink into the filesystem mirror while preserving PKIM identity and provenance. Make sure to use this skill whenever the user asks to refresh the mirror, export approved notes to Markdown, inspect mirror drift, or sync the canonical note layer to the repo-facing export surface, even if they only say "refresh the mirror."
compatibility: Works in any runtime that can read approved native notes and write within the configured export root. The local `scripts/pkim sync-mirror` command is the preferred deterministic tool path when available.
---

# dt-sync-export-mirror

This skill exists because the mirror is not just an export folder. It is the portability surface for canonical notes. If the export is sloppy, identity and traceability break downstream.

Your job is to produce a trustworthy one-way mirror from the canonical note layer.

## What this skill is for

Use it when canonical notes need to be reflected into filesystem Markdown:

- export changed approved notes
- rebuild the full mirror
- inspect which notes would export
- refresh mirror files before downstream tooling uses them

The result should be a clean export manifest and a mirror that still preserves PKIM identity.

## Why this matters

The mirror is how PKIM leaves DEVONthink without losing traceability. It needs:

- stable paths
- stable identity
- provenance in frontmatter
- explicit drift reporting

This is not a generic sync job. It is a policy-bound export.

## Two parallel mirror artefacts

Since WP2.1 the mirror produces two parallel artefacts from the same source-of-truth:

1. **Markdown export** (this skill) — portable YAML-frontmatter files for Git, external tooling, and disaster recovery. Lives under the configured export root.
2. **SQLite graph** — the analytical surface used by `pkim audit-discipline`, `pkim deep-profile`, `pkim.mirror.audits`, `pkim.mirror.propagation`, and the `Claim_Backed` write-back loop. Built via `pkim.mirror.build_mirror_graph(reader, databases, db_path=...)`; rebuilt on every refresh, never authoritative for records (DT remains source of truth).

Both artefacts use the same `DTReader` walk and the same body parsing, so a Markdown export run and a graph-rebuild run see the same corpus state. The graph DB is intended to be regenerated cheaply, not retained as historical archive — for that, use the Markdown export.

## Workflow

Follow this sequence.

1. Identify which canonical notes are eligible to export.
2. Restrict to the requested scope:
   - changed
   - all
3. For each note:
   - build stable frontmatter
   - preserve PKIM ID
   - preserve DEVONthink item-link provenance
   - choose the correct subtree
4. Write exports only inside the configured mirror root.
5. If the intended workflow includes writeback, update mirror-state metadata only after successful export.
6. Emit a manifest showing what exported, where it landed, and what failed.

## How to think about export quality

### Frontmatter fields

Every exported note must carry frontmatter with at minimum these fields:

```yaml
---
pkim_id: KN-20260417-0021
dt_uuid: 03CF4017-1689-4112-9213-E96C1EA37FD0
dt_item_link: x-devonthink-item://03CF4017-1689-4112-9213-E96C1EA37FD0
doc_role: knowledge
note_type: synthesis
review_state: approved
mirrored_at: 2026-04-17T14:10:00Z
mirror_path: knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md
---
```

Relation notes additionally include:

```yaml
source_item: x-devonthink-item://SOURCE-UUID
target_item: x-devonthink-item://TARGET-UUID
relation_type: supports
```

Do not export notes without `pkim_id` and `dt_item_link`. Without these, the mirror file cannot be traced back to its canonical record.

### Mirror naming

Use the stable ID in the filename, not the title alone:

- `knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md`
- `relations/RL-20260417-0004-problem-framing-supports-local-first-pkim.md`

Titles drift. IDs do not. Do not rename existing mirror files unless the PKIM_ID has also changed, which should never happen.

### What counts as drift

Drift is the condition where canonical note state in DEVONthink differs from what the mirror reflects. Specific drift signals:

- a note's content changed since `LastMirroredAt`
- a note's `Review_State` advanced but `Mirror_State` was not updated
- a note has `Review_State=approved` but no mirror file exists
- a mirror file exists with no corresponding live note
- a mirror file has a different `pkim_id` or `dt_item_link` than the canonical record

Report each drift case individually. Do not aggregate drift into a single count without per-record detail.

### Eligibility filter

Only export notes where `Review_State=approved`. Notes in any other state are not ready for the portable surface. Do not force-export draft or profiled notes.

### Reconciliation before export

Not all note changes are equivalent. Some changes to a canonical note imply that the relation graph around it also needs review before the updated version is exported. Exporting a note whose semantic content has changed without checking its edges can make the mirror a more accurate reflection of a graph that is now partially wrong.

**Defer export and switch to `skills/dt-reconcile-relation-edge/SKILL.md` first when any of these conditions are true:**

- The note's main claim changed: the summary was substantially rewritten, not just edited
- A key point was removed or its meaning reversed
- The note's `NoteType` changed (for example, from `seed` to `synthesis`)
- An evidence link was removed or replaced with a different source
- The note was assigned a new `PrimaryTopic` that shifts its graph neighbourhood

**Export immediately without reconciliation when:**

- The change is editorial: typo fixes, formatting, word choice
- Evidence links were added without any removed
- Tags were updated without changing the conceptual content
- The note's `Review_State` advanced without content changes

When deferring export for reconciliation, record the deferred note in the export manifest with `status: deferred-for-reconciliation`. Do not count a deferred note as exported or failed — it is pending.

### The mirror is representation, not authority

Never edit mirror files and treat those edits as canonical changes. Always flow from DEVONthink → mirror, not the reverse. Frontmatter and export paths are regenerated on each export; the note body is the only thing that should require authoring attention.

## How to know you are doing it right

You are doing this skill correctly when:

- export paths are stable
- relation notes land under the relation subtree
- failures are tied to specific records or paths
- the manifest is enough to diagnose drift later

You are doing it badly when:

- paths change unnecessarily
- provenance is lost
- partial export is reported as clean

## What not to do

- Do not write outside the configured export root.
- Do not treat mirror files as canonical truth.
- Do not enable writeback casually.
- Do not hide export failures in vague summaries.

## Output

Produce an export manifest written to `runs/<run-id>/export-manifest.json`. Canonical shape:

```json
{
  "run_id": "RUN-2026-04-17T14-10-00Z",
  "mode": "live",
  "database": "PKIM-Knowledge",
  "export_root": "/path/to/your/checkout/mirror",
  "scope": "changed",
  "mirrored_at": "2026-04-17T14:10:00Z",
  "records": [
    {
      "pkim_id": "KN-20260417-0021",
      "dt_uuid": "03CF4017-...",
      "doc_role": "knowledge",
      "export_path": "knowledge/KN-20260417-0021-problem-framing-in-local-second-brain-systems.md",
      "content_hash": "sha256:abc123...",
      "status": "updated"
    }
  ],
  "failures": [],
  "drift_detected": [],
  "result": "ok"
}
```

Valid `status` values per record: `updated` (file written or overwritten), `skipped` (unchanged since last mirror), `failed` (write error).

The `drift_detected` array should contain one entry per note with a drift signal — note that some drift conditions (missing mirror file for an approved note) may appear in `records` with `status: updated` rather than here if the export corrected it.

A `result` of `"partial"` means at least one record failed. Report partial export explicitly — do not claim `"ok"` if any failures are present.

## Preferred tool path

When the local CLI is available, use:

```bash
scripts/pkim sync-mirror --scope changed --format json
```

Use `--scope all` for a full refresh. Add `--live` only when mirror-state writeback is also intentionally part of the run.
