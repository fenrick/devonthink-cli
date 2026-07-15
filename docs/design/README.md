# Design Register

## Purpose

This register decomposes the DEVONthink PKIM design into stable components, captures the evolution across the two source briefs, and defines the current evergreen target.

Use it to choose the smallest design contract needed for the current task. Do not read the whole design pack unless you are changing cross-cutting architecture.

## Current Position

- DEVONthink is the canonical control plane and system of record.
- Evidence and knowledge are separate object classes with different storage and automation rules.
- Native DEVONthink Markdown notes are canonical for knowledge; filesystem Markdown mirrors are exported for Git, tooling, and portability.
- The runtime is DEVONthink 4.3+'s in-app MCP server; skills compose its tools directly. See doc 24. (Earlier runtime stances — community MCP adapter, owned Python MCP server, PyObjC bridge, and a Swift CLI (`pkim`) — are recorded in docs 09, 10, 20, 22, and 23 for context and superseded.)
- Build work proceeds continuously, but capability is measured by MVP checkpoints rather than a staged rollout.
- The repo is a working knowledge operating-system surface: design, skills, scripts, prompts, schemas, tests, run evidence, and mirrors are coordinated here rather than treated as separate projects.

## Reading Model

The design pack is deliberately layered:

1. **Principles** explain why the system exists and what must not be violated.
2. **Models** explain what the system is made of.
3. **Workflows** explain how records move through the system.
4. **Safety and automation contracts** explain what agents and scripts may do.
5. **Implementation packages** explain how the current build reached the operating surface.

The design is not only for humans. It is also the top-level method specification for LLM-driven operation. The skills and commands are executable slices of this design.

## Minimal Design Context

Do not load the whole design pack by default. Use the smallest set that answers the current question.

| Need | Read |
| --- | --- |
| Principles and authority | `01-principles-and-decisions.md`, `00-source-reconciliation.md` only if reconciling old briefs |
| Information model | `03-information-model.md`, then `08-record-and-note-specification.md` for exact fields |
| Workflow behaviour | `05-workflows.md`, then relevant skill docs |
| DEVONthink structure | `07-devonthink-operating-model.md` |
| Safety and write policy | `06-operations-and-safety.md` |
| Automation runtime | `24-dt-mcp-adoption.md` (canonical); docs 22 and 23 are superseded but retained for reasoning history |
| Repo structure | `12-project-hygiene-and-work-surface.md` |

## Authority Model

- DEVONthink is authoritative for native records, metadata-in-context, item links, queues, and note state.
- The repo is authoritative for automation code, schemas, prompts, tests, logs, and export logic.
- The export mirror is authoritative only as a portability and publishing representation, never for in-app state.

## System Boundary

This is a document-and-link graph with structured relation notes. It is not a native property-graph database.

## Front-Door Capability Status

Use this as the single front-door capability table. If an operation is not clear here, the pack is underspecified.

| Operation | Native DEVONthink | Scriptable via AppleScript/JXA | Available in current local command surface | Requires extension |
| --- | --- | --- | --- | --- |
| search records and open local context | yes | yes | yes | no |
| read record content and item links | yes | yes | yes | no |
| run compare or classify for discovery | yes | yes | yes | no |
| inspect and work native queues | yes | yes | yes | no |
| create canonical knowledge notes | yes | yes | yes | no |
| create canonical relation notes with full contract | yes | yes | yes | no |
| mutate canonical custom metadata safely | partial | yes | yes | no |
| move imported records with policy checks | partial | yes | yes | no |
| move indexed records safely | no | partial and policy-bound | no | yes |
| replicate records with policy checks | partial | yes | yes | no |
| export mirror files and manifests | partial | yes | yes | no |
| emit structured run manifests and audit logs | no | yes | yes | no |

Read this table literally:

- `yes`: available and intended to be used directly
- `partial`: possible but incomplete, version-sensitive, or missing required policy checks
- `no`: not an approved current path

## Version Targeting

Implementation should target the actual local DEVONthink Pro 4.1 environment first.

- validated against the target install: preferred and authoritative
- inferred from newer 4.2.x documentation: acceptable only when called out explicitly
- still needs local confirmation: must be treated as unvalidated

## Source Lineage

- `inputs/Agentic PKIM design brief for DEVONthink Pro 4.1.md`
  Focus: feasibility of a local agent-assisted stack, sidecars, Notion option, and MCP gap analysis.
- `inputs/DEVONthink-Centric PKIM Design Brief.md`
  Focus: DEVONthink-native control plane, canonical knowledge inside DEVONthink, one-way export mirror, and native workflows.

The second brief is the dominant design direction. The first brief still contributes useful constraints around automation limits, MCP gaps, identity discipline, sidecar portability, and approval-gated writes.

## Register

