# Repo Hygiene

## Purpose

What lives in this repo, where it goes, what gets committed. This repo is the working surface for PKIM — design, skills, prompts, operational history. It is not a parallel authoring surface for canonical notes; those live in DEVONthink.

## Tree

```
PKIM/
├── docs/
│   ├── design/          Evergreen design contracts (this folder)
│   └── ops/             Operating runbooks, cadence, environment setup
├── skills/              The four PKIM skills, each self-contained
├── prompts/             Reusable prompt files for bounded tasks
├── schemas/             Machine-readable artefact contracts
├── inputs/              Local-only source briefs (gitignored)
├── runs/                Per-session artefacts (gitignored)
├── logs/                Execution logs (gitignored)
├── tmp/                 Scratch (gitignored)
├── AGENTS.md            Codex-facing root instructions
├── CLAUDE.md            Claude Code-facing root instructions
├── README.md            Repo entry point
├── LICENSE              MIT
├── CONTRIBUTING.md      How to propose changes
├── SECURITY.md          Vulnerability reporting
├── CODE_OF_CONDUCT.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── .env.example         Sample environment variables
└── .gitignore
```

## Tracked

### `docs/design/`

Canonical design contracts. Nine numbered docs (`01-09`) plus this README. Every doc is evergreen — no supersession banners, no retired-runtime detours, no landed project plans. When a doc's shape changes materially, edit it in place; the git history carries the reasoning trail.

Cross-references between design docs are numbered and stable. Design docs do not link out to skills; skills are self-contained (see below).

### `docs/ops/`

Operating runbooks — session start, intake cadence, capability probe, restore drill, local environment setup, per-database policy. These are procedural documents that reference the skills and DT MCP tools by name.

### `skills/`

The four PKIM skills. Each is self-contained: a `SKILL.md` at the top with progressive-disclosure `references/` and optional `assets/` beside it. Skills do not link out to `docs/design/*` or `docs/ops/*` — everything a skill needs at runtime lives inside its own directory.

Cross-skill references (e.g. `dt-intake/references/*` linking to `pkim-primer/references/*`) are allowed and expected — every skill assumes `pkim-primer` has been read.

### `prompts/`

Reusable prompt contracts. Named tasks with clear input/output expectations. Consumed by skills or by the human directly.

### `schemas/`

Machine-readable artefact contracts. JSON schemas for anything a skill emits (run summaries, findings JSON, etc.).

## Untracked

### `inputs/`

Local-only source briefs and raw material. The `inputs/.gitignore` uses `*` + exemptions for `.gitignore` and `README.md`, so tracked-by-mistake is prevented at the directory level.

Never commit private source material.

### `runs/`, `logs/`, `tmp/`

Per-session artefacts. Skills produce these; the operator reviews them; they don't accumulate in the repo. Gitignored at the directory level.

## Skill self-containment

Skills are self-contained. This means:

- Every reference a skill needs at runtime lives inside `skills/<name>/references/`.
- Every asset a skill installs lives inside `skills/<name>/assets/`.
- Skills do not link out to `docs/design/*` or `docs/ops/*`. Design docs describe intent (what the system is); skills carry procedure (how to operate it). Skills reference other skills, not the design register.

Why: an operator running a skill should not need to leave the skill's tree to complete a workflow. The skill knows enough to act.

## Working rules

- **DEVONthink is the canonical working environment** for evidence and knowledge records.
- **This repo is the canonical working environment** for design, skills, prompts, and operational history.
- **Never commit raw source inputs.** `inputs/` is local-only; the gitignore enforces this.
- **Do not treat exported mirrors as authoritative.** `PKIM-Knowledge` is indexed against its iCloud-synced root; that root *is* the mirror. It's a projection, not canon.
- **Do not use this repo as a parallel authoring surface** for canonical notes. Notes are authored in DEVONthink.
- **Commits are small and reviewable.** Conventional-commits style is preferred (`feat(skill): …`, `docs(design): …`, `chore(repo): …`).

## Change discipline

### Design doc changes

- Edit the doc in place. No supersession banners.
- If the change is substantive, mention the reasoning in the commit message.
- Cross-references between design docs may need updates — grep for the doc number after any rename or restructure.

### Skill changes

- Every skill has three parts: description (in the SKILL.md frontmatter), body (the workflow), references (progressive-disclosure detail).
- Descriptions trigger invocation — change carefully; they affect when the LLM picks the skill.
- References carry operational detail — grow them freely; the SKILL.md pulls them in on demand.

### Adding a new doc / skill

- Design docs are numbered `01-XX`. Adding a new doc means picking the next number and updating `docs/design/README.md`.
- Skills are named without numeric prefixes. Follow the `<verb>-<noun>` or `<domain>-<verb>` pattern.

## Anti-patterns

- Committing `inputs/` content by mistake — the directory-level gitignore prevents this at add-time.
- Adding supersession banners to design docs when a rewrite is warranted — do the rewrite, let git history carry the trail.
- Skills linking out to `docs/`, breaking self-containment.
- Design docs describing skill-level procedure — that's the skills' job.
- Committing `runs/`, `logs/`, `tmp/` content when investigating a problem — those are gitignored for a reason.
- Encoding secrets in `.env.example` — the file is a template, not a place to leak keys.
