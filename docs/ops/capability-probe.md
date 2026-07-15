# Capability Probe

## Purpose

Confirm the local runtime surface is coherent before any automation acts on live databases.

**Rule: no agent session may issue writes without a passing probe in the same session.**

Since the runtime is now DEVONthink 4.3+'s in-app MCP server (see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md)), the "probe" is two DT MCP calls that any skill can make cheaply.

## Preflight

```
mcp__devonthink__is_running
mcp__devonthink__get_databases
```

Expected outcomes:

| Check | Passes when |
|---|---|
| DEVONthink installed | `is_running` returns without error |
| DEVONthink running | `is_running` returns `{running: true}` |
| Required databases open | `get_databases` returns entries whose `name` matches the required set (`PKIM-Knowledge`, `PKIM-Pilot`, at least one `PKIM-Evidence-*`) |
| Not writing to a cloud-synced database | none of the required databases point at an iCloud path — check `get_databases` results |

Optional deeper probe:

```
mcp__devonthink__list_custom_metadata_fields
```

Confirms the canonical metadata schema (`PKIM_ID`, `DocRole`, `Review_State`, `Relation_Type`, etc.) is defined in DT. If a required field is missing, the metadata-writing skills will fail; better to catch it here.

## Write-gate posture

DEVONthink itself is the write gate. Two mechanisms:

1. **Per-database exclusion.** `Exclude from Chat & MCP` in the database properties panel blocks a whole database from AI access. Encrypted / revision-proof databases have this enabled by default.
2. **Per-record exclusion.** The `Exclude from AI` flag on any record makes DT MCP refuse to operate on it. `search_records`, `classify_record`, `find_similar_records`, and the link-traversal tools filter it out of results too.

There is no PKIM-owned override. If a workflow needs to touch a `-excluded` record, the human toggles the flag off in DT first.

## When the probe fails

| Symptom | What to do |
|---|---|
| `is_running` returns `{running: false}` | Open DEVONthink and re-run |
| `get_databases` missing a required entry | Open the missing database in DEVONthink and re-run |
| `list_custom_metadata_fields` missing required fields | Run the `dt-bootstrap-pkim` skill (or manually add the fields per [compatibility-matrix.md](compatibility-matrix.md)) |
| DT MCP not responding at all | Check DT's Settings > AI > MCP panel — the server may be stopped or restart may be needed |

## What retired

The old `pkim probe-capabilities` and `pkim health-check` verbs and their run-manifest artefacts are gone. The check is now stateless — no `runs/<run-id>/capability-manifest.json`, no local caching. Every session re-probes cheaply via DT MCP.
