# Skills Retirement Map

Disposition of every skill under `skills/` against the atomic verb
surface defined in [`docs/design/22-cli-first-atomic-primitives.md`](../docs/design/22-cli-first-atomic-primitives.md).
Produced 2026-05-20 under task 5 of the CLI-first pivot.

This is a map, not a rewrite. Skill bodies are rewritten in a separate
workstream once the Swift binary lands. The map's purpose is:

1. Confirm every skill survives the pivot (it does — zero retire, zero merge).
2. Flag which skills carry policy that is currently embedded in retired Python (`legacy/src/pkim/commands/`) and therefore need their bodies *expanded* to fully contain that policy when the Python is removed.
3. Surface verbs the skills expect that doc 22 doesn't yet list — these feed doc 23.

## Verb surface (reference)

```
Reads          get  resolve  list  search  body  aliases  tags  file-path
Writes         set-metadata  set-tags  set-name  set-body  move
               create-note  create-group
Mirror/file    mirror-of  sync-record
Auxiliary      extract-text  probe-capabilities  health-check
```

Verb additions surfaced by this survey (see §Gaps): `mint-id`.

## Disposition table

| Skill | Disposition | Verbs used | Note |
|---|---|---|---|
| `dt-health-check` | THIN-WRAPPER | `health-check` | Direct call; gates other skills on runtime fitness. |
| `dt-ensure-group-path` | THIN-WRAPPER | `create-group` | Validates path against taxonomy, then creates. |
| `dt-apply-approved-metadata` | THIN-WRAPPER | `set-metadata`, `set-tags` | Field validation + state-transition policy around atomic writes. |
| `dt-safe-file` | THIN-WRAPPER | `move` | Pre-move sanity gate (filing allowlist, optional metadata alignment). |
| `dt-profile-record` | THIN-WRAPPER | `get`, `body`, `extract-text` | Read-only concept-set packet for one record. |
| `dt-sweep-inbox` | ORCHESTRATOR | `list`, `get`, `set-metadata`, `move` | Intake triage policy + per-record sequential workflow. |
| `dt-resolve-canonical-note` | ORCHESTRATOR | `search`, `get`, `body` | Merge/supersede/create decision logic across candidate set. |
| `dt-build-knowledge-note` | ORCHESTRATOR | `mint-id`*, `create-note`, `set-metadata`, `set-body`, `set-tags` | Full KN authoring; mint ID, offline draft, write. |
| `dt-build-relation-note` | ORCHESTRATOR | `mint-id`*, `create-note`, `set-metadata`, `set-body`, `set-tags` | Parallel to build-knowledge-note for RL records. |
| `dt-audit-graph-corpus` | ORCHESTRATOR | `search`, `get`, `body` | Multi-phase corpus audits; returns prioritised findings + repair routing. |
| `dt-reconcile-relation-edge` | ORCHESTRATOR | `get`, `body`, `set-body`, `set-metadata`, `search` | Single-record relation repair; enforces RL discipline. |
| `dt-inspect-graph-neighbourhood` | ORCHESTRATOR | `search`, `get`, `body`, `aliases`, `tags` | 1-hop graph walk; diagnostic only. |
| `dt-audit-claim-evidence` | ORCHESTRATOR | `search`, `get`, `body` | Cross-checks `## Claims` evidence links against EV records. |
| `dt-build-claim-ledger` | ORCHESTRATOR | `search`, `get`, `body`, `extract-text` | Claim-to-evidence ledger build. |
| `dt-identify-knowledge-gaps` | ORCHESTRATOR | `search`, `get`, `body` | Surfaces approved EV records lacking inbound knowledge links. |
| `dt-detect-contradictions` | ORCHESTRATOR | `search`, `get`, `body`, `aliases` | Finds contradiction chains across `contradicts`/`supports`/`supersedes`. |
| `dt-sweep-zombie-knowledge` | ORCHESTRATOR | `search`, `get`, `body`, `set-metadata` | Orphan/stale scan; applies `Review_State` transitions. |
| `dt-execute-repair-plan` | ORCHESTRATOR | `get`, `set-metadata`, `set-body`, `set-tags`, `move` | Applies coordinated multi-step fixes from audit findings. |
| `dt-recover-failed-write` | ORCHESTRATOR | `get`, `search`, `set-metadata`, `body` | Error-state inspection + recovery policy. |
| `dt-review-metadata-overview` | ORCHESTRATOR | `search`, `get` | Per-database field-coverage statistics; read-only. |
| `dt-review-queue-health` | ORCHESTRATOR | `search`, `get` | Smart-group queue depth + age; read-only. |
| `dt-sync-export-mirror` | ORCHESTRATOR | `search`, `get`, `body`, `sync-record`, `mirror-of` | Drives mirror DB rebuild. |
| `dt-push-batch` | ORCHESTRATOR | `create-note`, `set-metadata`, `move` | Workspace-directory batch ingestion. |
| `dt-check-scale-readiness` | ORCHESTRATOR | `get`, `search`, `health-check` | Environmental diagnostic. |
| `dt-run-restore-drill` | DEFERRED | (none on atomic surface) | Depends on DB open/close, which §1 of doc 22 retires. Skill stays as documentation of the drill until a successor verb appears. |

