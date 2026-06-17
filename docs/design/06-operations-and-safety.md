# Operations And Safety

## Purpose

This document defines the operational safety policy for the PKIM.

It answers:

What must be true before the system is allowed to read, write, recover, and continue operating safely?

It does not define:

- the repo file contract
- the automation architecture
- the build backlog
- the detailed skill command surface

## Safety Model

### Read-mostly by default

Search, read, lookup, compare, and classify are low-risk. They can be enabled early and used broadly.

### Normative production-write policy

This section is normative.

#### What counts as a production write

A production write is any mutation against a non-scratch database or canonical library, including:

- move
- replicate
- rename
- delete
- retag
- metadata write
- canonical note mutation
- mirror export that overwrites an intentionally committed canonical snapshot

#### Always forbidden by default

The following operations are forbidden by default:

- delete
- auto-move of indexed records
- any write against non-scratch databases when the write gate is closed
- any mutation path that does not support dry-run
- any mutation path that does not emit before-state and after-state logging
- any mutation path that cannot re-read and verify the intended change

#### Write unlock

No production write may execute unless `PKIM_ALLOW_PRODUCTION_WRITES=true`.

That flag enables eligibility for approved write paths. It does not waive approval, dry-run, logging, or verification requirements.

#### Required dry-run behaviour

Every state-changing command must support dry-run mode.

Dry-run output must show:

- target database
- target record IDs
- intended action
- policy result
- expected field changes or location changes

#### Required post-mutation verification

After every mutation, the runtime must:

- re-read the mutated record or records
- compare refreshed state to intended state
- log before state
- log intended mutation
- log refreshed after state
- fail closed if refreshed state does not match the intended bounded change

### Approval-gated writes

The following require explicit approval and logging:

- metadata mutation
- note creation that affects canonical records
- move, replicate, rename, or delete
- export actions that overwrite committed mirrors

### Scratch before production

Any new command or adapter must pass on a scratch database before it touches production libraries.

## Recovery Requirements

- Use conventional backups for DEVONthink database packages.
- Use DEVONthink versions and named versions for in-app note history.
- Use export mirrors for text-level portability and recovery.
- Keep run logs so bad automation can be traced, not guessed at.

### Backup and restore drills

Minimum required layers:

- system backup
- database archives
- mirror backup
- periodic restore testing

Restore tests must be run on a cadence, not just declared in a checklist.

## Indexed Material Rules

- Index parent roots, not one-off files.
- Expect manual refresh requirements after external filesystem activity.
- Treat indexed cloud material as operationally fragile.
- Keep mobile-critical content imported.

## Minimum Observability

At minimum, keep:

- run ID
- actor or tool name
- target database
- action type
- before state summary
- intended mutation
- refreshed after state summary
- error output or rollback action

## Release Gates

- compatibility matrix must be current
- capability probe must pass before agent runs
- scratch-database validation must pass before live write enablement

See:

- [docs/ops/compatibility-matrix.md](../ops/compatibility-matrix.md)
- [docs/ops/capability-probe.md](../ops/capability-probe.md)

## Best-Than-Best-Practice Defaults

- Separate production and scratch configuration.
- Record exact tool and schema versions in docs before enabling writes.
- Keep policy checks in code and documentation, not only prompts.
- Prefer replicate over move early.
- Treat delete as a later-stage administrative function, not an everyday automation action.

## Detailed Companions

- For repo artifact locations, use [12 Project Hygiene And Work Surface](12-project-hygiene-and-work-surface.md).
- For concrete runtime commands and runbooks, use [11 Agent Skills And Runbooks](11-agent-skills-and-runbooks.md).
- For automation component design, use [09 Automation Architecture](09-automation-architecture.md).
