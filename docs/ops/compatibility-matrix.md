# Compatibility Matrix

## Purpose

This tracked document is the release gate for runtime and automation compatibility.

Live write enablement is blocked until this matrix is current.

---

## Runtime Versions

| Component | Value | Status | Last validated |
|---|---|---|---|
| macOS version | `26.5` | validated against target install | `2026-04-26` |
| DEVONthink version | `4.1.1` | validated against target install | `2026-04-26` |
| `pkim` runtime | Swift binary at `pkim-binary/` (Swift 6.0+, ArgumentParser 1.3+) | validated against target install | `2026-05-20` |
| External MCP transport | DT 4.3 Herschel now ships its own MCP server; PKIM does not require a vendored MCP. Coexistence path TBD (see doc 24 once written). | external dependency | _open_ |
| target install class | `4.1` | baseline target | `2026-04-18` |

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

## Approved Command List

After the CLI-first pivot (doc 22) the approved command surface is the Swift `pkim` binary. Full contract: [docs/design/23-swift-pkim-binary.md](../design/23-swift-pkim-binary.md). The 25-verb surface is treated as one validated unit — `swift test` exercises 70 unit + offline-cache tests against the binary; `PKIM_BRIDGE_LIVE=1 swift test` runs the live-DT benches against `PKIM-Pilot`.

| Verb class | Verbs | Last validated |
|---|---|---|
| Reads | `get`, `resolve`, `list`, `search`, `body`, `aliases`, `tags`, `file-path`, `mirror-of` | `2026-05-20` |
| Atomic writes | `set-metadata`, `set-tags`, `set-name`, `set-body`, `move`, `create-group`, `create-note` | `2026-05-20` |
| Auxiliary | `mint-id`, `extract-text`, `probe-capabilities`, `health-check` | `2026-05-20` |
| Setup (PKIM-bootstrap) | `setup-database`, `verify-database`, `verify-smart-groups`, `fix-smart-groups`, `install-templates` | `2026-05-20` |

**Legacy AppleScript surface:** the five PKIM-bootstrap AppleScripts under `scripts/` retired with the verb ports — `setup-database`, `verify-database`, `verify-smart-groups`, `fix-smart-groups`, and `install-templates` are now native verbs. The retirement table is in [doc 22 §Retirement inventory](../design/22-cli-first-atomic-primitives.md).

**External MCP coexistence:** DEVONthink 4.3 Herschel ships its own MCP server. PKIM no longer requires a vendored MCP. The split between PKIM verbs (file-as-truth, atomic per-key metadata, run manifests, offline `.dt` cache reads) and DT MCP (DEVONthink-policy surface for hosts that want generic MCP access) needs a dedicated brief; tracked as "doc 24 — DT MCP coexistence" (not yet written).

---

## Scratch Test Status

| Test | Status | Last run |
|---|---|---|
| `pkim health-check` returns `ok` | `ok` | `2026-05-20` |
| `pkim verify-database PKIM-Pilot` returns `ok` | `ok` | `2026-05-20` |
| `pkim verify-smart-groups` returns `ok` | `ok` | `2026-05-20` |
| `pkim probe-capabilities` returns expected envelope | `ok` | `2026-05-20` |
| `swift test` (70 unit + offline-cache tests) | `ok` | `2026-05-20` |
| `PKIM_BRIDGE_LIVE=1 swift test` (live SB + bench suites) | `ok` | `2026-05-20` |
| Scratch write test against `PKIM-Pilot` via `set-metadata` | `ok` | `2026-05-20` |

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
