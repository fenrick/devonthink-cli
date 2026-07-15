# Repo Operating Model

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/07-runtime.md](../design/07-runtime.md) for how skills compose DT MCP.

## Purpose

This repository is the working area for a DEVONthink-centred knowledge operating system.

It is not just a source-code repository. It is where the system's design contracts, operating rhythm, agent skills, deterministic scripts, prompts, schemas, tests, run evidence, and portable mirrors are managed together.

It is not a dump of raw source materials and it is not a replacement for DEVONthink itself. DEVONthink is the canonical control plane for records, metadata-in-context, item links, groups, queues, and native notes. This repo is the operational surface that makes that environment inspectable, repeatable, and safe to operate with agents.

It is the shared execution surface for both Codex CLI and Claude Code. Runtime-specific phrasing can differ; repository rules cannot.

## Mental Model

The folder has three jobs:

1. **Define the operating system** — design docs describe the information model, workflow model, safety model, and DEVONthink topology.
2. **Run the operating system** — skills, prompts, scripts, and commands turn the design into bounded repeatable actions.
3. **Audit the operating system** — tests, run artifacts, dashboards, graph audits, and mirror exports show what happened and what needs attention.

The central boundary is:

| Surface | Role |
| --- | --- |
| DEVONthink | Canonical evidence, knowledge notes, relation notes, metadata, queues, item links |
| `docs/design/` | Evergreen contract for what the system is |
| `docs/ops/` | How the system is run day to day |
| `skills/` | Agent methods and guardrails for bounded work |
| `scripts/` and `src/pkim/` | Deterministic execution surface |
| `runs/`, `logs/`, `tmp/` | Local evidence of work, diagnostics, and scratch state |
| `exports/knowledge-mirror/` | Portable mirror, not canonical state |

## Operating Rhythm

The day-to-day cadence lives in [operating-rhythm.md](operating-rhythm.md).

Use it to decide what to run at the start of a work session, how to process inbox material, when to run graph checks, when to sync mirrors, and what to inspect before scaling the corpus.

## Tracked vs Untracked

### Tracked

- evergreen design docs
- operational docs
- runtime entry files for supported agent environments
- environment contract and example configuration
- project skill contracts
- scripts and adapters
- reusable prompts
- schemas
- tests
- intentionally committed export mirrors and manifests

### Untracked

- raw source briefs and other private input material in `inputs/`
- temporary run state in `runs/`, `logs/`, and `tmp/`
- local credentials and machine-specific config

## Change Discipline

- If a code change depends on a design change, update both in the same branch.
- If a design decision changes materially, update the design register rather than leaving the delta in commit history alone.
- Prefer multiple small commits over one opaque blob.
- If a workflow changes, update the relevant skill, command docs, and operating runbook together.
- If an agent action writes to DEVONthink, leave a run artifact and make sure the deterministic command surface can explain what happened.

## Navigation

- Project landscape: [../../README.md](../../README.md)
- Operating rhythm: [operating-rhythm.md](operating-rhythm.md)
- Runtime contract: [agent-runtime-surface.md](agent-runtime-surface.md)
- Local environment: [local-environment.md](local-environment.md)
- Intake workflow: [intake-runbook.md](intake-runbook.md)
- Capability probe: [capability-probe.md](capability-probe.md)
