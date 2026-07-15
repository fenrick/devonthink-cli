# PKIM Build Plan

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces it.

## Purpose

Living operational plan for the PKIM build. Update this file when a step changes status, when acceptance criteria are revised, or when a decision made during execution changes scope or sequencing.

**Source of truth for sequencing rationale:** the recommended build order agreed 2026-04-17.
**Source of truth for design contracts:** `docs/design/` register.
**Source of truth for work package detail:** `docs/design/14-implementation-work-packages.md`.

Use this file for build history and remaining operational backlog. Do not read it to understand the current operating workflow; use [operating-rhythm.md](operating-rhythm.md) and [intake-runbook.md](intake-runbook.md) instead.

---

## How to use this file

- Mark each step `[ ]` pending / `[~]` in progress / `[x]` done / `[!]` blocked.
- Record decisions, blockers, and outcome notes in the step's **Notes** section.
- When a step completes, confirm the relevant design doc is still accurate before moving on.
- Do not start a step unless its dependencies are marked done.

---

## Status

| Step | Title | Status | WPs |
|---|---|---|---|
| 01 | Freeze design contract | [x] | — |
| 02 | Build pilot DEVONthink databases | [x] | WP-01, WP-02 |
| 03 | Build canonical note layer | [x] | WP-01, WP-06 |
| 04 | Build queue and review model | [x] | WP-01 |
| 05 | Build export mirror | [x] | WP-09 |
| 06 | Build capability probe | [x] | WP-04 |
| 07 | Build read-only agent skills | [x] | WP-05 |
| 08 | Test on 50–100 document pilot corpus | [x] | WP-02, WP-05 |
| 09 | Add metadata writeback | [x] | WP-08 |
| 10 | Add relation-note creation automation | [x] | WP-07 |
| 11 | Add manual filing support | [x] | WP-10 |
| 12 | Add import and inbox choreography | [x] | WP-07, WP-10 |
| 13 | Add controlled move and replicate automation | [x] | WP-10 |
| 14 | Add indexed-folder automation | [x] | WP-10 |
| 15 | Consolidate shared write routing | [x] | WP-08, WP-10 |
| 16 | Add reporting and dashboards | [x] | WP-11 |
| 17 | Scale beyond pilot | [x] | — |
| 18 | Reconcile runtime truth across docs | [x] | — |
| 19 | Tighten operational readiness gates | [x] | WP-11 |
| 20 | Add graph audit and hygiene automation | [x] | — |
| 21 | Add candidate provenance ledger | [x] | — |
| 22 | Add repeatable workflow validation harness | [x] | WP-02, WP-11 |
| 23 | Finish skill packaging scaffolding | [x] | WP-12 |

## Full Deep Pass Readiness Checklist

Do not start the full deep pass until all of the following are confirmed:

- [ ] Controlled deepening pass completed (`docs/ops/controlled-deepening-pass.md`)
- [ ] Controlled pass evaluation rubric scored; averages at least 1.5, no category below 1
- [ ] Working-process docs updated from actual use during the controlled pass
- [ ] Candidate triage checkpoint is enforced and documented
- [ ] At least one dense source produced a sensible 1+ concept set without over-minting
- [ ] At least one rerun showed stable candidate fingerprints with no duplicate notes or edges
- [ ] Graph audit produced actionable, not overwhelming, findings
- [ ] Mirror validation passed: all approved notes mirrored with complete frontmatter
- [ ] A sample of relation edges reviewed and confirmed well-typed
- [ ] Repair workflow (`dt-recover-failed-write`, `dt-execute-repair-plan`) tested on at least one real issue
- [ ] Backup and restore path confirmed fresh (restore-drill evidence within 168 hours)
- [ ] Documentation debt section from the controlled pass has been resolved or explicitly deferred
- [ ] DEVONthink `Relation_Type` Selection field verified to contain all 8 closed-list values: `contradicts`, `exemplifies`, `extends`, `precedes`, `references`, `summarizes`, `supersedes`, `supports`
- [ ] All knowledge and relation notes from the controlled pass have tags and PKIM_ID alias set; confirmed visible in DT tag navigation

## Operational Backlog

- Keep command docs current when the local surface changes again.
- Replace the generic skill-package eval placeholders with skill-specific prompts as each skill is exercised in anger.
- Extend the workflow-validation harness with live write rehearsal cases when a stable scratch corpus exists for those paths.
- Keep graph-audit heuristics honest; do not let the issue catalogue drift away from real failure modes seen in the corpus.

---

## Step Detail

### Step 01 — Freeze design contract

**Status:** [x]
**Blocks:** everything else
**Design refs:** `docs/design/01`, `03`, `07`, `08`, `16`

Lock the following before any automation is built:

- `PKIM_ID` format and minting rules
- `DocRole` vocabulary
- `Review_State` vocabulary
- Relation-note contract (required fields, rationale obligation)
- Import vs index policy per library (Personal, Work, Server)
- Mirror contract (what is exported, when, naming convention)
- Write-gating policy (what conditions enable live writes)

**How:**
- Read all relevant design docs and confirm each locked item is unambiguous.
- If any item is still described with hedging language ("suggested", "probably"), resolve it explicitly.
- Record the locked state in `docs/design/00-source-reconciliation.md` with a datestamp.
- Update `docs/design/16-evidence-policy-by-library.md` to confirm per-library import/index policy.

**Acceptance criteria:**
- Each locked item has one definitive value or rule, not alternatives.
- No design doc uses "probably", "might", or "TBD" for any locked item.
- `docs/design/00` records the freeze date.

**Notes:**
Completed 2026-04-17. Seven items resolved:
- PKIM_ID locked as date-scoped 4-digit sequence (was "random-or-sequence")
- Review_State reconciled across docs 03 and 08 — full 9-value list including both `mirrored` and `error`
- Relation_Type vocabulary created from scratch — 8 types, closed list
- Relation-note rationale locked as mandatory
- PKIM-Evidence-Personal index exception conditions made explicit
- PKIM-Evidence-Server mount stability conditions made explicit
- Mirror trigger locked to observable field state (Review_State=approved + Mirror_State stale)
All decisions recorded in docs/design/00-source-reconciliation.md.

---

### Step 02 — Build pilot DEVONthink databases

**Status:** [x]
**Blocked by:** Step 01
**Blocks:** Steps 03, 04, 06, 07, 08
**Design refs:** `docs/design/07`, `docs/design/14` WP-01, WP-02

Create the following locally in DEVONthink Pro 4.1:

- `PKIM-Pilot` — scratch database, NOT in a cloud-synced path
- `PKIM-Knowledge` — canonical knowledge database
- `PKIM-Evidence-Personal` — personal evidence
- `PKIM-Evidence-Work` — work evidence (may be empty or minimal at pilot stage)

For each database, create the top-level group structure per `docs/design/07`:

- Knowledge: `/Inbox`, `/Notes/Literature`, `/Notes/Synthesis`, `/Notes/Relations`, `/Notes/Topics`, `/Notes/Projects`, `/Templates`, `/Operations`, `/Archive`
- Evidence: `/Inbox`, `/Sources/Imported`, `/Sources/Indexed`, `/Captures/Web`, `/Captures/Bookmarks`, `/Captures/Scans`, `/Working`, `/Review`, `/Archive`

Define and create the canonical custom metadata fields in DEVONthink per `docs/design/08`:

- `PKIM_ID` (text)
- `DocRole` (text or list)
- `Review_State` (text or list)
- `Origin_URI` (text)
- `Origin_Last_Path` (text)
- `Source_Item` (text)
- `Target_Item` (text)
- `Relation_Type` (text)
- `Mirror_Path` (text)
- `Content_SHA256` (text)
- Evidence-specific: `EvidenceStatus`, `CaptureType`, `CanonicalSourceURL`
- Knowledge-specific: `NoteType`, `KnowledgeStatus`
- Relation-specific: `RelationConfidence`, `RelationStatus`
- Queue signals: `Needs_OCR`, `Knowledge_Link_State`, `Relation_Gap_State`, `Indexed_Risk_State`, `Mirror_State`, `Automation_Last_Run_State`

Verify `PKIM-Pilot` is NOT stored inside iCloud Drive, Dropbox, or any other synced path.

**Repo deliverable:** update `docs/ops/compatibility-matrix.md` with the actual DEVONthink version and the list of metadata fields as created. Update `build-plan.md` Step 02 to `[x]`.

**Acceptance criteria:**
- All five databases exist locally and are open in DEVONthink.
- All top-level groups are present as specified.
- All metadata fields are defined and visible in DEVONthink's custom metadata panel.
- `PKIM-Pilot` path does not contain iCloud or any sync-service directory component.

**Notes:**
Repo deliverables complete 2026-04-17:
- `scripts/setup-database-groups.applescript` — creates group structure in all databases (idempotent)
- `scripts/verify-database-setup.applescript` — verifies group structure, reports pass/fail
- `docs/ops/setup-checklist.md` — step-by-step guide for manual DEVONthink work (databases + metadata fields)
- `docs/ops/compatibility-matrix.md` — expanded with database inventory, 30-field metadata table, scratch test status

Completed 2026-04-18:
- All 5 databases created and open, paths confirmed not cloud-synced.
- All 30 metadata fields defined. Vocabulary-constrained fields created as Selection type (DocRole, Review_State, Relation_Type, CreatedByMode, EvidenceStatus, CaptureType, NoteType, KnowledgeStatus, RelationStatus, Automation_Last_Run_State).
- `osascript scripts/verify-database-setup.applescript` → Pass: 59, Fail: 0.
- `uv run pkim health-check --format json` → result: ok.
- MCP not installed; capability probe via AppleScript verify script only.
- AppleScript bundle ID targeting confirmed: `com.devon-technologies.think`.
- `docs/ops/compatibility-matrix.md` filled in: DEVONthink 4.1.1, macOS 26.5, Python 3.14.4.

---

### Step 03 — Build canonical note layer

**Status:** [x]
**Blocked by:** Step 02
**Blocks:** Steps 07, 08, 10
**Design refs:** `docs/design/08`, `docs/design/07` (knowledge capture section)

Create the following native DEVONthink note templates in `PKIM-Knowledge/Templates/`:

1. **Knowledge note template** — MultiMarkdown metadata header with `PKIM_ID`, `DocRole`, `NoteType`, `Review_State`, `Aliases`, `PrimaryTopic` placeholders. Sections: Summary, Key points, Evidence links, Related notes.
2. **Relation note template** — header with `PKIM_ID`, `DocRole=relation`, `Relation_Type`, `Source_Item`, `Target_Item`, `Review_State`, `RelationStatus` placeholders. Sections: Why this relation exists, Interpretation.
3. **Topic note template** — header with `PKIM_ID`, `DocRole=topic`, `NoteType=topic`, `Review_State`. Sections: What this topic means, What it excludes, Key notes, Key evidence, Open questions.
4. **Project note template** — header with `PKIM_ID`, `DocRole=project`, `NoteType=project`, `Review_State`. Sections: Goal, Context, Notes, Evidence, Status.

Document the alias policy:
- `PKIM_ID` must appear in the `Aliases` field on every canonical knowledge note.
- WikiLinks are for discovery; item links are for stable references.
- Relation notes must use `x-devonthink-item://` links for `Source_Item` and `Target_Item`, never WikiLinks.

**Repo deliverable:** add `prompts/create-knowledge-note.md`, `prompts/create-relation-note.md` as completed prompt contracts (update the existing stubs to include the exact template structure, alias rules, and link rules). Update `build-plan.md` Step 03 to `[x]`.

**Acceptance criteria:**
- All four templates exist in `PKIM-Knowledge/Templates/`.
- Each template produces a valid note when applied in DEVONthink.
- Alias policy and link rules are written explicitly in `docs/design/08` (or a confirmed addendum).
- Prompt stubs in `prompts/` reflect the real template structure.

**Notes:**
Completed 2026-04-18:
- `scripts/install-note-templates.applescript` — installs all 4 templates into PKIM-Knowledge/Templates/ (idempotent). Run with `osascript scripts/install-note-templates.applescript`.
- `prompts/create-knowledge-note.md` — full executable contract: inputs, pre-conditions, dry-run output, live write steps, failure modes.
- `prompts/create-relation-note.md` — full executable contract: same structure, includes closed relation-type vocabulary, WikiLink prohibition explicit.
- `docs/design/08` — "Alias and Link Policy" section added: alias rules, item link requirements for Source_Item/Target_Item, WikiLink scope limitation.

---

### Step 04 — Build queue and review model in DEVONthink

**Status:** [x]
**Blocked by:** Steps 02, 03
**Blocks:** Steps 07, 08, 12
**Design refs:** `docs/design/07` (review queues section), `docs/design/08` (queue signals)

Create the following smart groups in DEVONthink. Each must filter on the metadata field or condition shown:

| Smart group | Filter condition | Database scope |
|---|---|---|
| `Needs Profile` | `PKIM_ID` is empty OR `Review_State` is empty | All evidence databases |
| `Needs OCR` | `Needs_OCR` is set / OCR text missing where expected | Evidence databases |
| `Needs Knowledge Note` | `Knowledge_Link_State` is empty or not linked | Evidence databases |
| `Needs Relation Note` | `Relation_Gap_State` is flagged | PKIM-Knowledge |
| `Needs Filing` | `Review_State` = approved AND in Inbox or Working | All databases |
| `Indexed Risk` | `Indexed_Risk_State` is flagged | Evidence databases |
| `Mirror Drift` | `Mirror_State` = stale or `Mirror_Path` set but `LastMirroredAt` is old | PKIM-Knowledge |
| `Automation Error` | `Automation_Last_Run_State` = error | All databases |
| `Needs Human Review` | `Review_State` = needs-human | All databases |
| `Ready for Mirror` | `Review_State` = approved AND `KnowledgeStatus` = active | PKIM-Knowledge |

Confirm that each smart group filter actually works with the metadata fields created in Step 02. Adjust filter logic as needed and record actual filter expressions in the Notes section below.

**Repo deliverable:** document the final smart group definitions (filter expressions) in `docs/design/07` Notes or a new appendix. Update `build-plan.md` Step 04 to `[x]`.

**Acceptance criteria:**
- All smart groups exist and return meaningful results on test records.
- Every queue maps to exactly one metadata state or transition per the queue contract table in `docs/design/07`.
- Filter expressions are documented.

**Notes:**
Repo deliverables complete 2026-04-18:
- `docs/ops/smart-groups-setup.md` — step-by-step guide for all 10 smart groups with exact filter conditions per database scope.
- `scripts/verify-smart-groups.applescript` — verifies groups exist by name and reports their predicate strings for documentation.
Completed 2026-04-18:
- All 35 required local smart groups created across the five PKIM databases.
- Seed validation records created in the relevant databases so each queue returns hits when matching records exist.
- `osascript scripts/verify-smart-groups.applescript` → `Pass: 35   Fail: 0`.
- DEVONthink Pro 4.1.1 exposes the smart groups by name but does not return `search predicates` through AppleScript on this install; verify output reports `(predicates unreadable)`.
- Recorded below are the exact predicate strings used at creation time.

