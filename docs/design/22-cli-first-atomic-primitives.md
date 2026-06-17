# CLI-First Atomic Primitives

## Purpose

Define the architectural pivot from a Python+PyObjC MCP server with compound tools to a single compiled CLI (`pkim`) exposing atomic primitives, with policy and orchestration owned by skills.

This doc is canonical for the pivot. It supersedes the runtime parts of [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), [10 MCP Extension Specification](10-mcp-extension-specification.md), and the automation-runtime parts of [09 Automation Architecture](09-automation-architecture.md). The information model, safety model, and operating model are unchanged — only the runtime shape is.

The concrete command-line surface, JSON contract, and project layout for the binary are specified separately in [23 Swift pkim Binary](23-swift-pkim-binary.md) (forthcoming under this branch).

## Why this pivot

Three pressures arrived together.

### 1. PyObjC introspection tax

Every property read on a DEVONthink record through PyObjC ScriptingBridge crosses the Python ↔ Objective-C bridge: method-table lookup, SEL resolution, runtime invoke, NSObject return, type coercion back to Python. On a 50 k-record corpus that is millions of bridge crossings before a single Apple Event leaves the process. The cost is structural, not implementation-quality — it is the price of using Python as the client for a Cocoa scripting API. A compiled Swift binary calling the same scripting suite pays a vtable-call cost per access.

### 2. Apple Events are the wrong read plane

DEVONthink ships its Spotlight metadata into `~/Library/Metadata/com.devon-technologies.think/<DBID>/<bucket>/<UUID>.dt`, a trivial TLV format (`DTst` tag + 4-byte field name + length + payload) holding per-record name, path, custom metadata, and more. The cache is on disk, queryable by `mdfind` / `MDQuery`, and available even when DEVONthink is not running. Walking DT through ScriptingBridge to answer questions the OS has already indexed is the wrong layer of abstraction. Reads do not need DT to be the query engine; they need DT to be the source of truth that the OS index reflects.

The Alfred Dt4Portal workflow (a small Swift binary at `…/user.workflow.F552D5EC-…/src/Dt4Portal`) already demonstrates this approach: parse the metadata cache directly, hit `MDQuery` for full-text, fall back to scripting only when necessary. Its sub-second performance across a large corpus is what the PKIM read plane should look like.

### 3. The MCP server's reason for existing has evaporated

