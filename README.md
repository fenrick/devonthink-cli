# PKIM

PKIM is a local knowledge operating system built around DEVONthink.

This folder is not just a codebase. It is the working area for the system: design intent, operating rules, agent skills, the `pkim` CLI binary, run evidence, and documentation all live here. DEVONthink remains the canonical store for evidence and knowledge records; this repo is the operational surface that makes the work repeatable.

The purpose is to turn incoming material into a curated, linked, reviewable knowledge corpus:

- evidence is captured and profiled
- metadata, tags, names, destinations, and notes are developed while records are still reviewable
- knowledge notes describe what the material means
- relation notes wire the graph together
- filing makes browsing easier without breaking stable DEVONthink item links
- skills, scripts, and run artifacts make the workflow repeatable

The system is a document-and-link graph with structured relation notes. It is not a native property-graph database.

## First Read

If you are new to the folder, read in this order:

1. [docs/README.md](docs/README.md) — documentation map and task-based loading guide.
2. [docs/ops/repo-operating-model.md](docs/ops/repo-operating-model.md) — what this working area is for.
3. [docs/ops/operating-rhythm.md](docs/ops/operating-rhythm.md) — how day-to-day work runs.
4. [docs/ops/intake-runbook.md](docs/ops/intake-runbook.md) — how inbox material is processed.
5. [docs/design/README.md](docs/design/README.md) — the full design register, including the pivot briefs [22 (CLI-first atomic primitives)](docs/design/22-cli-first-atomic-primitives.md) and [23 (Swift pkim binary)](docs/design/23-swift-pkim-binary.md).
6. [skills/README.md](skills/README.md) — how agent skills structure the workflow.

For task-specific work, do not read the whole documentation tree first. Use [docs/README.md](docs/README.md) to load the smallest useful context set.

The documentation is meant to disclose detail in layers:

1. **Why** — the system exists to turn material into usable, linked, reviewable knowledge.
2. **What** — DEVONthink holds canonical records; this repo holds operating contracts and execution surfaces.
3. **How** — skills define judgement; the `pkim` binary performs bounded repeatable actions.
4. **Exact contract** — design specs, schemas, Swift tests, and run artifacts define what must be true.

If a page jumps straight to commands without explaining why the step exists, it is incomplete.

## One Large Skill

The entire PKIM stack should be understood as one large LLM-operable skill, decomposed into smaller skills and deterministic tools.

At the top level, the skill is:

> Given incoming material, decide what it is, preserve evidence identity, develop useful metadata and notes, wire it into the knowledge graph, file it somewhere browseable, and leave enough evidence that the action can be audited or repaired.

The sub-skills in `skills/` are not isolated utilities. They are chapters of that larger operating skill. The `pkim` command surface exists so the LLM does not improvise unsafe mechanics while performing that skill.

## Landscape

Think of the project as five connected layers:

| Layer | What it does | Where to start |
| --- | --- | --- |
| Canonical store | DEVONthink databases, records, custom metadata, groups, smart groups, item links | [docs/design/07-devonthink-operating-model.md](docs/design/07-devonthink-operating-model.md) |
| Knowledge model | Evidence, knowledge notes, relation notes, frontmatter, metadata, mirror rules | [docs/design/08-record-and-note-specification.md](docs/design/08-record-and-note-specification.md) |
| Workflow method | Human-plus-agent operating flows from inbox to graph to mirror | [docs/design/05-workflows.md](docs/design/05-workflows.md) |
| Execution surface | The Swift `pkim` CLI (25 atomic verbs) plus skills, prompts, run artifacts | [docs/design/23-swift-pkim-binary.md](docs/design/23-swift-pkim-binary.md) |
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