**Predicate strings**
- `Needs Profile`
  `mdpkim_id==""||mdreview_state==""`
  Scope: `PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Needs OCR`
  `mdneeds_ocr==1`
  Scope: `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Needs Knowledge Note`
  `mdknowledge_link_state==""`
  Scope: `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Needs Relation Note`
  `mdrelation_gap_state!=""`
  Scope: `PKIM-Knowledge`
- `Needs Filing`
  `mdreview_state=="approved"`
  Scope: `PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Indexed Risk`
  `mdindexed_risk_state!=""`
  Scope: `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Mirror Drift`
  `mdmirror_state=="stale"`
  Scope: `PKIM-Knowledge`
- `Automation Error`
  `mdautomation_last_run_state=="error"`
  Scope: `PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Needs Human Review`
  `mdreview_state=="needs-human"`
  Scope: `PKIM-Knowledge`, `PKIM-Evidence-Personal`, `PKIM-Evidence-Work`, `PKIM-Evidence-Server`, `PKIM-Pilot`
- `Ready for Mirror`
  `mdreview_state=="approved"&&mdknowledgestatus=="active"`
  Scope: `PKIM-Knowledge`

---

### Step 05 — Build export mirror

**Status:** [x]
**Blocked by:** Steps 03, 04
**Blocks:** Steps 06, 08, 09, 16
**Design refs:** `docs/design/08` (mirror spec), `docs/design/09`, `docs/design/14` WP-09
**Schemas:** `schemas/export-manifest.schema.json`

Implement `scripts/pkim sync-mirror` beyond the current stub.

Requirements:
- Read canonical notes from `PKIM-Knowledge` via the shared local DEVONthink helper surface.
- Write portable markdown to `PKIM_EXPORT_ROOT` using the naming convention: `knowledge/KN-YYYYMMDD-NNNN-slugified-title.md`, `relations/RL-YYYYMMDD-NNNN-slugified-title.md`.
- Inject frontmatter per the implemented mirror spec in `docs/design/08`: `pkim_id`, `dt_uuid`, `dt_item_link`, `doc_role`, `note_type`, `review_state`, `mirrored_at`, `mirror_path`; relation notes additionally include `source_item`, `target_item`, and `relation_type` when present.
- Emit an export manifest at `runs/<run-id>/export-manifest.json` conforming to `schemas/export-manifest.schema.json`.
- Detect drift: flag notes where `Mirror_State` is stale.
- Write nothing outside `PKIM_EXPORT_ROOT`.
- Update `Mirror_Path` and `LastMirroredAt` on the source record after a successful export.

Add a helper script `scripts/pkim-sync-mirror` (thin shell or Python wrapper) as the entry point used by the main `pkim sync-mirror` command.

Write at least two tests in `tests/` covering:
- mirror file naming convention
- frontmatter completeness for a synthetic note fixture

**Repo deliverable:** implemented `sync-mirror` subcommand, tests passing, `exports/knowledge-mirror/README.md` updated to reflect the actual output shape. Update `build-plan.md` Step 05 to `[x]`.

**Acceptance criteria:**
- Running `scripts/pkim sync-mirror --scope changed --format json` on a note with `Review_State=approved` produces a valid mirrored file and a manifest.
- Mirror filename matches the naming convention.
- Frontmatter parses cleanly.
- Export does not write outside `PKIM_EXPORT_ROOT`.
- Tests pass.

**Notes:**
Completed 2026-04-18:
- `scripts/pkim sync-mirror` implemented: JXA query via osascript, file export with YAML frontmatter, export manifest to `runs/<run-id>/export-manifest.json`.
- Naming convention: `knowledge/KN-YYYYMMDD-NNNN-<slug>.md`, `relations/RL-YYYYMMDD-NNNN-<slug>.md`. RL prefix routes to `relations/`, all others to `knowledge/`.
- Frontmatter fields: `pkim_id`, `dt_uuid`, `dt_item_link`, `doc_role`, `note_type`, `review_state`, `mirrored_at`, `mirror_path`; plus `source_item`, `target_item`, `relation_type` when set.
- `--scope changed` (default) skips records where `Mirror_State == "current"`.
- `--live` writes `Mirror_Path`, `LastMirroredAt`, `Mirror_State=current` back to DEVONthink via `getRecordWithUuid` — blocked unless `PKIM_ALLOW_PRODUCTION_WRITES=true`.
- JXA approach: osascript -l JavaScript subprocess; queries `/Notes/<group>` children across Literature, Synthesis, Relations, Topics, Projects.
- MCP not used for mirror; JXA/AppleScript path chosen for stability and direct customMetaData access.
- `exports/knowledge-mirror/README.md` updated with output shape and usage.
- `tests/test_pkim_sync_mirror.py` — 23 tests: naming convention, frontmatter completeness, write gate, writeback, JXA error handling. All 25 tests (including smoke) pass.

---

### Step 06 — Build capability probe

**Status:** [x]
**Blocked by:** Step 02
**Blocks:** Steps 07, 09, 10, 11, 13, 14, 15
**Design refs:** `docs/design/09` (capability probe), `docs/design/14` WP-04, `docs/ops/capability-probe.md`
**Schemas:** `schemas/capability-manifest.schema.json`

Implement `scripts/pkim probe-capabilities` beyond the current stub.

Checks to perform:
1. DEVONthink is running and reachable (via JXA or AppleScript).
2. Target databases are open: `PKIM-Pilot`, `PKIM-Knowledge`, at least one evidence database.
3. Required local command/helper surface is present and resolvable; MCP availability may be reported separately but is not the required primary path.
4. Canonical custom metadata fields exist on the target databases.
5. `PKIM-Pilot` exists and is distinct from production databases.
6. `PKIM_ALLOW_PRODUCTION_WRITES` gate state is explicitly reported.

Output a capability manifest at `runs/<run-id>/capability-manifest.json` conforming to `schemas/capability-manifest.schema.json`. Include a `passed` boolean and a list of failing checks.

The capability probe must be the required preflight for every agent run involving writes. Record this as a rule in `docs/ops/capability-probe.md`.

Add a test in `tests/` that runs the probe against a mock environment and verifies the manifest shape.

**Repo deliverable:** implemented `probe-capabilities`, updated `docs/ops/capability-probe.md` with real check list and exit conditions. Update `build-plan.md` Step 06 to `[x]`.

**Acceptance criteria:**
- `scripts/pkim probe-capabilities --format json` returns a valid manifest with `passed` and per-check results.
- Any failing check causes `passed: false`.
- The manifest conforms to the schema.
- Test passes.

**Notes:**
Completed 2026-04-18:
- `scripts/pkim probe-capabilities` implemented: 8 named checks, structured `checks` list, `passed` boolean, `failed_checks` list, `write_gate` reported.
- JXA probe queries open databases and runs `dt.search()` with each `md<field>` predicate to confirm field definitions exist in DEVONthink.
- Fields tested: `PKIM_ID`, `Review_State`, `DocRole`, `NoteType`, `Mirror_State`, `Automation_Last_Run_State`, `Knowledge_Link_State` (7 fields).
- MCP binary missing is a warning and is reported in `warnings`, but does not block JXA-based operations; JXA is the primary runtime.
- Output written to `runs/<run-id>/capability-manifest.json`.
- `docs/ops/capability-probe.md` rewritten with full check table, exit conditions, and required-preflight rule.
- `tests/test_pkim_probe.py` — 12 tests: all-pass, per-check failure cases, write gate, warnings, manifest location. All 37 tests pass.

