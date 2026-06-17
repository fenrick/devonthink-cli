# CLAUDE

## Purpose

This repository is the shared operational surface for designing, extending, and running the DEVONthink-centric PKIM stack from Claude Code and Codex CLI.

## Ground Rules

- Start with [docs/design/README.md](docs/design/README.md) before making design or implementation changes.
- Follow [docs/ops/agent-runtime-surface.md](docs/ops/agent-runtime-surface.md) for runtime-neutral execution rules.
- Treat the `docs/design/` set as the current contract unless a newer committed change updates it.
- Keep `inputs/` local-only and untracked.
- Put transient run artifacts in `runs/`, `logs/`, or `tmp/`, not in tracked docs.
- Prefer small, reviewable commits. If the change is non-trivial, update the relevant design brief in the same branch.
- Do not add automation that can mutate DEVONthink without an explicit safety model and rollback path captured in `docs/design/`.

## Repo Conventions

- Keep canonical design intent in markdown.
- Use deterministic local scripts and adapters over opaque agent state.
- If you add a tool, document its contract, inputs, outputs, and failure modes before wiring it into agents.
- If a design decision changes, update `docs/design/00-source-reconciliation.md` or the relevant component brief so the delta stays explicit.

