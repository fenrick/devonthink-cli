# Bridge And MCP Architecture

> **SUPERSEDED 2026-05-20** by [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md).
>
> The Python+PyObjC bridge and Python MCP server described here are retired. Three pressures together — the PyObjC introspection tax, the existence of DEVONthink's on-disk Spotlight metadata cache as a viable read plane, and the disappearance of the warm-process amortisation argument once the runtime is compiled — invalidate the runtime model in this doc. The pivot is to a single compiled CLI (Swift, contract in doc 23) exposing atomic primitives, with skills owning policy.
>
> What this doc still records correctly: the *layered separation* between transport, orchestration, domain, and bridge. That separation survives — it is just re-expressed in the new runtime. Doc 22 explains the new layering. The information model, safety model, and identifier conventions are unaffected.
>
> The content below is retained for historical context. Do not act on it for new work. JXA-retirement notes carry forward only as background; the new runtime does not call JXA at all.

## Why

Both transport pivots have separate motivations that arrived together.

**Transport.** JXA via `osascript -l JavaScript` forks a subprocess per Apple Event. Corpus-wide reads (graph audits, mirror sync, claim ledger construction in Phase 1) are dominated by that fork/exec cost rather than DT's actual work. PyObjC ScriptingBridge dispatches Apple Events in-process and returns typed Cocoa objects, removing the subprocess boundary and the per-call serialisation tax. See [00 Source Reconciliation](00-source-reconciliation.md) for the dated decision.

**MCP.** The community MCP at v1.9.0 is built on string-template JXA — it has the same fork/exec cost the rest of the system is shedding, plus a string-injection surface and the JXA quirk catalogue. Sitting on top of it would compound the problem we are trying to remove. The decision is to build `dt-pkim-mcp` as a Python+PyObjC MCP server using the official MCP SDK, sharing the same bridge/domain/commands stack as the CLI.

[10 MCP Extension Specification](10-mcp-extension-specification.md) is **superseded** by this doc.

## Layered structure

```
┌──────────────────────────────────────────────────────────────┐
│  Transports                                                  │
│    ├─ pkim.cli                (existing CLI)                 │
│    └─ pkim.mcp                (new MCP server, this WP)      │
├──────────────────────────────────────────────────────────────┤
│  Orchestration                                               │
│    └─ pkim.commands           (existing; thinning over time) │
├──────────────────────────────────────────────────────────────┤
│  Domain                                                      │
│    └─ pkim.domain             (pure Python, no DT coupling)  │
├──────────────────────────────────────────────────────────────┤
│  Bridge                                                      │
│    └─ pkim.bridge             (PyObjC ScriptingBridge only)  │
└──────────────────────────────────────────────────────────────┘
```

### Layer rules (binding)

1. **`pkim.bridge` is the only module that may import `ScriptingBridge`, `Foundation`, `AppKit`, or `objc`.** Everything else sees Python primitives and dataclasses.
2. **`pkim.domain` is pure Python.** It must be importable on a non-macOS host. It owns the data shapes (`KN`, `EV`, `RL`, `WikiLink`, `Claim`, classifications) and the validators.
3. **`pkim.commands` orchestrates.** It composes bridge reads/writes and domain types into operations. It does not parse Apple Event strings.
4. **Transports (`pkim.cli`, `pkim.mcp`) are thin.** They marshal arguments in, format results out. No logic. If a CLI command and an MCP tool diverge in behaviour, the divergence is a bug in `pkim.commands`.
5. **No layer skips downward.** A transport must not import `pkim.bridge` directly; it goes through `pkim.commands`. A command must not import `ScriptingBridge`; it goes through `pkim.bridge`.
6. **`pkim.jxa` is deprecated.** Every write-bearing command has migrated to `DTWriter`; the remaining importers are `profile.py` (DT `classify` / `compare` verbs not exposed by ScriptingBridge) and `reporting.py` (database open/close for restore-drill). The module emits `DeprecationWarning` on import. New code does not import it.

### Why these rules

Each layer is testable on its own:

- **`pkim.bridge`** integration-tests against a live DT (marker: `live`, opt-in via `PKIM_BRIDGE_LIVE=1`).
- **`pkim.domain`** unit-tests with no I/O and no PyObjC (marker: `unit`).
- **`pkim.commands`** unit-tests with a faked bridge (no DT required); integration-tests against scratch DT databases.
- **Transports** unit-test argument parsing and output formatting; live-test the round-trip through commands → bridge → DT.