---

### Step 07 — Build read-only agent skills

**Status:** [x]
**Blocked by:** Steps 02, 03, 06
**Blocks:** Step 08
**Design refs:** `docs/design/11` (skills 1–2), `docs/design/14` WP-05
**Prompts:** `prompts/profile-record.md`
**Schemas:** `schemas/profile-packet.schema.json`

Implement the read-only profile skill together with its supporting read-only command surface.

The profile skill must:
- Accept a record reference (item link, `PKIM_ID`, or UUID).
- Read record content, properties, and existing metadata.
- Run DEVONthink compare and classify for discovery (treat output as suggestions, never truth).
- Propose tags, filing destination, related documents.
- Draft a knowledge note outline (title, note type, summary seed, evidence link).
- Draft relation note candidates if strong neighbours are found.
- Use the command surface as data input, not as the interpretation layer.
- Write nothing to DEVONthink.

Implement `scripts/pkim profile` as the pure read-only command surface for that skill:
- Accept a record reference (item link, `PKIM_ID`, or UUID).
- Read record content, properties, existing metadata, and native `kind`.
- Run DEVONthink compare and classify for discovery.
- Emit a deterministic record-context packet at `runs/<run-id>/profile.json` conforming to `schemas/profile-packet.schema.json`.
- Write nothing to DEVONthink.

Also implement `scripts/pkim-devonthink-helper` as the thin local helper that wraps AppleScript/JXA calls needed by the profile flow (properties read, compare, classify). Add the helper to the `pkim devonthink-helper` subcommand.

Update `prompts/profile-record.md` to be a complete, executable prompt contract (not a stub): inputs, expected outputs, constraints, example invocation.

Write tests for:
- profile output shape against a synthetic fixture
- helper script invocable without a live DEVONthink (mock mode or minimal smoke test)

**Repo deliverable:** implemented `profile` subcommand and DEVONthink helper, `prompts/profile-record.md` complete, tests passing. Update `build-plan.md` Step 07 to `[x]`.

**Acceptance criteria:**
- `scripts/pkim profile --record <ref> --format json` returns a read-only record-context packet without writing to DEVONthink.
- Output includes record metadata, content, classify suggestions, compare results, and deterministic risk level.
- Any interpreted candidate output remains read-only scaffolding, not a write path.
- No write path is reachable from the profile command.
- Tests pass.

**Notes:**
Completed 2026-04-19:
- `scripts/pkim profile --record <ref>` remains read-only: resolves by item link, PKIM_ID, or UUID via JXA, runs classify and compare for discovery, emits `runs/<run-id>/profile.json`, and now also writes `run.json` so reporting can count profile runs.
- Output carries deterministic record context plus a deterministic candidate set: `record`, extracted/native `content`, raw `classified_groups`, raw `compared_records`, discovery errors, `risk_level`, `candidate_notes`, `candidate_edges`, and `candidate_resolution_map`.
- Compatibility fields `knowledge_note_draft` and `relation_candidates` may also appear when there is exactly one clear canonical candidate. These are derived read-only scaffolding fields, not mutation instructions.
- Profile command has no write path. Classify and compare are discovery signals, not authority.
- `scripts/pkim devonthink-helper --operation read-record|classify|compare --ref <ref>` exposes raw JXA helper ops directly.
- JXA approach: osascript -l JavaScript; classify via `dt.classify(rec)`, compare via `dt.compare(rec)` with top-10 limit.
- `prompts/profile-record.md` now documents the candidate-set output explicitly.
- Project skill contracts added under `skills/`; skill/command boundary clarified in `docs/design/11-agent-skills-and-runbooks.md`.
- `tests/test_pkim_profile.py` updated to verify both read-only behavior and candidate-set output.

---

### Step 08 — Test on 50–120 document pilot corpus

**Status:** [x]
**Blocked by:** Steps 02, 03, 04, 05, 06, 07
**Blocks:** Step 09
**Design refs:** `docs/design/07` (ingest workflow), `docs/design/14` WP-02, README Phase 0 exit criteria

Ingest a representative pilot set into `PKIM-Pilot` and run the full read-only workflow against it.

Pilot corpus requirements:
- 50–120 records total.
- Include at least: 10 PDFs, 10 web captures (web bookmarks, web archives, or Markdown web clips), 5 Markdown notes, a small indexed parent folder (5–10 files).
- Mix of evidence already profiled and evidence in inbox state.

Run the following against the pilot set and review outputs:
1. `pkim health-check` — confirm runtime is clean.
2. `pkim probe-capabilities` — confirm preflight passes.
3. `pkim profile` on at least 10 records — review ProfilePackets for quality.
4. `pkim sync-mirror` on any manually created knowledge notes — review mirrored output.
5. Review smart queue outputs in DEVONthink — confirm queues populate correctly.

Evaluate:
- Schema stability: are any metadata fields missing or unexpectedly named?
- Note conventions: do the templates produce consistent, useful notes?
- Relation note usefulness: does the profile skill produce sensible relation candidates from the command surface?
- Compare/classify quality: are suggestions reasonable enough to support interpretation, not replace it?
- Queue design: does each queue surface the right records?
- Mirror outputs: are they clean and parseable?

Record all findings in a pilot report at `runs/pilot-corpus-review/summary.md` (untracked).

**Repo deliverable:** update any design docs that need correction based on pilot findings. Log schema changes in `docs/design/00-source-reconciliation.md`. Update `build-plan.md` Step 08 to `[x]`.

**Acceptance criteria — Phase 0 exit criteria (from README):**
- `PKIM-Pilot` exists locally and not in a cloud-synced path.
- 50–120 pilot records ingested across representative source types.
- Canonical metadata fields applied consistently enough to review.
- At least 15 native knowledge notes exist using the canonical metadata form.
- At least 5 relation notes exist and resolve correctly.
- One indexed parent-root pattern tested, including manual refresh checks.
- Mirror can be exported and read outside DEVONthink.
- Read-only runtime health and profiling flows work.
- Backup and restore paths exercised, not merely configured.

**Notes:**
2026-04-19 pilot review completed and recorded in `runs/pilot-corpus-review/summary.md`.

Closed state:
- `PKIM-Pilot/Inbox` contains `116` records: `70` PDFs, `23` Markdown, `10` RTF, `7` unknown, `2` pictures, `1` multimedia, `1` txt, `2` bookmarks.
- Markdown web clips are accepted as valid web captures for this step.
- `PKIM-Pilot/Sources/Indexed` contains three indexed group roots: `consulting-workflows`, `docs`, `docs`.
- Pilot now contains a mix of profiled and inbox-state evidence: `100` unprofiled remain after profiling and linking a real tranche.
- Created downstream note layer in `PKIM-Knowledge`: `15` literature notes and `5` relation notes.
- `pkim sync-mirror --scope all` now exports `20` records.
- Backup/restore path was exercised with package-copy backup and restore-test copies under `tmp/restore-drill/`.

Pilot finding:
- DEVONthink scripting returns internal custom-metadata keys such as `mdpkim_id` and `mdreview_state`, not just human-facing labels like `PKIM_ID` and `Review_State`.
- `src/pkim/commands/profile.py`, `src/pkim/commands/inbox.py`, and `src/pkim/commands/mirror.py` were updated to normalize those keys before interpreting metadata.
- The command-surface / skill split is now explicit: `profile` gathers read-only context, while the skill layer performs interpretation.