| Component | Purpose | Evergreen stance | Primary brief |
| --- | --- | --- | --- |
| [00 Source Reconciliation](00-source-reconciliation.md) | Records what changed between the two briefs | Treat the later brief as authoritative unless the first brief identifies a still-open technical constraint | Cross-cutting |
| [01 Principles And Decisions](01-principles-and-decisions.md) | Non-negotiable design rules | DEVONthink-centric, local-first, portable, safety-gated | Both |
| [02 System Topology](02-system-topology.md) | Databases, storage roots, mirrors, and trust boundaries | Multiple focused databases plus external mirrors and working roots | Second |
| [03 Information Model](03-information-model.md) | Conceptual information model | Native records first, mirrored markdown second | Both |
| [04 Automation Surface](04-automation-surface.md) | Orientation page for the automation portion of the design pack | Use as the boundary and reading-order page, not as the detailed spec | Both |
| [05 Workflows](05-workflows.md) | Operational workflows only | Keep operator flow separate from readiness and backlog planning | Both |
| [06 Operations And Safety](06-operations-and-safety.md) | Safety policy, recovery requirements, release gates, and observability floor | No blind write automation; recovery must be boring and reliable | Both |
| [07 DEVONthink Operating Model](07-devonthink-operating-model.md) | Detailed database, ingest, filing, queue, and review design | Native DEVONthink features should carry most of the operating load | Both |
| [08 Record And Note Specification](08-record-and-note-specification.md) | Precise metadata, note, relation, and mirror specs | Stable identifiers, native note authoring, disciplined mirrors | Both |
| [09 Automation Architecture](09-automation-architecture.md) | End-to-end automation service design | Shared local service for Claude and Codex, deterministic wrappers, audit-first writes | Both |
| [10 MCP Extension Specification](10-mcp-extension-specification.md) | Concrete extension plan for the DEVONthink MCP surface | Wrap first, fork only where the protocol really needs it | First plus user direction |
| [11 Agent Skills And Runbooks](11-agent-skills-and-runbooks.md) | Concrete skill contracts and runbooks | Runtime-neutral commands, artifacts, and operating steps | User direction |
| [12 Project Hygiene And Work Surface](12-project-hygiene-and-work-surface.md) | Exact repo contract for tracked and untracked work surfaces | This repo is the development and operational work surface | User direction |
| [13 Capability And MVP Map](13-capability-and-mvp-map.md) | Capability decomposition and checkpointed availability | Continuous build with explicit usable checkpoints | Both |
| [14 Implementation Work Packages](14-implementation-work-packages.md) | Concrete build backlog and sequencing logic | Build it as one system, but sequence work by dependency and leverage | User direction |
| [15 Glossary](15-glossary.md) | Local vocabulary | Keep terms stable across design, ops, and runtime use | User direction |
| [16 Evidence Policy By Library](16-evidence-policy-by-library.md) | Library-specific evidence handling appendix | Library policy should be explicit, not implied | User direction |
| [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) | Claim schema, confidence ladder, contradiction-handling rules, claim-ledger artefact contract | Claims are structured, evidence-backed, and confidence-graded | User direction |
| [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) | Project plan to close the synthesis gap with claim schema, contradiction handling, and confidence | Synthesis is a first-class discipline, not an emergent property of filing | User direction |
| [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md) | One-page rationale for the metadata-vs-graph principle | Graph edges live in note bodies as WikiLinks; metadata describes records | User direction |
| [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md) | Layered architecture for PyObjC ScriptingBridge transport and the new `dt-pkim-mcp` server | **Superseded 2026-05-20** by doc 22 | User direction |
| [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md) | Architectural pivot: single compiled CLI exposing atomic primitives; skills own policy and orchestration | **Superseded 2026-07-15** by doc 24 | User direction |
| [23 Swift `pkim` Binary](23-swift-pkim-binary.md) | Contract for the compiled CLI: verb surface, JSON envelope, project layout, Xcode setup, write-gate enforcement | **Superseded 2026-07-15** by doc 24 | User direction |
| [24 DT MCP Adoption](24-dt-mcp-adoption.md) | DEVONthink 4.3+ in-app MCP server is the runtime; skills compose its tools directly. Retires `pkim-binary`. | Canonical for the runtime; supersedes docs 09, 10, 20, 22, 23 | User direction |

## Build Threads

- Core information model: IDs, record classes, metadata schema, note templates, relation pattern, export manifest.
- DEVONthink operating model: database layout, import/index rules, review queues, native automation.
- Local automation layer: MCP wrapper, deterministic helpers, scratch-database validation, run logging.
- Working repo: scripts, prompts, adapters, tests, and exported knowledge mirror.
- Runtime interoperability: Claude Code and Codex CLI share one local command, environment, and logging surface.

## Operating Entry Points

- Folder landscape and repo purpose: [../ops/repo-operating-model.md](../ops/repo-operating-model.md)
- Regular operating cadence: [../ops/operating-rhythm.md](../ops/operating-rhythm.md)
- Inbox enrichment loop: [../ops/intake-runbook.md](../ops/intake-runbook.md)
- Runtime-neutral agent rules: [../ops/agent-runtime-surface.md](../ops/agent-runtime-surface.md)