- `pkim-binary/` — Swift package for the `pkim` CLI. Atomic-primitive verbs (`get`, `set-metadata`, `move`, `create-note`, etc.) plus five PKIM-bootstrap verbs (`setup-database`, `verify-database`, `verify-smart-groups`, `fix-smart-groups`, `install-templates`). Contract: [docs/design/23-swift-pkim-binary.md](docs/design/23-swift-pkim-binary.md).
- `docs/design/` — evergreen design contracts for the knowledge operating system.
- `docs/ops/` — operating model, rhythm, setup, validation, and runbooks.
- `skills/` — agent operating methods. A skill defines how work should be done, composing `pkim` verbs.
- `scripts/` — shell-only helpers that fall outside the binary's surface. After the AppleScript ports landed in doc 23, this directory holds only `README.md`.
- `prompts/` — reusable prompt contracts for bounded tasks.
- `schemas/` — machine-readable artifact contracts.
- `inputs/` — local-only source briefs and other raw inputs; ignored by git.
- `runs/` — per-invocation run artifacts (`mutation.json`, `mutation-proposal.json`, `invocation.json`); ignored by git.
- `logs/` — execution logs; ignored by git.

## Working Rules

- DEVONthink is the canonical working environment for evidence and knowledge records.
- This repo is the canonical working environment for design, the `pkim` binary, prompts, skills, and operational history.
- Skills drive workflow judgement; the `pkim` binary provides deterministic mechanics. Do not confuse the two.
- Live writes require `PKIM_ALLOW_PRODUCTION_WRITES=true` in the environment. `--dry-run` previews any write verb without touching DT and short-circuits the gate.
- Never commit raw source inputs from `inputs/`.
- Do not treat exported mirrors as authoritative unless a design doc says so.
- Do not use this repo as a casual parallel authoring surface for canonical notes.

## Building and Using `pkim`

```bash
cd pkim-binary
swift build                 # debug build at .build/debug/pkim
swift build -c release      # release build at .build/release/pkim
swift test                  # unit + offline-cache tests (70 tests / 15 suites)

# Optional: live DEVONthink suites (need DT running + your real .dt cache)
PKIM_BRIDGE_LIVE=1 swift test
```

Quickstart against a running DEVONthink:

```bash
./.build/debug/pkim probe-capabilities
./.build/debug/pkim list PKIM-Pilot --group /Inbox/ --limit 5
./.build/debug/pkim get <dt-uuid-or-pkim-id>

# Writes — opt in via env var, dry-run is the safety preview
PKIM_ALLOW_PRODUCTION_WRITES=true ./.build/debug/pkim \
    set-metadata <ref> Review_State=approved --dry-run
```

Full verb surface and JSON envelopes: [docs/design/23-swift-pkim-binary.md](docs/design/23-swift-pkim-binary.md).

Requirements: macOS 13+ (Ventura), Swift 6.0+, DEVONthink installed for write verbs and most read verbs; `.dt` cache reads work without DT running.

## Main Entry Points

- Documentation map: [docs/README.md](docs/README.md)
- Landscape and folder purpose: [docs/ops/repo-operating-model.md](docs/ops/repo-operating-model.md)
- Ops index: [docs/ops/README.md](docs/ops/README.md)
- Operating rhythm: [docs/ops/operating-rhythm.md](docs/ops/operating-rhythm.md)
- Design register: [docs/design/README.md](docs/design/README.md)
- CLI contract: [docs/design/23-swift-pkim-binary.md](docs/design/23-swift-pkim-binary.md)
- Pivot rationale: [docs/design/22-cli-first-atomic-primitives.md](docs/design/22-cli-first-atomic-primitives.md)
- Inbox workflow: [docs/ops/intake-runbook.md](docs/ops/intake-runbook.md)
- Runtime contract: [docs/ops/agent-runtime-surface.md](docs/ops/agent-runtime-surface.md)

## Agent Entry Points

- `AGENTS.md`: Codex-facing root instructions
- `CLAUDE.md`: Claude Code-facing root instructions
- `docs/ops/agent-runtime-surface.md`: runtime-neutral contract both must follow

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