---

### Step 09 — Add metadata writeback

**Status:** [x]
**Blocked by:** Steps 06, 08
**Blocks:** Steps 10, 11
**Design refs:** `docs/design/09` (write safety), `docs/design/14` WP-08
**Schemas:** `schemas/mutation-result.schema.json`

Implement `scripts/pkim apply-metadata` beyond the current stub.

Write-safety requirements (non-negotiable):
1. Dry-run is the default; `--live` must be explicit.
2. Pre-write: read and record the before-state of every field being changed.
3. Apply change via the approved path (JXA/AppleScript helper).
4. Post-write: re-read the record and compare intended vs actual state.
5. If post-write state does not match intent, fail loud and write the discrepancy to the run manifest.
6. Emit `MutationResult` at `runs/<run-id>/mutation.json` conforming to `schemas/mutation-result.schema.json`.

Allowed metadata writes at this step (no others):
- Mint `PKIM_ID` (first-time only, never overwrite).
- Set `Review_State` transitions within the allowed state machine.
- Set `DocRole` where missing.
- Set `LastProfiledAt` timestamp.
- Set `Automation_Last_Run_State`.

All other fields require an explicit design decision before being added to the allowed write list.

Validate the full write path against `PKIM-Pilot` before enabling against production databases.

Update `prompts/apply-approved-metadata.md` to be a complete executable prompt contract.

Write tests covering:
- Dry-run returns `MutationIntent` without touching DEVONthink.
- Live run on a mock/scratch fixture emits a `MutationResult` with before/after state.
- Overwrite of an existing `PKIM_ID` is rejected.

**Repo deliverable:** implemented `apply-metadata` subcommand, scratch-validated, tests passing, prompt complete. Update `build-plan.md` Step 09 to `[x]`.

**Acceptance criteria:**
- Dry-run never writes to DEVONthink.
- Live run emits a `MutationResult` with before, intended, and after state.
- Post-write mismatch causes a loud failure, not silent success.
- `PKIM_ID` overwrite is rejected.
- Tests pass.

**Notes:**
Completed 2026-04-19:
- `src/pkim/commands/apply_metadata.py` — full implementation: PKIM_ID minting, Review_State state machine, DocRole guard, `LastProfiledAt`, Automation_Last_Run_State passthrough, dry-run default, write gate enforcement, post-write verification.
- PKIM_ID minting: `EV/KN/RL-YYYYMMDD-NNNN`; sequence determined by scanning all open databases via JXA, then incrementing. Overwrite of an existing PKIM_ID is hard-rejected.
- Write path: JXA read-merge-write on `customMetaData`; post-write re-read compares intended vs actual (checks both canonical and `md*` internal keys).
- Mismatch causes `result: error` with `mismatch` list — loud failure, not silent success.
- `"mint"` and `"auto"` are accepted as PKIM_ID values and resolved to a real ID before validation.
- `apply-metadata` wired in `pkim` CLI; placeholder removed.
- `tests/test_pkim_apply_metadata.py` — 39 tests covering: state machine transitions, field validation, dry-run no-write assertion, live run, mismatch detection, mint resolution, write gate.
- Live-validated on PKIM-Pilot: `EV-20260419-0016` minted and written to a real inbox record; post-write verification passed; `list-inbox` confirmed unprofiled count dropped from 100 to 99.

---

### Step 10 — Add relation-note creation automation

**Status:** [x]
**Blocked by:** Steps 03, 09
**Blocks:** Step 11
**Design refs:** `docs/design/08` (relation-note spec), `docs/design/14` WP-07
**Schemas:** `schemas/mutation-result.schema.json`

Implement `scripts/pkim create-relation-note` beyond the current stub.

Requirements:
- Accept `--source`, `--target` (both as `PKIM_ID`, item link, or UUID), `--relation <type>`, and `--rationale <text>`.
- Resolve both source and target references before writing anything.
- Validate that the relation type is in the approved vocabulary (from the frozen design contract, Step 01).
- Create the relation note in `PKIM-Knowledge/Notes/Relations/` using the canonical relation note template (Step 03).
- Mint a `PKIM_ID` for the new relation note.
- Set `Source_Item` and `Target_Item` as native item links.
- Set `RelationStatus=proposed` unless `--reviewed` is passed.
- Dry-run must produce a valid draft note body without writing.
- Live run must emit a `MutationResult`.

Also implement `scripts/pkim create-knowledge-note` using the same pattern — create from a source evidence record, populate the template, link back to evidence via item link, mint `PKIM_ID`, set `DocRole=knowledge`.

Update `prompts/create-knowledge-note.md` and `prompts/create-relation-note.md` to be complete executable contracts.

Write tests covering:
- Dry-run produces a valid note body matching the template.
- Missing rationale (relation note) is rejected before write.
- Unresolvable source or target is rejected before write.

**Repo deliverable:** both subcommands implemented, scratch-validated, tests passing, prompts complete. Update `build-plan.md` Step 10 to `[x]`.

**Acceptance criteria:**
- Both subcommands work dry-run and live.
- Relation note has `PKIM_ID`, `Source_Item`, `Target_Item`, `Relation_Type`, and rationale.
- Knowledge note has `PKIM_ID`, `DocRole`, `NoteType`, and at least one evidence link.
- Tests pass.

**Notes:**
Completed 2026-04-19:
- `src/pkim/commands/create_note.py` — `command_create_knowledge_note` and `command_create_relation_note`, shared `_jxa_create_record` (JSON-params pattern to safely embed markdown in JXA), body builders for both note types, post-write verification against both canonical and `md*` keys.
- `RELATION_TYPES` frozen set (8 types); `NOTE_TYPE_GROUPS` maps note type to DEVONthink group path.
- Knowledge notes: route by `--note-type` → `/Notes/Literature|Synthesis|Topics|Projects`; metadata: `PKIM_ID` (KN-), `DocRole=knowledge`, `NoteType`, `Review_State=profiled`, `CreatedByMode=automation`.
- Relation notes: require both `--source` and `--target` resolved before write; `RelationStatus=proposed` (or `reviewed` with `--reviewed`); metadata includes `Source_Item` and `Target_Item` as item links.
- Both commands: dry-run default, write gate (`PKIM_ALLOW_PRODUCTION_WRITES=true`) for `--live`, mismatch on post-write → `result: error`.
- Both subcommands wired in `pkim` CLI with explicit choices for `--note-type` and `--relation`.
- `tests/test_pkim_create_note.py` — 36 tests: body builder assertions, dry-run/live for both commands, invalid inputs, mismatch detection, note-type routing, relation-type coverage, `reviewed` flag.
- `--summary` and `--key-points` added: agent synthesises both before calling CLI; body template renders summary paragraph and keyed bullet points, omits empty sections.
- DEVONthink 4 JXA `createRecord` bug: passing `type:markdown` enum via JXA causes -1708. Fixed by split: AppleScript creates the empty record (handles enum correctly), JXA sets `plainText` and `customMetaData` on the returned UUID.
- `run_applescript()` added to `pkim/jxa.py` for AppleScript-only operations.
- Prompt contracts rewritten as synthesis-first workflows (not plumbing specs): agent reads source, synthesises claim, extracts key points, then calls CLI.
- Live-validated on PKIM-Pilot: `KN-20260419-0017` created in PKIM-Knowledge/Notes/Literature; post-write verification passed.

---

### Step 11 — Add manual filing support

