# Project Hygiene And Work Surface

## Purpose

This document defines only the concrete repository contract for the PKIM work surface.

It answers one question:

What exactly lives in this repo, where does it go, and what gets committed?

It does not define the automation architecture or the detailed skill model.

The repo is for design, tooling, skills, exports, diagnostics, run evidence, and test surfaces. It is not a parallel work surface for casual editing of canonical native notes.

## Repository Tree Contract

The intended tree is:

```text
PKIM/
  docs/
    design/
    ops/
  exports/
    knowledge-mirror/
  inputs/
  logs/
  prompts/
  runs/
  schemas/
  scripts/
  skills/
  src/
  tests/
  tmp/
  AGENTS.md
  CLAUDE.md
  README.md
  .env.example
```

## Tracked Paths

### `docs/design/`

Purpose:

- canonical design pack

Commit rule:

- always tracked

### `docs/ops/`

Purpose:

- runtime-neutral operating contract

Commit rule:

- always tracked

### `scripts/`

Purpose:

- shared command wrappers and local helpers
- deterministic mechanics for bounded PKIM operations

Commit rule:

- track executable shared scripts only

Naming rule:

- `pkim-*` or `pkim` prefix for first-class commands

### `skills/`

Purpose:

- agent operating methods and workflow guardrails

Commit rule:

- track finished project skills and their supporting evals or references

Boundary rule:

- skills define judgement and sequencing; scripts execute deterministic operations

### `src/`

Purpose:

- implementation of the local `pkim` command surface

Commit rule:

- always tracked

### `prompts/`

Purpose:

- reusable prompt files tied to bounded tasks

Commit rule:

- track prompts that are part of the operating surface

### `schemas/`

Purpose:

- machine-readable contracts

Commit rule:

- track any schema used by commands, logs, or manifests

### `tests/`

Purpose:

- unit and integration validation

Commit rule:

- track all tests and safe fixtures

### `exports/knowledge-mirror/`

Purpose:

- intentional portable note mirror

Commit rule:

- commit only deliberate mirror outputs, not accidental churn

## Untracked Paths

### `inputs/`

Purpose:

- local-only source materials

Commit rule:

- never commit by default

### `runs/`

Purpose:

- per-run artifacts

Commit rule:

- untracked by default

### `logs/`

Purpose:

- execution logs

Commit rule:

- untracked by default

### `tmp/`

Purpose:

- scratch files

Commit rule:

- untracked by default

## File Naming Rules

### Scripts

- first-class shared command: `scripts/pkim`
- focused helper: `scripts/pkim-<verb>`
- internal helper: `scripts/pkim-<domain>-helper`

### Schemas

- `<artifact-name>.schema.json`

Examples:

- `run-manifest.schema.json`
- `profile-packet.schema.json`

### Prompt files

- `<task-name>.md`

Examples:

- `profile-record.md`
- `create-knowledge-note.md`

### Mirror files

- include stable `PKIM_ID` in filename

Example:

- `KN-20260417-0021-problem-framing-in-local-second-brain-systems.md`

## Commit Rules

### Always commit

- design changes
- runtime contract changes
- shared command changes
- schema changes
- test changes

### Commit intentionally

- mirror outputs
- generated examples used as fixtures

### Never commit by default

- raw local source materials
- ad hoc run output
- local credentials
- random scratch notes

## Artifact Location Rules

### Run artifacts

Write run artifacts under:

```text
runs/<run-id>/
```

Expected core files:

- `run.json`
- `summary.md`

Optional files:

- `profile.json`
- `mutation.json`
- `export-manifest.json`

### Log files

Write logs under:

```text
logs/<date-or-run-id>.log
```

### Temporary files

Write scratch files under:

```text
tmp/<task-or-run-id>/
```

## Runtime Parity Rules

Claude Code and Codex CLI must:

- read the same docs
- use the same `.env` contract
- call the same `scripts/` surface
- write artifacts to the same `runs/`, `logs/`, and `tmp/` structure

If one runtime needs a special helper, it is not a shared helper and should not become the system default.

## Minimum Shared Command Surface

The repo should converge on these first-class commands:

- `scripts/pkim`
- `scripts/pkim-health-check`
- `scripts/pkim-probe-capabilities`
- `scripts/pkim-sync-mirror`
- `scripts/pkim-devonthink-helper`

If a new command becomes first-class, add it here and document its purpose in `scripts/README.md`.

## Fixture Rules

Safe fixtures should live under:

```text
tests/fixtures/
```

Fixture types:

- sample manifests
- sample profile packets
- sample prompt inputs
- harmless note exports

Never use live private source documents as test fixtures.

## Change Discipline

If a repo-structure change affects how operators use the system:

1. update this document
2. update `README.md` or `docs/ops/` if needed
3. commit the docs with the structural change

## Anti-Patterns

Avoid:

- hidden conventions that live only in chat history
- runtime-specific directory layouts
- generated sludge committed as if it were intentional output
- commands with unstable names
- fixtures built from sensitive real input materials
