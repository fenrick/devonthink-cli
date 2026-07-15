# Compatibility Matrix

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces it.

## Purpose

This tracked document is the release gate for runtime and automation compatibility.

Live write enablement is blocked until this matrix is current.

---

## Runtime Versions

| Component | Value | Status | Last validated |
|---|---|---|---|
| macOS version | Sequoia (26.x) minimum | required for DT MCP server | `2026-07-15` |
| DEVONthink version | 4.3.2 (Herschel) | validated against target install | `2026-07-15` |
| Runtime | DEVONthink in-app MCP server (~65 tools) | validated via live probes on `PKIM-Pilot`: `set_record_custom_metadata mode="merge"` preserves untouched fields; `update_record_content` writes indexed on-disk files | `2026-07-15` |
| AI client | Any MCP-capable client (Claude Code, Codex CLI, etc.) | client-side dependency, not repo-side | `2026-07-15` |

---

## Database Inventory

| Database | Created | Path confirmed not cloud-synced | Last validated |
|---|---|---|---|
| `PKIM-Knowledge` | `[x]` | `[x]` | `2026-04-18` |
| `PKIM-Evidence-Personal` | `[x]` | `[x]` | `2026-04-18` |
| `PKIM-Evidence-Work` | `[x]` | `[x]` | `2026-04-18` |
| `PKIM-Evidence-Server` | `[x]` | `[x]` | `2026-04-18` |
| `PKIM-Pilot` | `[x]` | `[x]` | `2026-04-18` |

---

## Custom Metadata Fields

All 30 fields must be defined in DEVONthink Settings > Data > Custom Metadata before write automation is enabled.

| Field name | Type | Defined | Last validated |
|---|---|---|---|
| `PKIM_ID` | Text | `[x]` | `2026-04-18` |
| `DocRole` | Selection | `[x]` | `2026-04-18` |
| `Review_State` | Selection | `[x]` | `2026-04-18` |
| `Origin_URI` | Text | `[x]` | `2026-04-18` |
| `Origin_Last_Path` | Text | `[x]` | `2026-04-18` |
| `Source_Item` | Text | `[x]` | `2026-04-18` |
| `Target_Item` | Text | `[x]` | `2026-04-18` |
| `Relation_Type` | Selection | `[x]` | `2026-04-18` |
| `Mirror_Path` | Text | `[x]` | `2026-04-18` |
| `Content_SHA256` | Text | `[x]` | `2026-04-18` |
| `CreatedByMode` | Selection | `[x]` | `2026-04-18` |
| native `kind` property | Native | `[x]` | `2026-04-19` |
| `PrimaryTopic` | Text | `[x]` | `2026-04-18` |
| `LastProfiledAt` | Date | `[x]` | `2026-04-18` |
| `LastMirroredAt` | Date | `[x]` | `2026-04-18` |
| `LastRunID` | Text | `[x]` | `2026-04-18` |
| `EvidenceStatus` | Selection | `[x]` | `2026-04-18` |
| `CaptureType` | Selection | `[x]` | `2026-04-18` |
| `CanonicalSourceURL` | Text | `[x]` | `2026-04-18` |
| `NoteType` | Selection | `[x]` | `2026-04-18` |
| `KnowledgeStatus` | Selection | `[x]` | `2026-04-18` |
| `EvidenceCount` | Integer Number | `[x]` | `2026-04-18` |
| `RelationConfidence` | Text | `[x]` | `2026-04-18` |
| `RelationStatus` | Selection | `[x]` | `2026-04-18` |
| `Needs_OCR` | Boolean | `[x]` | `2026-04-18` |
| `Knowledge_Link_State` | Text | `[x]` | `2026-04-18` |
| `Relation_Gap_State` | Text | `[x]` | `2026-04-18` |
| `Indexed_Risk_State` | Text | `[x]` | `2026-04-18` |
| `Mirror_State` | Text | `[x]` | `2026-04-18` |
| `Automation_Last_Run_State` | Selection | `[x]` | `2026-04-18` |

---

## Approved Command Surface

The approved command surface is DEVONthink 4.3+'s in-app MCP server. Full doctrine: [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md). The tool set is what DEVONthink ships; the coexistence table there maps every retired `pkim <verb>` to its DT MCP equivalent.

Skills call DT MCP tools by name (e.g. `mcp__devonthink__get_record_properties`, `mcp__devonthink__set_record_custom_metadata`). There is no PKIM-owned CLI or runtime layer.

---

## Scratch Test Status

| Test | Status | Last run |
|---|---|---|
| `mcp__devonthink__is_running` returns `{running: true}` | `ok` | `2026-07-15` |
| `mcp__devonthink__get_databases` returns the required set | `ok` | `2026-07-15` |
| `mcp__devonthink__set_record_custom_metadata mode="merge"` preserves untouched fields (live probe on `PKIM-Pilot`) | `ok` | `2026-07-15` |
| `mcp__devonthink__update_record_content` writes on-disk indexed file (live probe with a `/tmp/pkim-probe/` file) | `ok` | `2026-07-15` |

---

## Version Interpretation

- `validated against target install` — safe basis for operational use
- `inferred from newer documentation` — not yet sufficient for live reliance
- `unvalidated` — design intent only

---

## Release Gate

No production-library write enablement until:

- All runtime version rows are populated and current
- All 30 metadata fields are marked defined
- Approved command list is explicit (from capability probe)
- Scratch test status is current
- Last validated dates are recent enough to trust