Cross-layer leakage breaks at least one of those test surfaces. The rule exists because the cost of leakage is paid every time the audit suite runs.

## Module layout

```
src/pkim/
├── bridge/                    # PyObjC ScriptingBridge transport
│   ├── __init__.py            # public surface re-exports
│   ├── client.py              # SBApplication wrapper, DTBridge, probe()
│   ├── reads.py               # DTReader (search, get_record_*, get_body, get_record_at)
│   ├── writes.py              # DTWriter (custom metadata, body, name, comment,
│   │                          #   create_record, create_group, move, replicate,
│   │                          #   duplicate, delete)
│   ├── convert.py             # ObjC <-> Python coercion helpers
│   ├── applescript.py         # NSAppleScript fallback for verbs SB cannot reach
│   └── errors.py              # BridgeError hierarchy
├── domain/                    # pure-Python data model (importable on any host)
│   ├── ids.py                 # PKIMId, DTUUID, parser
│   ├── records.py             # RecordHandle frozen dataclass
│   ├── edges.py               # RelationType, EVIDENCE_REQUIRED_RELATIONS
│   ├── classification.py      # PROPERTY / INDEX-POINTER / DERIVED enum
│   ├── wikilinks.py           # WikiLink parser with section context
│   ├── claims.py              # Claim parser for ## Claims blocks
│   ├── fields_registry.py     # canonical field → classification map
│   └── headers.py             # YAML <-> MMD header conversion (WP0.5 migration)
├── mirror/                    # analytical surface (SQLite-backed graph)
│   ├── graph.py               # MirrorGraph schema + build_mirror_graph
│   ├── audits.py              # corpus-level SQL detectors
│   ├── propagation.py         # EV supersession -> KN needs-review
│   └── writeback.py           # Claim_Backed compute + DTWriter write-back
├── commands/                  # CLI orchestration (migrated to bridge)
├── mcp/                       # dt-pkim-mcp server (FastMCP stdio)
│   ├── server.py              # entry point (console script: dt-pkim-mcp)
│   ├── tools.py               # bridge_probe, search_records, audit_discipline
│   └── resources.py           # placeholder; resources land alongside Phase 1 follow-ons
├── cli.py                     # pkim CLI entry point
├── jxa.py                     # deprecated; emits DeprecationWarning on import
└── runtime.py                 # run-id and run-manifest helpers
```

## MCP framework choice

