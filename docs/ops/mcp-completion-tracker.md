# MCP Completion Tracker

Status key: `[ ]` pending · `[~]` in progress · `[x]` done · `[-]` skipped

**Last updated: 2026-05-18 — all 7 tasks complete. 28 tools registered. Build green.**

---

## Priority 0 — BridgeSession (warm connection + cache)

Prerequisite for efficient multi-tool agent sessions. All tools must call
`get_session()` instead of `DTBridge.connect()`.

- [ ] Create `src/pkim/bridge/session.py`
  - [ ] `BridgeSession` class: holds single `DTBridge` + `DTReader` + `DTWriter`
  - [ ] `get_session(bundle_id=DT_BUNDLE_ID) -> BridgeSession` — module-level singleton, lazy-constructed
  - [ ] `require_running()` check per call, not per process start
  - [ ] Record cache: `dict[str, RecordHandle]` keyed by DT UUID, TTL 60 s
  - [ ] Database list cache: `list[DatabaseProbe]`, TTL 30 s
  - [ ] `invalidate(uuid: str)` — evicts record from cache, clears db-list cache on structural writes
  - [ ] Unit tests in `tests/test_bridge_session.py`
- [ ] Update `tools.py` to use `get_session()` in `search_records` and `audit_discipline`

---

## Priority 1 — Read Tools (9 tools, zero write risk)

All backed by existing `commands/` modules. Wire via `get_session()`.

- [ ] `list_inbox` → `commands/inbox.py`
- [ ] `health_check` → `commands/health.py`
- [ ] `metadata_overview` → `commands/metadata_overview.py`
- [ ] `graph_audit` → `commands/graph.py`
- [ ] `queue_metrics` → `commands/graph.py`
- [ ] `extract_text` → `commands/extract_text.py`
- [ ] `search_notes` → `commands/search_notes.py`
- [ ] `deep_profile` → `commands/deep_profile.py`
- [ ] `probe_capabilities` → `commands/probe.py`

---

## Priority 2 — Test Expansion

- [ ] `test_register_tools_all_tools_present` — assert every expected tool in `server.list_tools()`
- [ ] `test_session_reuse_across_tool_calls` — `DTBridge.connect()` called exactly once across two tool calls
- [ ] `test_record_cache_hit` — second identical search served from cache
- [ ] `test_record_cache_ttl_expiry` — expired TTL triggers re-query
- [ ] Per read-tool unit tests (faked bridge, assert `ok=True` + key fields)
- [ ] `tests/test_mcp_integration.py` (`@pytest.mark.live`) — real DT smoke tests
  - [ ] `test_list_inbox_live`
  - [ ] `test_search_then_audit_live`
  - [ ] `test_session_warmth_live` (second `bridge_probe` ≤ 50 ms)
- [ ] `tests/test_mcp_stdio.py` (`@pytest.mark.live`) — subprocess stdio round-trip

---

## Priority 3 — Write Tools (11 tools, gated)

Each must: check `PKIM_ALLOW_PRODUCTION_WRITES`, support `dry_run` default `True`,
call `session.invalidate(uuid)` before returning.

- [ ] `apply_metadata` → `commands/apply_metadata.py`
- [ ] `create_knowledge_note` → `commands/create_note.py`
- [ ] `create_relation_note` → `commands/create_note.py`
- [ ] `safe_file` → `commands/safe_file.py` (enforce `action=move`)
- [ ] `update_knowledge_note` → `commands/update_note.py`
- [ ] `update_relation_note` → `commands/update_note.py`
- [ ] `ensure_group_path` → `commands/ensure_group_path.py`
- [ ] `sweep_inbox` → `commands/sweep_inbox.py`
- [ ] `sync_metadata` → `commands/sync_metadata.py`
- [ ] `sync_mirror` → `commands/mirror.py`
- [ ] `repair_rl_endpoints` → `commands/repair_rl_endpoints.py`
- [ ] Write-gate unit tests (dry-run default, blocked-without-env)
- [ ] Cache-invalidation unit tests per write tool

---

## Priority 4 — Admin / Migration Tools (4 tools, destructive — `dry_run=True` default)

- [ ] `migrate_mmd_headers` → `commands/migrate_mmd.py`
- [ ] `migrate_evidence_links` → `commands/migrate_evidence_links.py`
- [ ] `migrate_claims_to_nodes` → `commands/migrate_claims_to_nodes.py`
- [ ] `workspace_push_batch` → `commands/workspace.py`

---

## Priority 5 — MCP Resources (`resources.py`)

- [ ] `register_resources(server)` called from `server.py`
- [ ] `pkim://runs/latest` — most recent run manifest JSON
- [ ] `pkim://audits/discipline/{database}` — last discipline audit report
- [ ] `pkim://mirror/graph` — mirror graph summary

---

## Priority 6 — WP0.6h JXA Retirement

Unblocked once priorities 1–3 are complete.

- [ ] `profile.py` — migrate `classify`/`compare` to `pkim.bridge.applescript.run_applescript()`
- [ ] `reporting.py` — migrate DB open/close; add `DTBridge.open_database()` / `close_database()` using NSAppleScript
- [ ] Delete `src/pkim/jxa.py`
- [ ] Remove `scripts/pkim-devonthink-helper` + `pyproject.toml` entry-point

---

## Testing Matrix

| Layer | Tool | Gate | File |
|---|---|---|---|
| Unit (no DT) | all tools | monkeypatched bridge | `test_mcp_server.py` |
| Unit (session) | BridgeSession | monkeypatched bridge | `test_bridge_session.py` |
| Integration (live DT) | read tools | `PKIM_BRIDGE_LIVE=1` | `test_mcp_integration.py` |
| stdio round-trip | full stack | `PKIM_BRIDGE_LIVE=1` | `test_mcp_stdio.py` |

---

## Design Constraints (binding)

- `pkim.mcp` must not import `pkim.bridge` directly — go through `pkim.commands` or `get_session()`.
  - Exception: `get_session()` is the bridge session accessor and is intentionally exposed to tools.
- Mutating tools refuse unless `PKIM_ALLOW_PRODUCTION_WRITES=true` is in the server environment.
- `safe_file` must enforce `action=move`, never `replicate` (see feedback: dt.replicate creates duplicates).
- All tool outputs are `{"ok": bool, ...}` — never raise through FastMCP.
- Cache invalidation is mandatory before a write tool returns.
