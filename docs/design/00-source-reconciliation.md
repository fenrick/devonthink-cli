# Source Reconciliation

## Purpose

This document records how the design evolved between the two source briefs and which position is now canonical.

Use it when a current design rule appears to conflict with older source material, or when a future reversal needs an explicit dated rationale. Do not use it as the day-to-day operating guide.

## Stable Through Both Briefs

- The system is local-first and built around a locally installed DEVONthink.
- Evidence and knowledge need to be modelled differently.
- Agent access must start read-mostly and become write-capable only behind approval gates.
- Stable identities, item links, and explicit provenance are mandatory.
- Portability matters. Markdown remains the practical interchange format even when it is not the canonical working layer.
- Indexed content is useful but operationally dangerous if used carelessly.

## What Changed

### Control plane

- First brief: DEVONthink plus markdown sidecars, with Notion as an optional control plane.
- Second brief: keep the control plane inside DEVONthink; use external markdown only as a one-way mirror.
- Evergreen decision: DEVONthink is the control plane. External markdown exists for Git, tooling, bulk LLM access, and disaster portability, not for primary authoring.

### Canonical knowledge location

- First brief: structured analysis lives in markdown sidecars.
- Second brief: canonical knowledge lives in imported DEVONthink Markdown notes.
- Evergreen decision: knowledge notes and relation notes are native DEVONthink records. Export mirrors preserve portability and enable repository-level tooling.

### Notion

- First brief: reasonable optional metadata mirror and workflow console.
- Second brief: unnecessary for the base system and removed from scope.
- Evergreen decision: no Notion dependency in the base architecture. Reintroduce only if a real collaboration or external workflow need appears.

### Delivery model

- First brief: explicit phases from read-only profiling through scheduled automation.
- User correction: build continuously; measure progress through MVP points rather than serial phases.
- Evergreen decision: maintain parallel workstreams and define checkpointed functionality thresholds instead of a waterfall rollout.

## What The First Brief Still Contributes

- The community MCP is incomplete for a serious second-brain system without local extension.
- Custom metadata writeback and safe filing logic require deterministic local helpers.
- Sidecar or mirror formats need a disciplined schema if they are going to support external tooling.
- Safety gates, dry runs, and rollback are not optional.

## Current Canonical Rule

When the briefs disagree:

1. Prefer the second brief for product shape and control-plane design.
2. Retain the first brief where it identifies unresolved interface gaps, operational risks, or portability requirements.
3. Record any future reversal explicitly here.

---

## Design Contract Freeze — 2026-04-17

The following items were locked on this date. Any future change must be recorded here with a new datestamp and rationale.

### `PKIM_ID` format

Canonical: `<CLASS>-<YYYYMMDD>-<NNNN>` where `NNNN` is a zero-padded 4-digit sequence counter scoped to the date and class prefix. The counter resets each calendar day per prefix.

Canonical class prefixes: `EV` (evidence), `KN` (knowledge), `RL` (relation).

Rationale: "random-or-sequence" was ambiguous. For a single-user local system, a date-scoped sequence is legible and collision-free.

### `DocRole` vocabulary

Canonical and closed: `evidence`, `knowledge`, `relation`, `annotation`, `project`, `topic`, `operation`.

### `Review_State` vocabulary and state machine

Canonical and closed: `inbox`, `profiled`, `needs-human`, `approved`, `blocked`, `filed`, `mirrored`, `archived`, `error`.

Reconciliation: doc 08 listed `error` but omitted `mirrored`; doc 03 listed `mirrored` but omitted `error`. Both values are required. Both documents now carry the full nine-value list and the full state machine including `any → error` and `error → profiled`.

State machine is normative in `docs/design/03-information-model.md`.

### `Relation_Type` vocabulary

Canonical and closed: `supports`, `contradicts`, `extends`, `summarizes`, `references`, `exemplifies`, `precedes`, `supersedes`.

Rationale: no vocabulary existed in any design doc. Without a closed list, automation cannot validate relation types. The list is intentionally minimal; extend only through an explicit schema change recorded here.

### Relation-note rationale

Mandatory. A relation note with no rationale (minimum one sentence) is invalid and must not be created or accepted by automation.

Rationale: the design doc said "short human-readable rationale" without marking it mandatory, despite stating "without the explanation, it is just metadata pretending to be knowledge." Resolved as mandatory.

### `PKIM-Evidence-Personal` import/index exception rule

Index is allowed only when ALL of the following are true: (a) another application must edit the file in place, (b) the folder has operational meaning outside DEVONthink, (c) the content is NOT mobile-critical.

Rationale: "by exception" was undefined. The conditions are now explicit.