The MCP server was justified by warm-process amortisation. Python import + PyObjC bridge construction + SB connect cost hundreds of ms; making every skill pay that on every call was untenable, so a long-lived stdio server kept the bridge warm. Caches (`BridgeSession`'s record/database TTL maps in `src/pkim/bridge/session.py`) exist for the same reason.

A compiled Swift binary starts in ~10 ms. The amortisation justification disappears. Once it disappears, every downstream complication that flowed from it — the asyncio event loop that blocks under sync SB calls (the "runs a bit then halts" symptom in this branch's parent state), the autorelease-pool growth in a long-lived process, the cache-invalidation bookkeeping, the dual-path code in `pkim.cli` and `pkim.mcp.tools`, the "is the server still alive" failure mode — also disappears, because there is no long-lived process to host them.

### Composed effect

Each pressure alone could be patched. Together they say the runtime shape is wrong. The fixes the parent state was reaching for (`asyncio.to_thread` wrappers, `objc.autorelease_pool` blocks, bounded Apple Event timeouts, batched walks) all pave the cow-path of "Python as the bridge, MCP as the runtime, compound tools as the surface". The pivot is to stop paving it.

## The new shape

```
┌─────────────────────────────────────────────────────────┐
│  Skills (markdown workflows)                            │
│    ├─ policy                                            │
│    ├─ orchestration                                     │
│    └─ agent-readable, version-controlled                │
├─────────────────────────────────────────────────────────┤
│  pkim CLI (single Swift binary, atomic verbs)           │
│    ├─ Read verbs  → .dt cache + MDQuery + (rare) SB     │
│    └─ Write verbs → ScriptingBridge into DEVONthink     │
├─────────────────────────────────────────────────────────┤
│  Persistence                                            │
│    ├─ DEVONthink databases  (system of record)          │
│    ├─ Indexed .md files     (file-as-truth surface)     │
│    ├─ Mirror DB (SQLite)    (queryable derived graph)   │
│    └─ runs/                 (per-call run manifests)    │
├─────────────────────────────────────────────────────────┤
│  MCP shim (optional, ~50 LOC)                           │
│    └─ exec(pkim …) and forward JSON                     │
└─────────────────────────────────────────────────────────┘
```

### Layer rules (binding)

1. **The CLI owns mechanism only.** Every verb is a single DEVONthink transaction or a single read against the cache. No verb encodes a multi-step workflow. No verb encodes business policy that belongs to a skill (filing rules, classification rules, supersession sequencing, review-state ladders).
2. **Skills own policy and orchestration.** Compound operations (`sweep_inbox`, `audit_discipline`, `graph_audit`, `deep_profile`, `migrate_*`, `repair_*`) are skill workflows that compose primitives. The Markdown skill is the source of truth for *what to do*; the binary is the source of truth for *how to do one step*.
3. **Reads do not require DEVONthink to be running** unless explicitly noted on the verb. The default read path is the `.dt` cache and `MDQuery`. Writes always require DT to be running.
4. **Each verb invocation is its own process.** No daemon, no shared state between calls, no warm caches. State that must persist between calls lives on disk (the mirror DB, run manifests, indexed files).
5. **JSON in, JSON out, exit code 0/non-zero.** Every verb takes flags + optional `--from @file` for large blobs, and writes a single JSON envelope to stdout. Errors return a structured envelope with `error_type` and `error_message`, plus a non-zero exit code.
6. **The MCP shim, if it exists, contains no logic.** It maps tool names to subprocess invocations and forwards JSON. The same code path serves human invocations and agent invocations.

### What changes vs. what stays

| Aspect | Before | After |
|---|---|---|
| Runtime | Python+PyObjC MCP server (stdio, long-lived) | Compiled CLI, per-call |
| Read plane | ScriptingBridge walks of live DT | `.dt` cache + `MDQuery`, SB only as fallback |
| Cache layer | `BridgeSession` TTL maps | None (each call is cold; cost is bounded) |
| Tool surface | ~25 compound MCP tools | ~15 atomic CLI verbs |
| Policy location | Embedded in `src/pkim/commands/*.py` | `skills/*/SKILL.md` |
| Skills role | Documentation of how to call compound tools | Executable policy that composes primitives |
| Information model | Unchanged (KN, EV, RL, CL, WikiLink, Claim) | Unchanged |
| Safety model | Write gate via `PKIM_ALLOW_PRODUCTION_WRITES` | Unchanged; enforced in CLI |
| Identifiers | PKIM_ID, DT UUID, item-link | Unchanged |
| Mirror DB | Built by Python commands | Built by `pkim sync-record` invocations |
| File-as-truth | Indexed Markdown is authoritative for body | Unchanged |
| Run manifests | Per-MCP-call into `runs/<id>/` | Per-CLI-call into `runs/<id>/` |

## Verb surface (preview)

Full schema, flags, and JSON envelopes are in [23 Swift pkim Binary](23-swift-pkim-binary.md). This list anchors the retirement inventory.

### Reads

```
pkim get <uuid>                              # single record + metadata
pkim resolve <ref>                           # pkim-id | uuid | item-link → uuid
pkim list <db> --group <path>                # immediate children only
pkim search <db> --field K=V [--text Q]      # one filter set, returns uuids
pkim body <uuid>                             # raw markdown
pkim aliases <uuid>
pkim tags <uuid>
pkim file-path <uuid>
```

### Writes

Each write is one Apple Event. Each is idempotent (set, not transition).

```
pkim set-metadata <uuid> <K=V> [<K=V>…]
pkim set-tags <uuid> [--add T]… [--remove T]…
pkim set-name <uuid> <name>
pkim set-body <uuid> --from @file
pkim move <uuid> --to <group>
pkim create-note <db> --group <path> --title … --body @file
pkim create-group <db> --path <path>
```

### Mirror / file layer

```
pkim mirror-of <uuid>                        # disk path of indexed record
pkim sync-record <uuid>                      # reconcile one .md ↔ DT row + mirror DB
```

That is the whole binary. ~15 verbs. Everything else is a skill.

**Update (2026-05-20 under task 5 and 7):** the skill survey in [`skills/RETIREMENT-MAP.md`](../../skills/RETIREMENT-MAP.md) and the contract drafting in [doc 23](23-swift-pkim-binary.md) settled the final verb count at **21**: the 15 above plus four auxiliary verbs surfaced as needed in §Ambiguities and the skill survey — `extract-text`, `probe-capabilities`, `health-check`, `mint-id`. Doc 23 is canonical for the full list; this section preserves the original 15 to show the shape of the pure record-verb surface.

## What moves into skills

The compound tools today encode business policy in code. After the pivot, that policy lives in skill workflows. Examples:

| Today (compound tool) | After (skill that composes primitives) |
|---|---|
| `sweep_inbox` | `dt-sweep-inbox`: lists inbox via `pkim list`, gets each via `pkim get`, decides classification (skill prose + agent reasoning), applies via `pkim set-metadata` + `pkim move` |
| `audit_discipline` | `dt-audit-graph-corpus`: queries via `pkim search` + `pkim body`, runs the audit checks in skill prose, emits a findings JSON |
| `graph_audit` | Skill workflow over `pkim search` + `pkim get` |
| `deep_profile` | Skill workflow over `pkim get` + `pkim body` + `pkim aliases` + mirror DB query |
| `migrate_claims_to_nodes` | Skill workflow: `pkim search` to find candidates, `pkim body` to read, `pkim create-note` for CL records, `pkim set-body` to update KN |
| `repair_rl_endpoints` | Skill workflow over `pkim search` + `pkim body` + `pkim set-body` |
| `sync_metadata` | Skill workflow that walks indexed files, calls `pkim sync-record` per file |
| `sync_mirror` | Skill workflow that drives `pkim sync-record` across the corpus |

The principle: anything that today returns a multi-section structured report becomes a skill that orchestrates atomic calls and assembles the report. The primitive does not know what an "audit" is; the skill does.

## Honest trade-offs

1. **Many small calls.** A skill profiling 500 records fires ~500 invocations. At ~10 ms each that is ~5 s, which is acceptable. If a real hotspot emerges, add one `pkim batch < commands.jsonl` verb that runs N primitives in one process — but only when measurement demands it.
2. **Cross-record transactionality.** Today's compound tools run as one logical operation; if interrupted, partial state can be hard to reason about. As primitives, a skill can die halfway through. Each primitive is idempotent and skills checkpoint progress to a file. Net effect: clearer recovery, not worse.
3. **Agent friction.** Agents call more verbs, each with their own JSON envelope. This is a feature: each step is visible, replayable, and reasoned about, instead of opaquely invoked.
4. **Two languages in the repo.** Swift for the binary, Python is retired from the runtime (skills remain markdown). The `src/pkim/` tree shrinks dramatically. Domain types are re-expressed in Swift; the domain model itself is unchanged.
5. **MCP becomes optional.** Hosts that want MCP get a thin shim. Hosts that prefer direct CLI invocation skip MCP entirely. Both paths exercise the same binary.

## Retirement inventory

This section is the authoritative deletion plan for the pivot. Each path is classified as **DELETE** (retired by the pivot, gone from the tree), **PORT** (logic re-expressed in the Swift binary; Python source then deleted), **KEEP-TRANSITIONAL** (stays Python during the transition; revisited after the binary lands), or **KEEP** (untouched by the pivot).

Survey performed 2026-05-20. Counts are exact at that snapshot; small drift is expected as tests are added or removed before deletion commits execute.

### src/pkim/

| Path | Disposition | Target / reason |
|---|---|---|
| `__init__.py`, `cli.py`, `runtime.py` | DELETE | Python entry-point + run-id/run-dir glue; Swift binary owns its own run management. |
| `bridge/__init__.py` | DELETE | Module root. |
| `bridge/client.py` | DELETE | `DTBridge`, `SBApplication` wrapper, `probe()` — re-expressed in Swift. |
| `bridge/reads.py` | DELETE | `DTReader.search`/`get_record_*`/`get_body` → Swift implementations of `pkim get`/`search`/`list`/`body`. |
| `bridge/writes.py` | DELETE | `DTWriter` primitives → Swift implementations of `pkim set-metadata`/`set-body`/`set-name`/`set-tags`/`move`/`create-note`/`create-group`. |
| `bridge/convert.py` | DELETE | ObjC↔Python coercion; native in Swift. |
| `bridge/applescript.py` | DELETE | NSAppleScript fallback for `classify`/`compare`; not in the atomic surface (deferred — see ambiguity §1). |
| `bridge/session.py` | DELETE | `BridgeSession` warm-process caches; no warm process under the pivot. |
| `bridge/errors.py` | DELETE | `BridgeError` hierarchy → Swift `Error`-conforming types. |
| `mcp/__init__.py`, `mcp/server.py`, `mcp/tools.py`, `mcp/resources.py` | DELETE | Entire MCP server layer. If host MCP integration is wanted, it lives as a ~50 LOC subprocess shim outside this tree. |
| `commands/*.py` (all ~25 modules) | DELETE | Compound command modules; policy moves into skill workflows. Listed exhaustively in the [commands table](#commands-table) below. |
| `domain/ids.py` | DELETED | `PKIMId` lives in `pkim-binary/Sources/pkim/Domain/PKIMId.swift`. Python source deleted by the pivot-followups branch. |
| `domain/records.py` (RecordHandle) | DELETED | The Swift binary uses `DEVONthinkRecord` from the typed bridge directly. |
| `domain/edges.py` | DELETED | `RelationType` was relation-discipline policy held in Python for the mirror module. Module retired by the pivot-followups branch; the type vocabulary survives as skill markdown (`docs/design/00-source-reconciliation.md` §Relation_Type). |
| `domain/classification.py` | DELETED | PROPERTY / INDEX-POINTER / DERIVED categories now live only as skill-prose discussion. The Python enum had a single audit-time consumer in `mirror/audits.py`; both retired together. |
| `domain/wikilinks.py` | DELETED | WikiLink parser; only consumer was `mirror/graph.py`. Retired with the mirror module. |
| `domain/claims.py` | DELETED | Claim block parser; same shape as wikilinks — mirror-internal. |
| `domain/fields_registry.py` | DELETED | Canonical field → classification map; used by `mirror/audits.py`. Retired with the mirror module. |
| `domain/headers.py` | DELETED | YAML↔MMD header conversion used by mirror sync. Skill-side YAML processing replaces it when needed. |
| `extraction/__init__.py`, `extraction/extractors.py` | DELETED | Swift `extract-text` covers PDF / txt / md / html / rtf via PDFKit + NSAttributedString. DOCX / PPTX / XLSX / EPUB / RTFD support was retired; if a need re-emerges, port to Swift via `textutil` shell-out. |
| `mirror/__init__.py`, `graph.py`, `audits.py`, `propagation.py`, `writeback.py` | DELETED | Mirror graph builder, SQL audits, EV-supersession propagation, `Claim_Backed` write-back. Retired wholesale by the pivot-followups branch; the audit semantics that survive are re-expressed as skill workflows over `pkim search` / `get` / `body` / `set-body` / `set-metadata`. The mirror DB itself is no longer maintained — if the queryable derived graph is needed in future, a skill writes it from `pkim search` output.|

#### Commands table

All entries DELETE. Logic re-expressed as either an atomic verb (named in the right column) or a skill workflow that composes verbs.

| Module | Disposition path |
|---|---|
| `apply_metadata.py` | Skill: composes `pkim set-metadata`. |
| `audit_discipline.py` | Skill: composes `pkim search` + `pkim body` + `pkim get`. |
| `bridge.py` | Native verb (capability probe; see ambiguity §3). |
| `create_claim.py` | Skill: composes `pkim create-note` + `pkim set-metadata`. |
| `create_note.py` | Native verb: `pkim create-note`. |
| `deep_profile.py` | Skill: composes `pkim get` + `pkim body` + `pkim aliases` + mirror DB. |
| `ensure_group_path.py` | Native verb: `pkim create-group`. |
| `extract_text.py` | Native verb (pending §2): `pkim extract-text`. |
| `graph.py` | Skill: composes `pkim search` + `pkim get` + mirror DB. |
| `health.py` | Skill (or native verb; see ambiguity §3). |
| `inbox.py` | Native verb: `pkim list <db> --group /Inbox`. |
| `metadata_overview.py` | Skill: composes `pkim search` + analysis. |
| `migrate_claims_to_nodes.py` | Skill: composes `pkim search` + `pkim body` + `pkim create-note` + `pkim set-body`. |
| `migrate_evidence_links.py` | Skill: composes `pkim search` + `pkim body` + `pkim set-body`. |
| `migrate_mmd.py` | Skill: composes `pkim search` + `pkim body` + `pkim set-body`. |
| `mirror.py` | Skill: composes `pkim sync-record` over a corpus selection. |
| `note_format.py` | Inlined into verbs (markdown header authoring) or into skills. |
| `profile.py` | Retired (depends on JXA `classify`/`compare`; see ambiguity §1). |
| `probe.py` | Native verb (capability probe; see ambiguity §3). |
| `repair_rl_endpoints.py` | Skill: composes `pkim search` + `pkim body` + `pkim set-body`. |
| `reporting.py` | Retired (`restore-drill` depends on JXA DB open/close; see ambiguity §1). |
| `safe_file.py` | Native verb: `pkim move`. |
| `search.py`, `search_notes.py` | Native verb: `pkim search`. |
| `sweep_inbox.py` | Skill: composes `pkim list` + `pkim get` + `pkim set-metadata` + `pkim move`. |
| `sync_metadata.py` | Skill: walks indexed `.md` files, composes `pkim sync-record`. |
| `update_note.py` | Native verbs: `pkim set-body` + `pkim set-metadata`. |
| `validation.py` | Inlined into Swift verbs as guard clauses. |
| `workspace.py` | Skill: composes `pkim create-note` per file in the workspace dir. |

### scripts/

| Path | Disposition | Reason |
|---|---|---|
| `pkim` | DELETE | Old Python CLI entry; replaced by Swift binary on `PATH`. |
| `pkim-devonthink-helper` | DELETE | AppleScript shim subsumed by the Swift binary. |
| `pkim-health-check`, `pkim-probe-capabilities`, `pkim-sync-mirror` | DELETE | Wrappers around Python commands; replaced by skill workflows or native verbs. |
| `setup-database-groups.applescript`, `verify-database-setup.applescript`, `verify-smart-groups.applescript`, `fix-smart-group-predicates.applescript`, `install-note-templates.applescript` | PORTED | All five ported to native `pkim` verbs by the pivot-followups branch (see doc 23 §Setup verbs). AppleScript files deleted; logic lives in `pkim-binary/Sources/pkim/Setup/PKIMSetup.swift` and the matching `Commands/Setup*.swift`. |
| `README.md` | REWRITTEN | Documents the verb-port surface and the script-vs-skill boundary. |

### tests/

All `test_bridge_*.py`, `test_mcp_*.py`, and per-compound-command test files map to their parent module's disposition:

| Pattern | Disposition | Notes |
|---|---|---|
| `test_bridge_*.py` (4 files) | DELETE | Bridge layer retired. |
| `test_mcp_*.py` (3 files) | DELETE | MCP layer retired. |
| `test_pkim_<command>.py` for every retired command module | DELETE | Tests of compound logic. Behaviour that survives lives in skill workflows; tests of atomic verbs are written in Swift. |
| `test_domain_*.py` (4 files) | PORT | Domain unit tests re-expressed as Swift unit tests; Python source then deleted. |
| `test_mirror_*.py` (5 files) | KEEP-TRANSITIONAL | Track the mirror module's transitional status. |
| `test_pkim_smoke.py`, `test_audit_missing_tags.py`, `test_migrate_claims_to_nodes.py` | DELETE | Compound logic; behaviour re-expressed in skills + Swift integration tests. |

### Top-level

| Path | Disposition | Notes |
|---|---|---|
| `pyproject.toml` | REWRITTEN-STUB | All Python deps removed by the pivot-followups branch. The file survives as a one-section stub so a stray `uv pip install` against the repo root degrades gracefully. |
| `uv.lock` | DELETED | Removed after the Python dependency list emptied. |
| `vendor/` | DELETE | Empty under current `main`; nothing vendored after the MCP SDK move. |

### Ambiguities and recommended calls

**§1 — `classify`/`compare` and DB open/close.** Today `profile.py` and `reporting.py` reach for `NSAppleScript` because DT's `classify`, `compare`, and database open/close verbs are not exposed cleanly by PyObjC ScriptingBridge. Swift's `NSAppleScript` API is the same surface; these can be wrapped, but they are not in the atomic 15. **Recommended call:** retire from the core verb surface; if a real use case re-emerges, add as a 17th/18th primitive in doc 23 with a clear scope. Until then, the dependent commands (`profile.py`, `reporting.py`, `restore-drill`) retire without a successor.

**§2 — `extract-text`.** Doc 22 lists 15 verbs. Text extraction is a clear *read primitive* (it produces text from a file path; deterministic, no DT round-trip). **Recommended call:** add `pkim extract-text <file-path>` to the binary as the 16th primitive in doc 23. The existing Python extractors port to Swift (using available macOS frameworks for PDF / Office formats; some formats may need a vendored library). If Swift parity is expensive for one or two niche formats, fall back to per-format helpers shelled out by the binary.

**§3 — capability / health probes.** `pkim probe-capabilities` and `pkim health-check` are not record-shaped verbs; they describe the *environment*. **Recommended call:** both become native binary verbs (cheap to implement in Swift; no DT round-trip beyond checking that the app is reachable). Add to doc 23 as auxiliary verbs alongside the 15 record verbs.

**§4 — `src/pkim/mirror/`.** Kept transitional. Once the binary exists, the mirror module rewrites to consume `pkim` CLI output instead of importing `pkim.bridge`. Pure-SQL audits in `audits.py` are unaffected. **Recommended call:** revisit after task 7 completes; do not port to Swift yet — the cost/benefit is unclear and the module's API is still moving.

### Disposition counts

Final state after the pivot-followups branch (`feat/pivot-followups`):

```
DELETED               ~110 Python source + test files
                       (bridge/*, mcp/*, commands/*, cli, runtime, domain/*,
                        extraction/*, mirror/*, every test that imported them)
PORTED                 5 AppleScript setup helpers → Swift verbs
                       (setup-database, verify-database, verify-smart-groups,
                        fix-smart-groups, install-templates — see doc 23)
REWRITTEN              2 files (pyproject.toml stub, scripts/README.md)
DELETED-EXTRA         uv.lock, src/, tests/ (now-empty package roots)
```

Final commit-batch sequencing is in task 6.

## Migration order

1. This doc (task 1 — current).
2. Mark upstream docs as superseded with banners pointing here (task 2).
3. Register doc 22 in `docs/design/README.md` and `00-source-reconciliation.md` (task 3).
4. Produce the exact retirement inventory in the section above (task 4).
5. Rewrite the skills index against the new primitives — map each skill to its new shape (task 5).
6. Delete retired Python in reviewable batches (task 6). Stops once Python runtime is gone; the Swift binary does not yet exist, so the branch is functionally non-operational at that point — acceptable on a pivot branch.
7. Write doc 23 specifying the Swift binary's exact surface (task 7). This is the contract the implementation is built against.

Implementation of the Swift binary itself is **not** part of this branch's task list. The branch's job is to land the decision, retire the displaced code, and produce the contract. The build of the new runtime is a separate workstream against a clean tree.

## Out of scope for this doc

- The Swift binary's exact CLI surface, flag set, JSON envelopes, error codes, project layout, build instructions — all in [23 Swift pkim Binary](23-swift-pkim-binary.md).
- The implementation order of porting individual verbs.
- Performance benchmarking targets (`docs/ops/` will own those once there is something to measure).
- Changes to the information model, safety model, or operating model. None of these are affected by the pivot.

## Anti-patterns this doc forbids

- Adding a "compound" verb to the CLI because "the skill is fiddly". The fiddliness belongs in the skill; if the skill is fiddly the policy is wrong, not the verb surface.
- Re-introducing a long-lived process to amortise startup. The startup cost is the budget that constrains how chatty the workflow can be; respecting it forces good design.
- Re-introducing PyObjC anywhere in the runtime hot path. The Python `pkim.mirror` module may temporarily survive for the mirror builder, but it does not call DT live — it consumes `.dt` cache or `pkim` CLI output.
- Hiding state in MCP server memory. State is on disk (mirror DB, run manifests, indexed files) or it does not exist.
