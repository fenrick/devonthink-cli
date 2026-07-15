# PKIM Documentation Map

> **Runtime note (2026-07-15).** The current runtime is DEVONthink 4.3+'s in-app MCP server; skills compose its tools directly. See [design/24-dt-mcp-adoption.md](design/24-dt-mcp-adoption.md). Earlier docs frequently reference a PKIM-owned `pkim` binary or Python runtime — those are historical. Doc 24 §"Coexistence / replacement table" maps every retired `pkim <verb>` to its DT MCP replacement.

## Purpose

This folder is the map for operating PKIM as a knowledge operating system.

An operator or LLM should not need to read every document before acting. Start with the smallest layer that answers the current question, then load deeper contracts only when the task requires them.

## End-To-End Story

PKIM exists to turn incoming material into durable, linked, reviewable knowledge:

1. material arrives in DEVONthink
2. the inbox is swept and each record is profiled
3. metadata, tags, names, candidate notes, and candidate destinations are developed while the record is still reviewable
4. knowledge notes describe what the material means
5. relation notes make important graph edges explicit
6. graph checks find missing or weak connections
7. records are renamed and filed only after semantic enrichment is complete
8. mirrors, run artifacts, and tests make the system portable and auditable

The LLM layer performs judgement through skills. DEVONthink's in-app MCP server (v4.3+) performs the bounded deterministic reads, writes, validation, and extraction. DEVONthink remains canonical for records, notes, metadata, queues, groups, and item links.

## Progressive Disclosure Contract

Every operating document should answer only the level it owns:

| Level | It should explain | It should not duplicate |
| --- | --- | --- |
| Map | where to start and what to load next | command details or schema tables |
| Operating guide | why the workflow exists and how to run it | low-level implementation internals |
| Design contract | stable model, authority, safety, and state rules | session-by-session procedure |
| Skill | agent judgement, sequencing, stop rules, and output shape | command implementation details |
| Script or command doc | inputs, outputs, artifacts, and failure modes | LLM reasoning method |

If two pages need the same fact, one page owns the fact and the other links to it. Repeating canonical metadata, workflow order, or command behaviour in several places is drift waiting to happen.

## Context Layers

| Layer | Read when | Documents |
| --- | --- | --- |
| Orientation | You need to understand what this project is | [../README.md](../README.md), [ops/repo-operating-model.md](ops/repo-operating-model.md) |
| Operating rhythm | You need to run a session or decide what to do next | [ops/operating-rhythm.md](ops/operating-rhythm.md), [ops/README.md](ops/README.md) |
| Workflow method | You need to process records or notes | [design/05-workflows.md](design/05-workflows.md), [ops/intake-runbook.md](ops/intake-runbook.md) |
| Skill method | You need agent behaviour and safety boundaries | [../skills/README.md](../skills/README.md), [design/11-agent-skills-and-runbooks.md](design/11-agent-skills-and-runbooks.md) |
| System contract | You need authoritative model or metadata detail | [design/README.md](design/README.md), [design/08-record-and-note-specification.md](design/08-record-and-note-specification.md) |
| Implementation detail | You need to change how skills call DT MCP | [design/24-dt-mcp-adoption.md](design/24-dt-mcp-adoption.md), the relevant `skills/*/SKILL.md` |

## Canonical Detail Owners

| Detail | Canonical owner |
| --- | --- |
| Folder purpose and repo role | [ops/repo-operating-model.md](ops/repo-operating-model.md) |
| Daily operating cadence | [ops/operating-rhythm.md](ops/operating-rhythm.md) |
| Inbox-to-graph workflow | [design/05-workflows.md](design/05-workflows.md), [ops/intake-runbook.md](ops/intake-runbook.md) |
| Metadata, note, relation, and mirror schema | [design/08-record-and-note-specification.md](design/08-record-and-note-specification.md) |
| Skill catalogue and skill/script boundary | [../skills/README.md](../skills/README.md), [design/11-agent-skills-and-runbooks.md](design/11-agent-skills-and-runbooks.md) |
| Command implementation architecture | [design/09-automation-architecture.md](design/09-automation-architecture.md) |
| Historical build state and backlog | [ops/build-plan.md](ops/build-plan.md) |

## Task-Based Loading

| Task | Start with | Load next only if needed |
| --- | --- | --- |
| Understand the project | [../README.md](../README.md) | [ops/repo-operating-model.md](ops/repo-operating-model.md), [design/README.md](design/README.md) |
| Start a work session | [ops/operating-rhythm.md](ops/operating-rhythm.md) | [ops/capability-probe.md](ops/capability-probe.md), [ops/local-environment.md](ops/local-environment.md) |
| Process inbox records | [ops/intake-runbook.md](ops/intake-runbook.md) | [design/05-workflows.md](design/05-workflows.md), `skills/dt-sweep-inbox`, `skills/dt-profile-record` |
| Create knowledge notes | `skills/dt-build-knowledge-note` | [design/08-record-and-note-specification.md](design/08-record-and-note-specification.md), [design/11-agent-skills-and-runbooks.md](design/11-agent-skills-and-runbooks.md) |
| Create relation notes | `skills/dt-build-relation-note` | [design/05-workflows.md](design/05-workflows.md), [design/08-record-and-note-specification.md](design/08-record-and-note-specification.md) |
| File or move records | `skills/dt-safe-file` | [ops/intake-runbook.md](ops/intake-runbook.md), [design/07-devonthink-operating-model.md](design/07-devonthink-operating-model.md) |
| Audit graph health | `skills/dt-audit-graph-corpus` | [ops/operating-rhythm.md](ops/operating-rhythm.md), [design/05-workflows.md](design/05-workflows.md) |
| Debug a failed write | `skills/dt-recover-failed-write` | [ops/operating-rhythm.md](ops/operating-rhythm.md), [design/06-operations-and-safety.md](design/06-operations-and-safety.md) |
| Change code | [design/09-automation-architecture.md](design/09-automation-architecture.md) | [design/14-implementation-work-packages.md](design/14-implementation-work-packages.md), relevant tests |

## Reading Rule

Load broad context first, then narrow contracts:

1. read the orientation paragraph or table
2. identify the workflow or skill
3. load only the relevant skill/runbook
4. load design specs only when changing contracts or resolving ambiguity
5. load implementation files only when editing code

If a task requires reading the whole docs tree, the documentation structure has failed.