### `PKIM-Evidence-Server` mount stability rule

Index is allowed only when ALL of the following are true: (a) the mount has been continuously available for at least 30 days without manual reconnection, (b) the host system policy permits DEVONthink to hold a reference to the mount, (c) the folder is not a cloud-sync placeholder path.

Rationale: "mount stability is proven" was undefined.

### Mirror trigger rule

Mirror export runs when `Review_State=approved` AND (`Mirror_State` is absent or stale OR note content has changed since last mirror). Scheduled refresh and explicit operator requests are also valid triggers.

"Reviewed relation notes" in the mirror scope means relation notes where `Review_State=approved` — the same rule as knowledge notes.

Rationale: "on approved note change" was vague. The trigger is now defined in terms of observable field state.

### Write-gating policy

A production write may execute only when ALL of the following are true:
1. `PKIM_ALLOW_PRODUCTION_WRITES=true` in the runtime environment.
2. The capability probe returns `passed: true`.
3. The write path has been validated against a scratch database.
4. The command supports dry-run mode.
5. Before-state and after-state logging are emitted for the run.

Enabling `PKIM_ALLOW_PRODUCTION_WRITES=true` grants eligibility only. It does not waive any other condition.

### DEVONthink custom-metadata readback keys

Operational finding from the 2026-04-19 pilot: DEVONthink scripting can return custom metadata under internal field keys such as `mdpkim_id`, `mdreview_state`, `mddocrole`, and `mdnotetype` rather than only the human-facing field labels.

Canonical rule:

- write-facing contracts and design docs continue to use the human-facing names (`PKIM_ID`, `Review_State`, `DocRole`, `NoteType`, etc.)
- adapter code that reads DEVONthink metadata must normalize both representations before interpreting state

Rationale: without normalization, the runtime can misclassify profiled records as unprofiled and mirror logic can silently export nothing even when the underlying DEVONthink data is correct.

### Graph edges live in note bodies (2026-05-16)

Operational finding from a synthesis-methodology review: PKIM's design surface is heavily weighted toward capture, filing, and hygiene, and thin on the discipline by which evidence becomes structured understanding. A contributing cause is the temptation to express relationships as DEVONthink custom metadata fields. DT treats only body content, WikiLinks, item links, and replicants as graph data; custom metadata is invisible to See Also, back-references, AI suggestions, and graph traversal.

Canonical rule:

- graph edges live in note bodies as `[[PKIM_ID|Name]]` WikiLinks
- custom metadata describes properties of the record, not relationships to other records
- narrow exceptions: identity pointers on relation notes (`Source_Item`, `Target_Item`) that duplicate body WikiLinks, and derived-property fields written back by the export mirror
- every new field must be classified at design time as PROPERTY, INDEX-POINTER, or DERIVED

Reference: [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md), [01 Principles And Decisions](01-principles-and-decisions.md), [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md).

Rationale: storing relationships in metadata produces a richly-tagged but operationally inert knowledge base — relationships that look structured but are invisible to the tool that is supposed to use them. The rule keeps the system honest about what DEVONthink can and cannot see.

### MultiMarkdown headers as canonical native note format (2026-05-16)

Reverses an earlier anti-pattern entry in [08 Record And Note Specification](08-record-and-note-specification.md) §Anti-Patterns that listed MultiMarkdown metadata headers as a format to avoid.

Canonical rule:

- native DEVONthink Markdown notes use MultiMarkdown (MMD) metadata headers at the top of the file, separated from the body by a single blank line
- mirror files use YAML frontmatter for portability with external tooling
- the two formats are semantically equivalent and round-trip-testable
- standard MMD keys (`Title`, `Aliases`, `Tags`, `Author`, `Keywords`, `URL`, `Date`) are read natively by DEVONthink into its corresponding properties
- PKIM-specific custom fields (`PKIM_ID`, `DocRole`, `Review_State`, etc.) are carried in the MMD header for portability but remain authoritative on the DT record's custom metadata, set via JXA

Rationale: DEVONthink natively parses MMD headers and populates its own properties (notably `Aliases`, which is the mechanism by which `PKIM_ID`-based discovery works). YAML frontmatter sits in the body as opaque text and gives DT no hooks. Adopting MMD removes a class of script-based work that exists only to compensate for unread frontmatter.