**Status:** [x]
**Blocked by:** Steps 06, 09, 10
**Blocks:** Step 12
**Design refs:** `docs/design/07` (filing policy), `docs/design/14` WP-10 (proposal stage)
**Prompts:** `prompts/evaluate-safe-filing.md`

Implement a filing proposal flow as the dry-run half of `scripts/pkim safe-file`.

At this step, the command must:
- Accept `--record`, `--destination`, `--action replicate|move`.
- Run policy evaluation: imported vs indexed, destination validity, review state check.
- Produce a filing proposal with: proposed destination, action, rationale, risk level, and any blocking conditions.
- Default to `--dry-run`; reject `--live` at this step (live mode comes in Step 13).
- For indexed records, always flag risk regardless of other conditions.
- Emit proposal as part of the run manifest.

Update `prompts/evaluate-safe-filing.md` to be a complete executable prompt contract including the policy evaluation steps, risk flags, and output shape.

This step intentionally stops before automating any actual moves. The value here is proving the policy engine works and surfaces correct risk flags before any record is touched.

Write tests covering:
- Indexed record triggers a risk flag.
- Record not in `Review_State=approved` is blocked.
- Destination outside allowed groups is rejected.

**Repo deliverable:** dry-run `safe-file` subcommand implemented, policy engine tested, prompt complete. Update `build-plan.md` Step 11 to `[x]`.

**Acceptance criteria:**
- Dry-run returns a filing proposal with risk classification for any record.
- Indexed record always gets a risk flag.
- Unapproved record is blocked from filing.
- No live writes are possible at this step.
- Tests pass.

**Notes:**
Completed 2026-04-19:
- `src/pkim/commands/safe_file.py` — full policy engine: resolves record via `_jxa_inspect_record` (adds `isIndexed` and `database` to the standard fields), validates destination group existence via `_jxa_validate_destination`, evaluates policy rules, emits filing proposal with `risk_level`, `risk_flags`, `blocking`, and `rationale`.
- Blocking conditions: `Review_State` in `{inbox, needs-human, rejected, unset}`, `action=move` on indexed record, destination not found or not a group, `--live` flag (rejected at this step).
- Risk flags (non-blocking): indexed+replicate (path fragility), move+imported (irreversible), profiled-not-approved.
- Risk levels: low (approved+imported+replicate), medium (move or profiled), high (blocked or indexed+move).
- `--live` explicitly rejected — live filing is Step 13.
- Manifest written to `runs/<run-id>/filing-proposal.json`.
- `prompts/evaluate-safe-filing.md` rewritten as a full synthesis-first prompt contract.
- `tests/test_pkim_safe_file.py` — 19 tests covering all policy branches.
- Live-validated: blocked correctly for unset-state inbox record; proposal issued correctly for approved imported record with move.

---

### Step 12 — Add import and inbox choreography

**Status:** [x]
**Blocked by:** Steps 04, 09, 11
**Blocks:** Step 13
**Design refs:** `docs/design/07` (ingest workflow, entry channels, ingest states), `docs/design/14` WP-07 area

Build the intake loop that turns arriving records into profiled, queue-assigned items.

Requirements:
- Define trigger points: manual import, smart-rule-based auto-assign on ingest, or operator-run sweep.
- On new inbox record: run `pkim profile` → review output → apply `PKIM_ID` and `Review_State=profiled` via `pkim apply-metadata`.
- For records that fail profiling: set `Review_State=needs-human` and surface in `Needs Human Review` queue.
- Confirm the `Needs Profile` smart group clears correctly after profiling.
- Document the intake loop as a runbook in `docs/design/11` or `docs/ops/`.

Source-type-aware handling per `docs/design/07`:
- Web page: bookmark only, unless snapshot required.
- PDF: import, OCR check.
- Scan: import plus OCR trigger.
- Canonical markdown note: import to `PKIM-Knowledge` only.
- Spreadsheet/active office file: usually indexed if cross-app editing matters.
- Email or clipper capture: inbox, then review.

**Repo deliverable:** intake runbook documented, intake loop tested against `PKIM-Pilot` corpus, `Needs Profile` queue verified to clear. Update `build-plan.md` Step 12 to `[x]`.

**Acceptance criteria:**
- Arriving inbox records are profiled and assigned `PKIM_ID` + `Review_State` via the intake loop.
- Records that fail get `needs-human` and surface in the right queue.
- `Needs Profile` queue empties after a successful sweep.
- Kind-based intake policy is applied consistently.

**Notes:**
Completed 2026-04-19:
- `src/pkim/commands/sweep_inbox.py` — `command_sweep_inbox`: queries all records in a database with missing PKIM_ID or Review_State, classifies from DEVONthink `kind` (with filename extension as fallback), emits batch triage report. `--scope inbox` limits to /Inbox/; `--scope all` searches the full database.
- Intake classification: pdf, web, markdown, office, scan, email, unknown. OCR flag fires on pdf/scan records with word count < 50 and not indexed.
- `recommended_action` per record: `profile` (ready), `ocr-first` (trigger OCR first), `needs-human` (unrecognised type or unresolvable).
- Live mode (`--live`): sets `Review_State=needs-human` only on records classified `needs-human`. Write-gated by `PKIM_ALLOW_PRODUCTION_WRITES=true`. Does not auto-mint PKIM_IDs — that step requires agent profiling per record.
- `pkim sweep-inbox` wired into the CLI.
- `docs/ops/intake-runbook.md` — full six-step intake runbook: sweep → OCR candidates → flag needs-human → profile → apply metadata → verify queue clears.
- `prompts/sweep-inbox.md` — synthesis-first prompt contract for the full intake loop.
- `tests/test_pkim_sweep_inbox.py` — 25 tests: classification unit tests, command integration, OCR flag, indexed record exception, scope routing, live mode, write gate.
- Trigger mechanism: operator-triggered manual sweep (no fully automatic rule at this phase). DEVONthink smart rules remain available as a future upgrade point.
- Kind edge cases: DEVONthink `type` can be too coarse (`unknown`) even when `kind` is specific (`PowerPoint Presentation (.pptx)`, `Electronic Publication (EPUB)`). Intake classification now prefers `kind`. Indexed PDFs with low word count are classified as `profile` not `ocr-first` (OCR must happen at filesystem level for indexed files).
- Live-validated on PKIM-Pilot: 99 records need profiling; 89 profile, 8 needs-human, 2 ocr-first. Text output and verbose flag confirmed working.

---

### Step 13 — Add controlled move and replicate automation

**Status:** [x]
**Blocked by:** Steps 11, 12
**Blocks:** Step 14
**Design refs:** `docs/design/07` (replicate vs move policy), `docs/design/14` WP-10

Enable live mode for `scripts/pkim safe-file` for imported records only.

Requirements:
- `--live` flag enabled only when `PKIM_ALLOW_PRODUCTION_WRITES=true` and capability probe passes.
- Replicate is the default for any record not meeting all move conditions.
- Move conditions: record is imported (not indexed), `Review_State=approved`, destination is stable and in the allowlist.
- Indexed records: live move is hard-blocked at this step regardless of flags.
- Before/after refresh: read state before, apply action, re-read state, compare.
- Emit `MutationResult` with before, intended, and after state.
- Log to `runs/<run-id>/mutation.json`.

Test against `PKIM-Pilot` for at least: replicate of an imported record, move of an imported approved record, attempted move of an indexed record (must be hard-blocked).

**Repo deliverable:** live `safe-file` for imported records, scratch-validated, tests passing. Update `build-plan.md` Step 13 to `[x]`.

**Acceptance criteria:**
- Replicate works and is logged.
- Move works for imported approved records.
- Indexed records cannot be moved; hard block is enforced.
- All live runs produce `MutationResult` with before/after.
- Tests pass.