\* `mint-id` is a gap — see §Gaps.

## Counts

```
THIN-WRAPPER        5
ORCHESTRATOR       19
DEFERRED            1
RETIRE              0
MERGE               0
                  ---
Total skills       25
```

Every skill survives the pivot. The architectural change is entirely in the runtime shape and the policy location — none of the workflows themselves are invalidated.

## Skills with policy currently embedded in retired Python

These nine skills carry policy that today lives in `legacy/src/pkim/commands/*.py`. When the Swift binary lands and Python is deleted, the skill body must contain *all* of that policy explicitly. Track them as the rewrite targets:

| Skill | Source of embedded policy |
|---|---|
| `dt-sweep-inbox` | `legacy/src/pkim/commands/sweep_inbox.py` |
| `dt-resolve-canonical-note` | `legacy/src/pkim/commands/profile.py` (parts) + candidate comparison logic |
| `dt-build-knowledge-note` | `legacy/src/pkim/commands/create_note.py` + `update_note.py` |
| `dt-build-relation-note` | `legacy/src/pkim/commands/create_note.py` (RL variant) + parts of `repair_rl_endpoints.py` |
| `dt-audit-graph-corpus` | `legacy/src/pkim/commands/audit_discipline.py` + `graph.py` + `legacy/.../mirror/audits.py` |
| `dt-reconcile-relation-edge` | `legacy/src/pkim/commands/repair_rl_endpoints.py` |
| `dt-apply-approved-metadata` | `legacy/src/pkim/commands/apply_metadata.py` |
| `dt-safe-file` | `legacy/src/pkim/commands/safe_file.py` |
| `dt-sync-export-mirror` | `legacy/src/pkim/commands/mirror.py` + `sync_metadata.py` |
| `dt-push-batch` | `legacy/src/pkim/commands/workspace.py` |

The other skills already contain their policy in markdown; their post-pivot change is just naming the new verbs in the runbook section.

## Gaps — verbs the skills expect that aren't yet in doc 22

### `pkim mint-id` (proposed addition)

Used by `dt-build-knowledge-note` and `dt-build-relation-note`. Deterministic generator producing `<CLASS>-<YYYYMMDD>-<NNNN>` per doc 00 §`PKIM_ID` format. Two natural shapes:

- **Pure-function variant:** `pkim mint-id --type <kn|rl|ev|cl> [--date YYYYMMDD]` — returns next ID without touching DT. Requires a counter source. The Python implementation today computes the next sequence by scanning DT for existing IDs of that class on that date; a Swift implementation can do the same via `mdfind` against the `.dt` cache. Read-only.
- **Reserve-and-allocate variant:** writes a reservation file to disk to prevent two concurrent mints colliding. Likely unnecessary for a single-user local system, but worth flagging.

**Recommended call:** add `pkim mint-id` as a 17th primitive verb (alongside `extract-text`, `probe-capabilities`, `health-check` from the §Ambiguities of doc 22). Pure-function variant. Captures one of the few pieces of business logic that *does* belong in the binary because every skill that creates records needs it.

### Auxiliary verbs surfaced

The §Ambiguities of doc 22 already proposed `extract-text`, `probe-capabilities`, and `health-check` as auxiliary verbs. The skills survey confirms all three are needed (`dt-profile-record`, `dt-build-claim-ledger` use `extract-text`; `dt-health-check`, `dt-check-scale-readiness` use the probes). Lock these into doc 23.

### Verbs the skills do *not* need

The survey did not surface a single use of: a deletion verb, an explicit `setReviewState` verb separate from `set-metadata`, a JSON-batch verb, or a daemon-mode verb. `pkim` stays at ~17 atomic verbs.

## What this map does not do

- It does not rewrite any skill body. That happens after task 7 (doc 23) locks the verb surface and after the Swift binary lands. The rewrite is part of the implementation workstream, not this pivot branch.
- It does not finalise the `dt-run-restore-drill` decision. If the binary never gains DB open/close, the skill becomes a manual runbook (humans run the AppleScript helpers in `scripts/`). That choice is recorded in doc 23.
- It does not catalogue the `_shared/` policy fragments. Those are pure prose; no verb coupling; KEEP-AS-IS.

## Implications for doc 23 (task 7)

The atomic verb list in doc 23 should be:

```
Reads (8)         get  resolve  list  search  body  aliases  tags  file-path
Writes (7)        set-metadata  set-tags  set-name  set-body  move
                  create-note  create-group
Mirror/file (2)   mirror-of  sync-record
Auxiliary (4)     extract-text  probe-capabilities  health-check  mint-id
                                                                ─────────
                                                                  Total: 21
```

The shift from 15 → 21 is justified — every added verb is a primitive backed by skill usage in this survey, not a compound operation in disguise.