Reference: [01 Principles And Decisions](01-principles-and-decisions.md), [08 Record And Note Specification](08-record-and-note-specification.md), [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.5.

### `PrimaryTopic` removed (2026-05-16)

User direction: insufficient value for the risk it carried of becoming an edge-in-metadata pointer to topic notes. Topical grouping is now expressed via tags, body WikiLinks to topic notes, or `Aliases`. Removed from §Core fields and §Topic or project note minimum metadata in [08 Record And Note Specification](08-record-and-note-specification.md). Audit trail in [19 Synthesis Uplift Plan — Appendix A](19-synthesis-uplift-plan.md#appendix-a--field-audit-table-wp02).

### Transport: PyObjC ScriptingBridge replaces JXA (2026-05-16)

The canonical transport to DEVONthink is now PyObjC + `ScriptingBridge.framework`, dispatched in-process from Python. The legacy `osascript`-spawning layer at `src/pkim/jxa.py` is deprecated and retained only as a short-term fallback for writes until they are ported under [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6g.

Canonical rule:

- only `src/pkim/bridge/` may import `ScriptingBridge`, `Foundation`, `AppKit`, or `objc`
- all read commands migrate to the bridge before writes (see WP0.6b–d)
- new code does not import `pkim.jxa`; it is retired in WP0.6h

Rationale: every JXA call forks `osascript`. Corpus-wide reads were dominated by fork/exec cost, not by DEVONthink's actual work. ScriptingBridge dispatches Apple Events in-process and returns typed Cocoa objects, producing a typed, debuggable, mypy-checkable surface.

Reference: [01 Principles And Decisions](01-principles-and-decisions.md), [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6.

### MCP: `dt-pkim-mcp` replaces the vendored community MCP (2026-05-16)

The vendored `mcp-server-devonthink` v1.9.0 is retired and replaced by `dt-pkim-mcp`, a Python MCP server built on the official `mcp` SDK that shares the bridge / domain / commands stack with the CLI. Supersedes the "wrap and extend the vendored MCP" stance recorded in [10 MCP Extension Specification](10-mcp-extension-specification.md).

Canonical rule:

- PKIM owns its MCP transport
- `dt-pkim-mcp` is the canonical MCP server identifier; it lives in `src/pkim/mcp/`
- the MCP transport is stdio-only for local Claude Code and Codex CLI integration
- MCP tools are thin wrappers over `pkim.commands` — no business logic in `pkim.mcp`

Rationale: the vendored MCP is built on string-template JXA; sitting on top of it would compound the fork/exec cost the bridge decision removes, and would keep the string-injection surface and JXA quirk catalogue in the workflow. Owning the MCP also enables synthesis-aware tools (claim ledgers, audit reports, contradiction registers) that have no equivalent upstream.

Reference: [01 Principles And Decisions](01-principles-and-decisions.md), [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), [10 MCP Extension Specification](10-mcp-extension-specification.md) (superseded).

### Read commands migrated to PyObjC ScriptingBridge (2026-05-17)

The following read-only command surfaces are now served by `pkim.bridge` rather than `osascript`-spawned JXA:

- `pkim list-inbox`
- `pkim probe-capabilities`
- `pkim health-check`
- `pkim metadata-overview` (record-enumeration phase; report-writing remains on JXA until WP0.6g)
- `pkim sweep-inbox` (candidate enumeration; `needs-human` flag write remains on JXA)
- `pkim queue-metrics`
- `pkim graph-audit` (record + ref-context fetch)
- `pkim extract-text` (record-fetch phase)

Compatibility note: each ported function retained its historical `_jxa_*` name so existing tests that patch the function as a seam continued to work without change. The dict-shape return contract was preserved.

Open transport item: DEVONthink's `classify` and `compare` AppleScript verbs are not directly exposed by PyObjC ScriptingBridge; `profile.py` keeps the JXA path for those two verbs until either `performSelector_withObject_` plumbing or a small AppleScript helper bridges the gap.

Reference: [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6d, [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md).

### Synthesis uplift Phases 1–4 landed (2026-05-17)

End-of-day landing of the remainder of the synthesis uplift programme. Doc 19 status table is the live tracker.

**Phase 1 — Claim schema and KN template.**

- New doc [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) defines the YAML claim block schema (`claim`, `type`, `confidence`, `evidence`, `contradicted_by`, optional `note`), the four claim types (`fact`, `inference`, `assumption`, `open-question`), the three-band confidence ladder, the contradiction-handling shapes, and the run-artefact contract for `runs/<run-id>/claim-ledger.md`.
- [08 Record And Note Specification](08-record-and-note-specification.md) KN template replaces `## Key points` with `## Claims`; introduces `KnowledgeConfidence` (PROPERTY) and `Claim_Backed` (DERIVED) fields; documents the migration approach (refactor-on-touch via `KnowledgeStatus=needs-review`).
- `pkim audit-discipline` extended with a `missing-claims` detector (`src/pkim/commands/audit_discipline.py`) that flags `reviewed`/`published` KNs lacking a populated `## Claims` block or carrying `fact`/`inference` claims without evidence.
- Three new authoring skills under `skills/`: `dt-build-claim-ledger`, `dt-detect-contradictions`, `dt-audit-claim-evidence`.
- Workflow 3 extended with a Pass 3 — Triangulate step; new Workflow 7 — Periodic Claim Audit added.

**Phase 2 — Mirror as analytical source of truth.**

- New package `src/pkim/mirror/` with a SQLite-backed graph store (`graph.py`), pure-SQL audits (`audits.py`), and the `Claim_Backed` write-back loop (`writeback.py`).
- Mirror schema documented in [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) Appendix B.
- Mirror audits add five new patterns: `orphan-kn`, `zombie-kn`, `dangling-wikilink` (corpus-wide), `corpus-contradiction`, `low-claim-density`.

**Phase 3 — Propagation and lifecycle.**

- EV supersession propagation lands in `src/pkim/mirror/propagation.py` and is codified in [15 Supersession And Retirement Policy](15-supersession-and-retirement-policy.md). Retiring an EV flips every dependent KN to `KnowledgeStatus=needs-review` via `DTWriter.set_knowledge_status`.
- New skill `dt-sweep-zombie-knowledge` surfaces KNs whose evidence is entirely retired.
- `needs-human` review state is codified in [08 Record And Note Specification](08-record-and-note-specification.md) as the catch-state for unresolved contradictions and degraded audit verdicts. Automated workflows skip `needs-human` records until cleared manually.

**Phase 4 — Checkpoint re-gating.**

- New Checkpoint S (Synthesis) inserted between C and D in [13 Capability And MVP Map](13-capability-and-mvp-map.md). Hard gate — D, E, F, G cannot be declared until S is met.
- Checkpoint G success criteria amended with four synthesis-health gates including ≥80% published-KN claim coverage and zero unresolved corpus contradictions.

**Cross-cutting transport closures.**

- `DTWriter` (`src/pkim/bridge/writes.py`) — typed write primitives (custom metadata, review state, knowledge status, `Claim_Backed`, aliases, tags, plain-text body). Replaces every legacy `_jxa_*` write helper at the primitive layer; command-module migration is per-touch follow-on.
- `pkim.bridge.applescript` — in-process NSAppleScript fallback for DT verbs the ScriptingBridge cannot reach (`classify`, `compare`).
- `pkim.bridge.reads._lookup_uuid` — corrected the UUID-resolution path (`getRecordWithUuid_in_` requires a database scope; iterate open databases).
- `pkim.jxa` now emits `DeprecationWarning` on import; full file removal gated on per-command migration in WP0.6g.

**Live-finding closures.**

- 7 legacy PKIM custom fields (`mdanchor`, `mdsource_role`, `mdprofile_status`, `mdcollection_id`, `mdpkim_type`, `mdknowledge_action`, `mdsourcetype`) added to `src/pkim/domain/fields_registry.py` so the audit accepts them; `mdsourcetype` retained as deprecated (native `kind` preferred).
- New CLI command `pkim repair-rl-endpoints` rewrites legacy relation-note bodies to add the canonical `## Endpoints` section. **Executed live 2026-05-17:** 36 records repaired, 0 failures.
- Deprecated `PrimaryTopic` field cleared from 7 PKIM-Knowledge records. PKIM-Knowledge audit-discipline now reports zero findings.

Reference: [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) §Status, [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md).

### Custom-metadata writes must go through `setCustomMetaData_` (2026-05-17)

Operational finding from the live `PrimaryTopic` cleanup pass: DEVONthink's `setValue:forKey:` raises `NSUnknownKeyException` when invoked with a custom-metadata key not registered in the live schema. This blocked clearing deprecated fields that still held values on legacy records.

Canonical rule:

- custom-metadata writes go through `setCustomMetaData_` (whole-dict replace), not per-key `setValue:forKey:`
- the dict-replace path works for add, update, and clear, and for both registered and unregistered keys
- `DTWriter.set_custom_metadata` is the canonical surface; no code calls `setValue:forKey:` directly for custom-metadata keys

Rationale: DT only key-codes the keys currently declared in its custom-metadata schema. Deprecated fields, legacy fields not yet re-registered, and any unknown keys all fail `setValue:forKey:` with `NSUnknownKeyException`. The `customMetaData` property accepts a whole dictionary regardless and persists what it accepts.

Reference: `src/pkim/bridge/writes.py` `DTWriter.set_custom_metadata`; regression tests in `tests/test_bridge_writes.py` covering the clear-key, update-existing-key, and preserve-other-keys paths.

### Write-command migration to bridge complete (2026-05-17)

WP0.6g landed. Every write-bearing command module has had its `_jxa_*` helpers ported off `osascript`/JXA onto `DTWriter`:

| Module | Helpers ported |
| --- | --- |
| `apply_metadata` | `_jxa_read_record`, `_jxa_find_max_sequence`, `_jxa_write_metadata`, `_jxa_set_pkim_alias` |
| `sweep_inbox` | `_jxa_set_needs_human` |
| `mirror` | `_jxa_query_approved_notes`, `_jxa_writeback` |
| `update_note` | `_jxa_set_plain_text`, `_jxa_set_note_content` |
| `metadata_overview` | `_jxa_find_note_by_name`, `_jxa_set_note_body` |
| `create_note` | `_jxa_create_record` — single bridge call instead of the AppleScript-then-JXA dance (PyObjC ScriptingBridge accepts `type: "markdown"` directly on `createRecordWith_in_`) |
| `ensure_group_path` | `_jxa_validate_group`, `_applescript_create_location` |
| `safe_file` | `_jxa_inspect_record`, `_jxa_validate_destination`, `_jxa_execute_filing` (move/duplicate), `_jxa_rename_record`, `_jxa_apply_alignment_metadata`, `_jxa_apply_indexed_metadata`, `_jxa_find_record_in_group` |
| `workspace` | `_jxa_set_alias`, `_jxa_lookup_uuid_by_pkim_id`, ref-resolution loop in `push_batch` |
| `search_notes` (legacy) | `_jxa_search` |

`DTWriter` gained these new typed primitives: `set_name`, `set_comment`, `create_record`, `create_group`, `move_record`, `replicate_record`, `duplicate_record`, `delete_record` — exercised via 10 new regression tests.

Open follow-on items (not blocking):

- `profile.py` retains JXA for the `classify` / `compare` verbs — neither is exposed by PyObjC ScriptingBridge selector resolution; the NSAppleScript fallback at `pkim.bridge.applescript.run_applescript` is the future migration path.
- `reporting.py` `restore-drill` retains its `osascript` open/close-database flow until the bridge gains a database lifecycle primitive.

Reference: `src/pkim/bridge/writes.py`, `tests/test_bridge_writes.py`, all `_jxa_*` helpers across `src/pkim/commands/`.

### Runtime pivot: compiled CLI replaces Python+PyObjC MCP server (2026-05-20)

The Python+PyObjC ScriptingBridge transport and the `dt-pkim-mcp` MCP server — both landed earlier in this register on 2026-05-16 — are retired in favour of a single compiled CLI (`pkim`) exposing atomic primitives, with policy and orchestration owned by skills. Supersedes the runtime decisions recorded in:

- [09 Automation Architecture](09-automation-architecture.md)
- [10 MCP Extension Specification](10-mcp-extension-specification.md) (already obsoleted by doc 20; now obsoleted further)
- [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md)

Canonical rule:

- the PKIM runtime is a single compiled binary (`pkim`) invoked per call; there is no warm process
- read operations target the on-disk DEVONthink Spotlight metadata cache at `~/Library/Metadata/com.devon-technologies.think/<DBID>/...` and `MDQuery`; ScriptingBridge is reserved for writes and for the small set of reads the cache cannot serve
- the verb surface is ~15 atomic primitives (get / resolve / list / search / body / aliases / tags / file-path / set-metadata / set-tags / set-name / set-body / move / create-note / create-group / mirror-of / sync-record); compound operations are skill workflows that compose these
- MCP, if used, is a thin shim that `exec`s the CLI and forwards JSON — no business logic in the shim
- skills are the canonical location for policy; the CLI is mechanism-only

Rationale: three pressures together — the PyObjC introspection tax on every property read, the existence of the on-disk metadata cache as a viable read plane, and the disappearance of the warm-process amortisation argument once the runtime is compiled — invalidate the Python+MCP runtime shape. Patches to that shape (asyncio offload, autorelease pools, bounded AE timeouts, batched walks) pave the cow-path; the pivot removes it.

The information model, safety model, identifier conventions, and operating model are unaffected. PKIM_ID, DocRole, Review_State, Relation_Type vocabularies, write-gating policy, MMD-headers-as-canonical, graph-edges-in-bodies, and supersession rules all carry forward unchanged.

Reference: [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md) — canonical doc for the pivot. [23 Swift pkim Binary](23-swift-pkim-binary.md) — forthcoming contract for the binary's CLI surface (drafted under task 7 of the pivot branch).
