# PKIM

PKIM is a local knowledge operating system built around DEVONthink.

This folder is not just a codebase. It is the working area for the system: design intent, operating rules, agent skills, run evidence, and documentation all live here. DEVONthink remains the canonical store for evidence and knowledge records; this repo is the operational surface that makes the work repeatable.

The purpose is to turn incoming material into a curated, linked, reviewable knowledge corpus:

- evidence is captured and profiled
- metadata, tags, names, destinations, and notes are developed while records are still reviewable
- knowledge notes describe what the material means
- relation notes wire the graph together
- filing makes browsing easier without breaking stable DEVONthink item links
- skills, prompts, and run artifacts make the workflow repeatable

The system is a document-and-link graph with structured relation notes. It is not a native property-graph database.

## Runtime

DEVONthink 4.3+ ships an in-app MCP server. That is the runtime PKIM composes; there is no PKIM-owned binary. Skills call DT MCP tools directly (`get_record_properties`, `set_record_custom_metadata`, `update_record_content`, `search_records`, etc.). See [docs/design/07-runtime.md](docs/design/07-runtime.md) for how skills compose DT MCP.

Requirements: macOS Sequoia or later, DEVONthink 4.3+ (Pro edition for MCP), an MCP-capable AI client (Claude Code, Codex CLI, etc.).

## First Read

If you are new to the folder, read in this order:

1. [docs/README.md](docs/README.md) — documentation map and task-based loading guide.
2. [docs/ops/repo-operating-model.md](docs/ops/repo-operating-model.md) — what this working area is for.
3. [docs/ops/operating-rhythm.md](docs/ops/operating-rhythm.md) — how day-to-day work runs.
4. [docs/ops/intake-runbook.md](docs/ops/intake-runbook.md) — how inbox material is processed.
5. [docs/design/README.md](docs/design/README.md) — the full design register.
6. [docs/design/07-runtime.md](docs/design/07-runtime.md) — how skills compose DT MCP.
7. [skills/README.md](skills/README.md) — how agent skills structure the workflow.

For task-specific work, do not read the whole documentation tree first. Use [docs/README.md](docs/README.md) to load the smallest useful context set.

The documentation is meant to disclose detail in layers:

1. **Why** — the system exists to turn material into usable, linked, reviewable knowledge.
2. **What** — DEVONthink holds canonical records; this repo holds operating contracts and skill workflows.
3. **How** — skills define judgement; DT MCP tools perform bounded repeatable actions.
4. **Exact contract** — design specs and schemas define what must be true.

If a page jumps straight to commands without explaining why the step exists, it is incomplete.

## One Large Skill

The entire PKIM stack should be understood as one large LLM-operable skill, decomposed into smaller skills and deterministic tools.

At the top level, the skill is:

> Given incoming material, decide what it is, preserve evidence identity, develop useful metadata and notes, wire it into the knowledge graph, file it somewhere browseable, and leave enough evidence that the action can be audited or repaired.

The sub-skills in `skills/` are not isolated utilities. They are chapters of that larger operating skill. The DT MCP tool surface exists so the LLM performs mechanics through a trusted, DEVONthink-signed API rather than improvising.

## Landscape

Think of the project as five connected layers:

| Layer | What it does | Where to start |
| --- | --- | --- |
| Canonical store | DEVONthink databases, records, custom metadata, groups, smart groups, item links | [docs/design/04-devonthink-operating-model.md](docs/design/04-devonthink-operating-model.md) |
| Knowledge model | Evidence, knowledge notes, relation notes, frontmatter, metadata, mirror rules | [docs/design/03-record-and-note-specification.md](docs/design/03-record-and-note-specification.md) |
| Workflow method | Human-plus-agent operating flows from inbox to graph to mirror | [docs/design/05-workflows.md](docs/design/05-workflows.md) |
| Execution surface | Skills composing the DEVONthink 4.3+ MCP server tools | [docs/design/07-runtime.md](docs/design/07-runtime.md) |
| Operating rhythm | The repeatable cadence for checking queues, processing inboxes, repairing graph issues, and refreshing mirrors | [docs/ops/operating-rhythm.md](docs/ops/operating-rhythm.md) |

## How Work Moves

The normal flow is:

1. Capture or import material into DEVONthink.
2. Sweep and profile records while they remain in `/Inbox/`.
3. Apply reviewed metadata and enrichment.
4. Create or update knowledge notes and relation notes.
5. Run graph checks and repair missing edges.
6. Rename and file records only after the semantic work is done.
7. Export mirrors and review dashboards.

Use [docs/ops/intake-runbook.md](docs/ops/intake-runbook.md) for the detailed inbox loop.

## What Lives Here

- `docs/design/` — evergreen design contracts for the knowledge operating system.
- `docs/ops/` — operating model, rhythm, setup, validation, and runbooks.
- `skills/` — agent operating methods. A skill defines how work should be done, composing DT MCP tools.
- `prompts/` — reusable prompt contracts for bounded tasks.
- `schemas/` — machine-readable artifact contracts.
- `inputs/` — local-only source briefs and other raw inputs; ignored by git.
- `runs/`, `logs/`, `tmp/` — per-session artefacts; ignored by git.

## Working Rules

- DEVONthink is the canonical working environment for evidence and knowledge records.
- This repo is the canonical working environment for design, skills, prompts, and operational history.
- Skills drive workflow judgement; DT MCP tools provide deterministic mechanics. Do not confuse the two.
- Writes are gated by DEVONthink's own settings and per-record `Exclude from AI` flags; skills honour them.
- Cross-database references (any KN → EV link across `PKIM-Knowledge` ↔ `PKIM-Evidence-*`) use `x-devonthink-item://<uuid>` item links, not `[[Name|Display]]` WikiLinks — the renderer only resolves WikiLinks within one database.
- Never commit raw source inputs from `inputs/`.
- Do not treat exported mirrors as authoritative unless a design doc says so.
- Do not use this repo as a casual parallel authoring surface for canonical notes.

## Main Entry Points

- Documentation map: [docs/README.md](docs/README.md)
- Landscape and folder purpose: [docs/ops/repo-operating-model.md](docs/ops/repo-operating-model.md)
- Ops index: [docs/ops/README.md](docs/ops/README.md)
- Operating rhythm: [docs/ops/operating-rhythm.md](docs/ops/operating-rhythm.md)
- Design register: [docs/design/README.md](docs/design/README.md)
- Runtime brief: [docs/design/07-runtime.md](docs/design/07-runtime.md)
- Inbox workflow: [docs/ops/intake-runbook.md](docs/ops/intake-runbook.md)

## Agent Entry Points

- `AGENTS.md`: Codex-facing root instructions
- `CLAUDE.md`: Claude Code-facing root instructions

## Phase 0 Pilot Exit Criteria

The pilot is not complete until all of the following are true:

- `PKIM-Pilot` exists locally and is not stored in a cloud-synced path.
- 50 to 100 pilot records have been ingested across representative source types.
- the canonical metadata fields are defined and applied consistently enough to review.
- at least 15 native knowledge notes exist and use the canonical metadata form.
- at least 5 relation notes exist and resolve correctly.
- one indexed parent-root pattern has been tested, including manual refresh checks.
- the mirror can be exported and read outside DEVONthink.
- read-only runtime health and profiling flows work.
- backup and restore paths have been exercised, not merely configured.

## Contributing

PKIM is a single-developer project; the bar for external changes is high (see [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md)). Issues and proposals welcome; please anchor proposals to a design brief.

## License

MIT — see [LICENSE](LICENSE).
