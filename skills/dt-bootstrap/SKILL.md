---
name: dt-bootstrap
description: Install or repair the canonical PKIM configuration in DEVONthink — canonical group trees, custom metadata fields, text-predicate smart groups, note templates. Use when pkim-primer's preflight reports a gap, when onboarding a new machine, when adding a new PKIM database, or when the user says 'bootstrap PKIM', 'set up PKIM', 'install PKIM config', 'the smart groups are wrong', or 'the metadata fields are missing'. Idempotent — safe to re-run.
---

> **Runtime.** DEVONthink 4.3+ in-app MCP server. Assumes [`pkim-primer`](../pkim-primer/SKILL.md) has been read — this skill installs the *configuration* the primer describes.

# dt-bootstrap

Bootstrap the canonical PKIM configuration in DEVONthink. Idempotent — every step re-checks what's present before mutating, so re-running never duplicates or overwrites.

Five phases: databases, group trees, custom metadata fields, smart groups, note templates. Each phase's mutation calls are DT MCP tools; each phase completes when the check that opens it re-passes.

## When to invoke

- The `pkim-primer` preflight (`is_running` + `get_databases` + `list_custom_metadata_fields`) reports a gap.
- Onboarding a new machine.
- Adding a new PKIM database that needs the canonical group tree.
- After a manual DEVONthink change that broke a smart group (e.g. someone edited a predicate through the GUI).

## Preflight