**Notes:**
Completed 2026-04-20:
- `src/pkim/commands/safe_file.py` now supports `--live` for imported records only. Live filing is gated by `PKIM_ALLOW_PRODUCTION_WRITES=true` and a passing capability probe before any DEVONthink mutation runs.
- Dry-run remains the default and still writes `runs/<run-id>/filing-proposal.json`. Live runs write `runs/<run-id>/mutation.json` with `before`, `intended`, and `after` state.
- Missing destination subpaths are now handled by a separate `pkim ensure-group-path` command rather than by implicit behaviour inside `safe-file`.
- Actual mutation path uses JXA via `theApp.move({record, to})` and `theApp.replicate({record, to})`, followed by post-write refresh verification against the destination group membership.
- `safe-file` supports an optional `--rename-to` phase for imported records only; indexed records remain blocked from rename automation.
- `safe-file` also supports optional alignment metadata for imported records during filing: `--aliases`, `--tags`, and `--abstract` (stored in the DEVONthink comment field), all verified in the refreshed after-state.
- Indexed records must not have filename or path semantics changed by filing automation.
- Stable destination allowlist enforced: `/Sources/Imported`, `/Sources/Indexed`, `/Archive`.
- Live filing blocks all indexed records at this step. Indexed handling stays deferred to Step 14.
- `src/pkim/cli.py` exposes `pkim safe-file --live`; action now defaults to `replicate`.
- `prompts/evaluate-safe-filing.md` updated for the live workflow and gating rules.
- Tests updated:
  - `tests/test_pkim_safe_file.py` covers live replicate, live move, write-gate failure, capability-probe failure, indexed blocks, mismatch handling, and artifact writes.
  - `tests/test_pkim_probe.py` now treats missing MCP binary as a warning rather than a blocking failure, matching the documented JXA-first runtime.
- Verification:
  - `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 uv run pytest tests/test_pkim_safe_file.py tests/test_pkim_probe.py -q`
  - `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 uv run pytest tests/test_pkim_smoke.py -q`

---

### Step 14 — Add indexed-folder automation

**Status:** [x]
**Blocked by:** Step 13
**Blocks:** Step 15
**Design refs:** `docs/design/07` (indexed rules), `docs/design/14` WP-10 (indexed section)

Extend the filing controller to handle indexed content with elevated safety gates.

Requirements:
- Index only parent folders, never individual files (enforce this at the helper level).
- Path policy check: confirm the indexed root still exists and is reachable before any action.
- `Update Indexed Items` check: surface a warning if the indexed root has not been refreshed recently.
- Cloud-sync caveat: detect if the indexed root path contains a known sync-service directory component (iCloud Drive, Dropbox, OneDrive) and log a warning.
- For indexed records, `replicate` is always preferred where DEVONthink-level replication is safe; autonomous `move` is never allowed.
- `Indexed Risk` smart group: verify it surfaces records correctly after path policy checks.

Document indexed-folder handling as a specific section in the filing runbook.

**Repo deliverable:** indexed-folder handling implemented and tested, runbook updated. Update `build-plan.md` Step 14 to `[x]`.

**Acceptance criteria:**
- Individual indexed files cannot be auto-moved.
- Cloud-sync paths trigger a warning.
- Indexed moves remain hard-blocked with no override flag.
- `Indexed Risk` queue surfaces the right records.
- Tests pass.

**Notes:**
Completed 2026-04-20:
- `src/pkim/commands/safe_file.py` now evaluates indexed path policy before replicate or move decisions.
- Indexed `move` remains hard-blocked. Indexed `rename` and metadata alignment during filing also remain blocked; use the metadata path instead.
- Indexed `replicate` is now allowed in live mode only when:
  - `Review_State=approved`
  - the filesystem path exists
  - capability probe and write gate both pass
- `Origin_Last_Path` and `Indexed_Risk_State` are written during the live indexed path so the `Indexed Risk` queue can surface path and refresh-assumption issues.
- `Origin_Last_Path` mismatch is treated as a warning and bookkeeping signal, not as a source-of-truth path.
- Runbook updated:
  - `prompts/evaluate-safe-filing.md`
  - `skills/dt-safe-file/SKILL.md`
- Tests updated:
  - `tests/test_pkim_safe_file.py` now covers indexed live replicate success, missing-path block, `Origin_Last_Path` mismatch warning, and the continued indexed move hard-block.
- Verification:
  - `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 uv run pytest tests/test_pkim_safe_file.py -q`

---

### Step 15 — Consolidate shared write routing

**Status:** [x]
**Blocked by:** Steps 06, 09, 13, 14
**Blocks:** Step 16
**Design refs:** `docs/design/10` (MCP extension spec), `docs/design/09`

Consolidate the shared write-routing surface once the native workflow is proven.

At this step:
- Review all write paths built in Steps 09, 10, 13, 14 and confirm which are implemented via AppleScript/JXA and whether any need a second transport.
- Keep the shared command surface authoritative even if alternate backends are explored.
- Update `scripts/pkim-devonthink-helper` and related helpers only if routing consolidation actually improves reliability.
- Document the routing decision in `docs/design/10`.
- Update `schemas/capability-manifest.schema.json` only if the required command surface changes.
- Run the full capability probe with the updated expected command set.

This step does not add new write operations. It is a reliability and surface audit for what has already been built.

**Repo deliverable:** routing decisions documented in `docs/design/10`, capability manifest updated if needed, helper routing tested. Update `build-plan.md` Step 15 to `[x]`.

**Acceptance criteria:**
- Each write path has a documented routing decision with rationale.
- Capability probe correctly gates on the required shared command surface.
- No write path is silently broken after the routing update.
- Tests pass.

**Notes:**
Completed 2026-04-20:
- `pkim probe-capabilities` now records the authoritative command surface in `tools` and the approved write routes in `write_routes`.
- Current routing decision is explicit and unchanged by this step:
  - `apply-metadata` → JXA
  - `create-knowledge-note` → AppleScript create + JXA enrich
  - `create-relation-note` → AppleScript create + JXA enrich
  - `ensure-group-path` → AppleScript create location + JXA validate
  - `safe-file` → JXA
  - `sync-mirror` → JXA
- `docs/design/10-mcp-extension-specification.md` now documents the authoritative write route for each live mutation path and narrows MCP to an optional future extension transport.
- No second transport was introduced for existing write paths.
- Tests updated:
  - `tests/test_pkim_probe.py` now verifies the manifest includes `tools` and `write_routes`.
- Verification:
  - `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 uv run pytest tests/test_pkim_probe.py tests/test_pkim_safe_file.py tests/test_pkim_profile.py tests/test_pkim_smoke.py -q`

---

### Step 16 — Add reporting and dashboards

**Status:** [x]
**Blocked by:** Steps 05, 08, 09, 10, 11, 15
**Blocks:** Step 17
**Design refs:** `docs/design/09` (observability), `docs/design/14` WP-11

Build the operational reporting layer once real workflows exist to report on.

Deliverables:
- Metadata overview dashboard notes in DEVONthink: one per standard reporting slice, showing canonical field coverage.
- Queue metrics: a script or native command that counts records in each named smart group and emits a simple JSON summary.
- Mirror health check: add a `pkim sync-mirror --check` mode that reports drift count without exporting.
- Run log summary: a lightweight reader that aggregates `run.json` files from `runs/` and reports totals by command, result, and dry-run vs live.
- Failure-rate tracking: surface `Automation_Last_Run_State=error` count.

