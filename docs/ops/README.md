# Operations Index

> **Runtime note (2026-07-15).** DEVONthink 4.3+'s in-app MCP server is the runtime. Any `pkim <verb>` reference in these ops docs (or in the skills) is historical — see [../design/07-runtime.md](../design/07-runtime.md) for how skills compose DT MCP.

## Purpose

`docs/ops/` explains how to run the PKIM knowledge operating system.

Use these docs when you need operating cadence, environment setup, safety checks, runbooks, or evidence that the system is healthy enough to keep processing material.

For the full documentation context map, start at [../README.md](../README.md).

## Read Order

The docs are intentionally layered. Do not start with implementation detail unless you already understand the layer above it.

1. **Why this exists:** [repo-operating-model.md](repo-operating-model.md) explains what the project folder is, why it exists beside DEVONthink, and how it acts as a working surface.
2. **How to operate it:** [operating-rhythm.md](operating-rhythm.md) explains the regular session, batch, graph, and mirror cadence.
3. **How agents share the surface:** [agent-runtime-surface.md](agent-runtime-surface.md) explains the shared contract for Codex CLI and Claude Code.
4. **How the machine is configured:** [local-environment.md](local-environment.md) explains environment variables and local paths.
5. **How material enters the system:** [intake-runbook.md](intake-runbook.md) explains the inbox-to-enrichment workflow.

## Progressive Disclosure Rule

Every operating page should answer these questions in this order:

1. Why does this exist?
2. What state or decision does it control?
3. What should the operator or agent do?
4. Which DT MCP tool or skill supports the work?
5. What evidence proves it worked?

If a doc only lists tool calls, it is a reference page, not an operating page.

## Operating Docs

| Document | Use it for |
| --- | --- |
| [repo-operating-model.md](repo-operating-model.md) | Folder purpose, tracked/untracked surfaces, change discipline |
| [operating-rhythm.md](operating-rhythm.md) | Daily/session rhythm, queue checks, graph checks, mirror rhythm, stop conditions |
| [agent-runtime-surface.md](agent-runtime-surface.md) | Runtime-neutral rules for Codex and Claude |
| [local-environment.md](local-environment.md) | Required environment settings |
| [capability-probe.md](capability-probe.md) | Runtime readiness checks via DT MCP |
| [intake-runbook.md](intake-runbook.md) | Inbox sweep, profile, metadata, enrichment, filing |
| [smart-groups-setup.md](smart-groups-setup.md) | DEVONthink queue/smart-group setup |
| [setup-checklist.md](setup-checklist.md) | Initial DEVONthink setup |
| [restore-drill.md](restore-drill.md) | Backup and restore evidence |
| [compatibility-matrix.md](compatibility-matrix.md) | Local version and feature compatibility |

## Minimal Context Sets

| Situation | Read these only |
| --- | --- |
| Starting a session | [operating-rhythm.md](operating-rhythm.md), [capability-probe.md](capability-probe.md) |
| Processing inbox material | [intake-runbook.md](intake-runbook.md), [operating-rhythm.md](operating-rhythm.md) |
| Checking whether the system is healthy | [operating-rhythm.md](operating-rhythm.md), [capability-probe.md](capability-probe.md), [restore-drill.md](restore-drill.md) if scaling |
| Understanding folder purpose | [repo-operating-model.md](repo-operating-model.md) |
| Changing runtime rules | [agent-runtime-surface.md](agent-runtime-surface.md), [local-environment.md](local-environment.md) |

## Normal Session Preflight

Call two DT MCP tools before any meaningful work:

- `mcp__devonthink__is_running`
- `mcp__devonthink__get_databases`

Optionally follow up with `list_custom_metadata_fields` to confirm the schema is intact. That's the equivalent of the retired `pkim health-check` and `pkim probe-capabilities`.

Writes are gated by DEVONthink's own settings + per-record `Exclude from AI` flags. There is no PKIM-owned write gate.
