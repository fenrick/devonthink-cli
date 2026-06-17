# Automation Surface

## Purpose

This document is only the orientation page for the automation part of the design pack.

It answers one question:

What belongs in the automation surface, and which detailed document defines each part?

It does not try to restate the technical design, the MCP extension plan, the runbooks, or the implementation backlog.

## Automation Surface Boundary

The automation surface is the local system that lets Claude Code and Codex CLI work against DEVONthink safely and repeatably.

The approved automation posture is CLI/JXA-first: a shared local command surface backed by local helpers, with MCP treated as optional transport where it helps.

It includes:

- shared local command wrappers
- optional MCP transport where useful
- local helper scripts for gaps and safety controls
- run logging and manifests
- mirror export logic
- policy checks for metadata mutation and filing

It does not include:

- the DEVONthink information model itself
- the native note and metadata specification
- the implementation backlog
- generic repo hygiene rules

## Detailed Documents

| Topic | Canonical document |
| --- | --- |
| Native DEVONthink operating behaviour | [07 DEVONthink Operating Model](07-devonthink-operating-model.md) |
| Record, metadata, and note structures | [08 Record And Note Specification](08-record-and-note-specification.md) |
| End-to-end automation service design | [09 Automation Architecture](09-automation-architecture.md) |
| MCP uplift and extension plan | [10 MCP Extension Specification](10-mcp-extension-specification.md) |
| Runtime skills and runbooks | [11 Agent Skills And Runbooks](11-agent-skills-and-runbooks.md) |
| Repo and work-surface operating contract | [12 Project Hygiene And Work Surface](12-project-hygiene-and-work-surface.md) |
| Capability checkpoints | [13 Capability And MVP Map](13-capability-and-mvp-map.md) |
| Build backlog | [14 Implementation Work Packages](14-implementation-work-packages.md) |

## Controlling Rules

- DEVONthink remains the canonical store.
- Claude Code and Codex CLI use the same local command surface.
- All write paths must support dry-run and post-write verification.
- Indexed items are treated as higher-risk than imported items.
- The export mirror is portable, not canonical.

## Reading Order

Read in this order if the task is about automation:

1. this document
2. [09 Automation Architecture](09-automation-architecture.md)
3. [10 MCP Extension Specification](10-mcp-extension-specification.md)
4. [11 Agent Skills And Runbooks](11-agent-skills-and-runbooks.md) to choose the relevant skill, then load only that skill's `SKILL.md`
5. [13 Capability And MVP Map](13-capability-and-mvp-map.md) or [14 Implementation Work Packages](14-implementation-work-packages.md), depending on whether the question is readiness or build sequencing