The MCP server is built on the official **`mcp` Python SDK** (the same package that powers Anthropic's reference servers). Key constraints:

- **stdio transport** for local Claude Code and Codex CLI integration. The HTTP+SSE transport is out of scope for the local-first stance.
- **Tools are typed.** Tool input schemas are derived from Python type annotations on the tool functions; FastMCP synthesises the JSON schema internally. Pydantic models can be introduced for richer input validation when a tool's surface grows, but the default form is type-annotated functions.
- **Resources** expose corpus snapshots, audit reports, and run manifests as MCP resources so a client can list and fetch them without invoking a tool. (Resource registrations land alongside Phase 1 follow-on work; the stub `pkim/mcp/resources.py` reserves the registration entry point.)
- **No business logic in `pkim.mcp`.** Every tool is a thin wrapper over a function already used by the CLI or the mirror layer.

The MCP server identifier is `dt-pkim-mcp`. The console script `dt-pkim-mcp = pkim.mcp.server:main` is registered in `pyproject.toml`; running it spawns the stdio server with `bridge_probe`, `search_records`, and `audit_discipline` registered as tools.

## Type safety

The combined surface is fully typed:

- **`pkim.bridge`** is typed with `Any` at the PyObjC boundary and concrete types elsewhere. Conversion helpers in `bridge/convert.py` are the only place `Any` propagates upward.
- **`pkim.domain`** is fully typed using `dataclass(frozen=True)`, `NewType` for ID types, and `Literal[...]` for closed vocabularies (relation types, edge classes, classifications).
- **`pkim.commands`** consumes domain types directly. JSON output goes through `dataclasses.asdict` or model `model_dump()` calls; no hand-rolled dict construction.
- **`pkim.mcp`** uses Pydantic models for tool I/O. Output models mirror domain dataclasses or wrap them.
- **mypy** runs over the entire `src/pkim/` tree, with the PyObjC frameworks listed in `tool.mypy.overrides`.

## Test strategy

- Unit tests (`@pytest.mark.unit`) cover `bridge` with fakes, `domain` end-to-end, `commands` with a faked bridge, and transport argument parsing.
- Integration tests (`@pytest.mark.integration`) — reserved for future scratch-DT scenarios.
- Live tests (`@pytest.mark.live`, opt-in via `PKIM_BRIDGE_LIVE=1`) cover the real bridge against the local DT install. PKIM_Pilot is the canonical live test corpus.
- Benchmark harness — **not built**. WP0.6c was skipped on user direction; typed-and-functional was prioritised over measured speedup.

## Migration sequence

The work packages are defined in [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) §Phase 0 §WP0.6 sub-sequence. Summary:

| WP | Status | Scope |
| --- | --- | --- |
| WP0.6a | **done** 2026-05-16 | `bridge/client.py`, `commands/bridge.py`, `pkim bridge probe`, unit + live tests |
| WP0.6b | **done** 2026-05-16 | `bridge/reads.py` typed read primitives (search, record fetch, group enumerate, body) |
| WP0.6c | **skipped** 2026-05-16 | benchmark skipped per user direction; typed-and-functional supersedes measured speedup |
| WP0.6d | **done** 2026-05-17 | read commands migrated: `list-inbox`, `probe-capabilities`, `health-check`, `metadata-overview`, `sweep-inbox`, `queue-metrics`, `graph-audit`, `extract-text` |
| WP0.6e | partial | `pkim.domain` types in use across ported commands; full sweep alongside WP0.6g |
| WP0.6f | stub done 2026-05-16; full pending | `mcp/server.py` exposes `bridge_probe`, `search_records`, `audit_discipline`; resources and remaining tools land alongside Phase 1 |
| WP0.6g | **done** 2026-05-17 | writes ported across `apply_metadata`, `create_note`, `safe_file`, `update_note`, `ensure_group_path`, `workspace.push_batch`, `mirror`, `sweep_inbox`, `metadata_overview`, `search_notes`. `DTWriter` gained `set_name`/`set_comment`/`create_record`/`create_group`/`move_record`/`replicate_record`/`duplicate_record`/`delete_record`. Remaining JXA importers: `profile.py` (classify/compare) and `reporting.py` (restore-drill open/close). |
| WP0.6h | pending | retire `jxa.py` and `scripts/pkim-devonthink-helper` — final two callers (`profile.py`, `reporting.py`) must migrate first |

Open transport item not yet a WP: DEVONthink's `classify` and `compare` verbs are not directly exposed by PyObjC ScriptingBridge (`app.classify_` etc. don't resolve). `profile.py` retains the JXA path for those two verbs until either `performSelector_withObject_` plumbing or a small AppleScript helper bridges the gap.

## What this supersedes

- [10 MCP Extension Specification](10-mcp-extension-specification.md) — the "wrap and extend the vendored community MCP" stance is replaced by "own the MCP via the bridge."
- The legacy JXA fallback at `src/pkim/jxa.py` — marked deprecated (emits `DeprecationWarning` on import). All write-bearing commands have migrated to `DTWriter`. Two callers remain (`profile.py` for classify/compare, `reporting.py` for database open/close); deletion follows when both migrate (WP0.6h).

## Open questions (track here, not in code comments)

- **Deep record counts.** *Resolved.* PyObjC ScriptingBridge exposes DT's `records` element as immediate root children only. `DTReader.search` performs a recursive walk with dedupe-by-UUID and is the deep-enumeration primitive. The probe still reports `root_item_count` to avoid implying otherwise.
- **Write gating in MCP.** Live once write tools land on the MCP surface (post-WP0.6f). The convention: a mutating tool refuses unless `PKIM_ALLOW_PRODUCTION_WRITES=true` is set in the server's environment, mirroring the CLI's `--live` flag. None of the current three MCP tools mutate, so the gate is not yet exercised.
- **Resource vs tool boundary.** Default stands: snapshots and reports are resources (cacheable, listable); operations are tools. Stub at `pkim/mcp/resources.py` reserves the registration entry point; first concrete resource lands when the periodic-claim-audit run-artefact contract from Workflow 7 is wired into the MCP surface.
- **DT classify / compare verbs.** PyObjC ScriptingBridge does not expose them via selector resolution (verified empirically — `getattr(app, 'classify_')` is False). `pkim.bridge.applescript.run_applescript` is the in-process NSAppleScript fallback; `profile.py` will switch to it when next touched.
- **Database lifecycle verbs.** `reporting.py`'s restore-drill needs DT's `open database` / `close database` verbs. They aren't yet exposed as bridge primitives. A `DTBridge.open_database(path)` / `close_database(database)` pair on top of NSAppleScript would close the last JXA caller.