These reports should be readable by both Claude Code and Codex CLI via the shared command surface.

**Repo deliverable:** queue metrics command, mirror health check mode, run log summary, metadata overview dashboard notes in DEVONthink. Update `build-plan.md` Step 16 to `[x]`.

**Acceptance criteria:**
- Queue metrics command returns counts for all named smart groups.
- Mirror health check returns a drift count without exporting files.
- Run log summary reads from `runs/` and returns totals.
- Failure count is visible from the command surface.

**Notes:**
Completed 2026-04-24:
- Shared run-manifest emission widened so reporting commands can aggregate `run.json` across meaningful actions instead of scraping command-specific artifacts. `profile` and `devonthink-helper` now emit proper run manifests rather than being invisible or collapsing to `unknown`.
- Added `pkim queue-metrics` to count all named PKIM smart groups and surface `Automation Error` totals directly.
- Added `pkim sync-mirror --check` to report mirror drift count without exporting files.
- Added `pkim run-summary` to aggregate `runs/*/run.json` by command, result, and dry-run vs live.
- Added `pkim metadata-overview` to compute canonical metadata coverage, emit `metadata-overview.json`, and in live mode write/update dashboard notes under `PKIM-Knowledge/Operations/Reports/`.
- Added `pkim metadata-overview --standard-set` to run the fixed reporting batch:
  - `PKIM-Pilot` with `DocRole=evidence`
  - `PKIM-Evidence-Personal` unfiltered
  - `PKIM-Knowledge` with `DocRole=knowledge`
  - `PKIM-Knowledge` with `DocRole=relation`
- Live-validated dashboard notes on the target DEVONthink install:
  - `Metadata Overview - PKIM-Pilot - evidence`
  - `Metadata Overview - PKIM-Evidence-Personal`
  - `Metadata Overview - PKIM-Knowledge - knowledge`
  - `Metadata Overview - PKIM-Knowledge - relation`
- Reporting stack run validated end to end:
  - `probe-capabilities` run `RUN-2026-04-24T14-00-23-971281Z`
  - `queue-metrics` run `RUN-2026-04-24T14-00-26-786591Z`
  - `sync-mirror --check` run `RUN-2026-04-24T14-00-32-079905Z`
  - `metadata-overview --standard-set --live` run `RUN-2026-04-24T14-00-35-206178Z`
  - `run-summary` run `RUN-2026-04-24T14-00-45-487279Z`
- Tests added for the new command surface and run-manifest behavior.
- Fixed a real defect in `run_id()` by adding subsecond precision so concurrent commands stop colliding in the same `runs/RUN-*` directory and overwriting manifests.

---

### Step 17 — Scale beyond pilot

**Status:** [x]
**Blocked by:** Step 16 (and all Phase 0 exit criteria from Step 08)
**Design refs:** README Phase 0 exit criteria, `docs/design/13`

Do not start this step until all Phase 0 exit criteria from Step 08 are confirmed.

When scaling:
- Move from `PKIM-Pilot` to full evidence libraries only after the pilot workflow is stable.
- Do not ingest the full Gartner corpus or other large sets until metadata schema is stable, note conventions are stable, and write logs show low failure rates.
- Add `PKIM-Evidence-Server` only when indexed-folder automation (Step 14) is proven.
- Review the ontology (tags, relation types, review states, queue names) before scaling. Do not let it drift under bulk ingestion.
- Confirm backup and restore procedure before scaling.

This step is mostly operational discipline, not new code. Document any schema changes discovered during scale-up in `docs/design/00-source-reconciliation.md`.

**Repo deliverable:** updated `build-plan.md` with post-scale findings. `docs/design/00` updated if schema changes were made. Update `build-plan.md` Step 17 to `[x]`.

**Acceptance criteria:**
- All Phase 0 exit criteria confirmed before scale-up begins.
- Backup tested before first large ingest batch.
- No schema drift occurred during scale without explicit design doc update.

**Notes:**
Started 2026-04-25:
- Added `pkim scale-readiness` to turn the Step 17 entry criteria into one local command instead of an informal checklist.
- First readiness run: `RUN-2026-04-25T00-48-43-242687Z`
- Current blockers from that run:
  - backup/restore drill evidence path `tmp/restore-drill` is missing in the current worktree
  - `Automation Error` total is `5`, above the default scale threshold of `0`
  - mirror drift is `18`, above the default scale threshold of `0`
- Current non-blockers from that run:
  - Step 08 and Step 16 are both marked closed
  - capability probe passes
  - run manifests are complete
  - reporting surface has been exercised and is visible in `run-summary`
- Interpretation:
  - the system is now structurally ready to assess scale, but it is not yet operationally clean enough to scale
  - Step 17 should remain in progress until backup evidence is re-established and the current reporting backlog (`Automation Error`, mirror drift) is reduced to an explicitly accepted level

Completed 2026-04-25:
- Cleared stale `Automation Error` queue items and reduced the total to `0`.
- Ran live mirror sync and reduced mirror drift to `0`.
- Re-established backup evidence under `tmp/restore-drill/` using a package-copy backup of `PKIM-Pilot.dtBase2` and a restore-test copy at `tmp/restore-drill/restore-test/PKIM-Pilot-RestoreTest.dtBase2`.
- Restore drill evidence recorded at `tmp/restore-drill/evidence/restore-drill-summary.json`.
- Added `pkim restore-drill` so the backup/restore evidence path can be regenerated from the shared command surface instead of ad hoc shell steps. Contract: `docs/ops/restore-drill.md`.
- `pkim scale-readiness` now requires that restore-drill evidence is both valid and fresh; the default max age is `168` hours.
- Passing readiness run: `RUN-2026-04-25T02-50-04-458938Z`
- Result:
  - all Step 17 gate checks passed
  - no schema drift was introduced during the readiness cleanup

---

### Step 18 — Reconcile runtime truth across docs

**Status:** [x]

Completed 2026-04-26:
- Updated front-door status docs so the repo no longer claims placeholder command surfaces where real commands exist.
- Reconciled capability/status prose with the implemented command surface and current operational hardening work.

---

### Step 19 — Tighten operational readiness gates

**Status:** [x]

Completed 2026-04-26:
- `pkim queue-metrics` now reports queue aging, count deltas versus recent history, missing expected groups, and queue-surface trustworthiness.
- `pkim scale-readiness` now uses the same queue surface for mirror drift and queue completeness instead of a narrower side-path.

---

### Step 20 — Add graph audit and hygiene automation

**Status:** [x]

Completed 2026-04-26:
- Added `pkim graph-audit` to detect broken relation endpoints, incomplete relation metadata, duplicate relations, stale mirror state, orphaned approved knowledge notes, and error-state records.

---

### Step 21 — Add candidate provenance ledger

**Status:** [x]

Completed 2026-04-26:
- `pkim profile` now emits `candidate-ledger.json`.
- Added `pkim candidate-ledger` to rebuild a candidate-scoped provenance ledger from profile, resolution, and mutation artifacts.

---

### Step 22 — Add repeatable workflow validation harness

**Status:** [x]

Completed 2026-04-26:
- Added `pkim workflow-validate` to run a deterministic scratch validation pass across health, capability probe, queue metrics, metadata overview, graph audit, search, and optional record profiling.

---

### Step 23 — Finish skill packaging scaffolding

**Status:** [x]

Completed 2026-04-26:
- Added `agents/openai.yaml`, `evals/evals.json`, and `evals/trigger-evals.json` across the PKIM skill directories so the skill pack is consistently packageable and trigger-testable.
