# System Topology

## Purpose

This document defines where the major PKIM surfaces live and what boundaries separate them.

Use it when deciding whether something belongs in DEVONthink, the filesystem, the export mirror, or the automation layer. Do not use it for metadata fields, note templates, or workflow steps.

## Topology Summary

The system has four practical layers:

1. DEVONthink databases for canonical evidence and knowledge.
2. Local filesystem working roots for indexed evidence where external editability matters.
3. Export mirrors and operational artifacts in this repository.
4. A local automation service that mediates MCP access, policy, logging, and write controls.

This document is about placement and boundaries only.

It does not define:

- detailed DEVONthink operating behaviour
- metadata or note structure
- repo file contracts
- automation command design

## Recommended Databases

| Database | Role | Content policy |
| --- | --- | --- |
| `PKIM-Knowledge` | Canonical note graph | Import-only Markdown knowledge notes, relation notes, templates, curated annotation notes |
| `PKIM-Evidence-Personal` | Personal evidence | Import by default; selectively index active local working folders |
| `PKIM-Evidence-Work` | Work and shared evidence | Index parent folders from local sync roots when policy requires; import only where allowed and useful |
| `PKIM-Evidence-Server` | NAS or mounted-share evidence | Prefer import unless the mount is stable and continuously available |
| `PKIM-Pilot` | Scratch and validation surface | Disposable records for schema, automation, and write tests |

## Storage Rules

- DEVONthink database packages live on local storage, not inside cloud-synced folders.
- Index parent folders, not scattered individual files.
- Do not assume indexed content will behave cleanly on mobile or after external moves.
- Keep the knowledge mirror outside database packages and outside ephemeral temp areas.

## Trust Boundaries

### Native boundary

DEVONthink remains the source of truth for its records, links, versions, and metadata. External tools must read or mutate it only through approved adapters.

### Export boundary

Export mirrors are copies. They can be indexed back into DEVONthink or processed by external tools, but they do not outrank the originating DEVONthink records.

### Automation boundary

The local automation layer is the only place that should combine MCP calls, AppleScript/JXA helpers, policy checks, and logging. Do not let desktop AI clients write directly to production libraries.

## Detailed Companions

- For DEVONthink operating behaviour, use [07 DEVONthink Operating Model](07-devonthink-operating-model.md).
- For repo path and work-surface rules, use [12 Project Hygiene And Work Surface](12-project-hygiene-and-work-surface.md).
- For automation boundaries and command surfaces, use [04 Automation Surface](04-automation-surface.md) and [09 Automation Architecture](09-automation-architecture.md).