Same three DT MCP calls the primer names. Do not proceed unless DT is running. If the required databases aren't open, surface the missing names to the operator and pause — this skill doesn't create databases (that's a manual DEVONthink step, because the on-disk location is a choice: local for evidence, iCloud-indexed for `PKIM-Knowledge`).

## Canonical configuration

The exact shape lives in [references/canonical-config.md](references/canonical-config.md) — read it once at the start of a bootstrap run. It carries:

- The five databases and their expected on-disk classes (local vs iCloud-indexed).
- The two group-tree shapes (`knowledge` and `evidence`) and which databases get which.
- The ten canonical smart groups with their text predicates and which databases each lives in.
- The four `PKIM-Knowledge/Templates/` note templates.

The custom metadata schema is documented in [`../pkim-primer/references/metadata-schema.md`](../pkim-primer/references/metadata-schema.md) — canonical field list, types, valid enum values.

## Phase 1 — group trees

For each open canonical database, ensure its group tree exists. `create_group_path` is idempotent — passing an existing path returns the existing group, so this phase is safe on a run where the tree is already there.

```
for each database in {PKIM-Knowledge, PKIM-Evidence-*, PKIM-Pilot}:
    shape = "knowledge" if name == "PKIM-Knowledge" else "evidence"
    for each path in canonical_groups[shape]:
        mcp__devonthink__create_group_path(database_uuid=<db.uuid>, path=<path>)
```

**Completion criterion for Phase 1:** for every open canonical database, `lookup_records location: "<path>"` resolves for every path in the canonical group list for that database's shape. Do not proceed to Phase 2 until this holds — a missing group later derails the smart-group + template steps.

## Phase 2 — custom metadata fields

Compare `list_custom_metadata_fields` against the canonical field list in [`../pkim-primer/references/metadata-schema.md`](../pkim-primer/references/metadata-schema.md). For each missing field:

1. Create a scratch markdown record in `PKIM-Pilot` via `create_record`.
2. Write a placeholder value for the missing field via `set_record_custom_metadata mode: "merge"`. DT auto-registers the field with the type inferred from the value — so **pick a value with the right type on the first write**: boolean fields need `true` / `false`, dates need ISO 8601 strings, set (enum) fields need a valid vocabulary value.
3. Trash the scratch record via `trash_record`.

**Completion criterion for Phase 2:** every canonical field name appears in the re-fetched `list_custom_metadata_fields` result, and every `set`-type field's `values` matches its canonical vocabulary. Fields that autoregistered with wrong types (rare — usually a value typo on the first write) need manual repair in DEVONthink; surface those to the operator.

## Phase 3 — smart groups

DEVONthink's GUI smart-group picker emits **binary NSPredicates** that query the internal field index. DT MCP writes go to the raw customMetaData dictionary. Only **text predicates** query the raw dictionary — which means only text predicates match records whose metadata is written via MCP. This is why Phase 3 rebuilds any smart group whose predicate isn't text-form.

For each canonical smart group × its scope of databases:

1. Look up by path: `lookup_records location: "/<name>"` in the database.
2. If missing → create via `create_record` with `type: "smart-group"`, `name`, `search predicate: <canonical text predicate>`, `destination: <db root UUID>`.
3. If present → read `searchPredicates` via `get_record_properties`. Compare to the canonical text predicate.
   - If identical → skip.
   - If different (usually because it's a binary predicate the GUI created) → `trash_record` and recreate.

**Completion criterion for Phase 3:** every canonical smart group resolves via `lookup_records`, its `searchPredicates` reads back as the exact canonical text form, and searching against it returns non-nonsense results (a quick sanity check on `Needs Filing` should return records with `mdreview_state=="approved"`). Skip the sanity check if the corpus is empty.

## Phase 4 — note templates

Only for `PKIM-Knowledge`. Four templates live under `/Templates`: `Knowledge Note`, `Relation Note`, `Topic Note`, `Project Note`. Bodies are in `assets/{knowledge,relation,topic,project}.md`.

For each template:

1. Look up: `lookup_records location: "/Templates/<Template Name>" database_uuid: <PKIM-Knowledge>`.
2. If present → skip.
3. If missing → read the body from `assets/<slug>.md`, then `create_record type: markdown, name: "<Template Name>", content: <body>, destination: <Templates group UUID>`.

**Completion criterion for Phase 4:** all four templates resolve at their canonical paths.

## Phase 5 — verify

Re-run the primer's preflight:

```
mcp__devonthink__is_running
mcp__devonthink__get_databases
mcp__devonthink__list_custom_metadata_fields
```

Plus one canonical-config spot-check: `lookup_records location: "/Needs Filing" database_uuid: <PKIM-Knowledge>` should resolve. Anything that fails here contradicts an earlier phase's completion — surface to the operator; don't declare success on a re-check that didn't pass.

**Completion criterion for the whole skill:** all four earlier phase criteria hold, plus Phase 5 verifies clean.

## Report

Emit a summary keyed by database:

```
dt-bootstrap 2026-07-15
--
PKIM-Knowledge:      groups 11/11    fields all present    smart groups 4/4    templates 4/4
PKIM-Pilot:          groups 11/11    smart groups 5/5      (no templates — knowledge-only)
PKIM-Evidence-Personal:  groups 11/11    smart groups 5/5
...
```

Distinguish "created this run" from "already present" in the log so re-runs of a clean environment produce all-`already-present` output.

## Stop conditions

- A required database is not open → pause; surface to the operator; do not proceed to any phase.
- A set-field autoregistered with the wrong type (Phase 2) → surface; requires DEVONthink UI intervention.
- Phase 5 verification fails on something an earlier phase claimed to complete → the completion criterion for that phase was wrong; surface the exact call + response and stop.

## Anti-patterns

- **Skipping the phase-boundary re-checks.** Each phase's completion criterion is there because the next phase depends on it. Charging ahead is how "the smart groups don't work" becomes "the metadata fields aren't registered either."
- **Editing DEVONthink through the GUI mid-run.** The bootstrap is reading DT state to decide what to write; concurrent GUI edits cause it to make wrong decisions.
- **Bootstrapping when the primer's preflight already passes clean.** No-op runs are safe (idempotent) but noisy — the primer's completion criterion catches this earlier.

## Assets

- [assets/knowledge.md](assets/knowledge.md), [assets/relation.md](assets/relation.md), [assets/topic.md](assets/topic.md), [assets/project.md](assets/project.md) — canonical note-template bodies. Phase 4 reads these verbatim into `create_record content`.

## Related skills

- [`pkim-primer`](../pkim-primer/SKILL.md) — the vocabulary + rules this skill's configuration exists to serve. Read first.
- [`dt-intake`](../dt-intake/SKILL.md) — the inbox-to-filed workflow that assumes bootstrap has been run.
- [`dt-audit`](../dt-audit/SKILL.md) — the graph-health audit; assumes the canonical smart groups from Phase 3 exist.
