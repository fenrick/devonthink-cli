# Automation Architecture

> **SUPERSEDED 2026-05-20** by [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md).
>
> The runtime shape described here — Python+PyObjC under an MCP server, a shared local command layer with compound verbs, JXA/AppleScript helpers — is retired. PKIM's runtime is now a single compiled CLI (`pkim`) exposing atomic primitives, with policy and orchestration owned by skills. The information model, safety model, and operating model below are unaffected; only the automation runtime is.
>
> The content below is retained for historical context only. Do not act on it for new work. Where this doc describes a verb or behaviour that survives under the new model, the canonical statement now lives in doc 22 or doc 23 (forthcoming).

## Purpose

This document expands the technical design for the automation layer that sits around DEVONthink. It defines the runtime shape, command surface, internal components, logging rules, and write controls needed to turn the shared local helper surface into a practical PKIM automation system.

## Architecture Goal

Create one local automation surface that:

- works for Claude Code and Codex CLI
- keeps DEVONthink as the canonical store
- adds missing metadata and export behaviour
- enforces safety and auditability
- remains understandable to a tired operator

The approved operator surface is the shared local command layer, backed by JXA or AppleScript helpers where needed. MCP may exist in the stack, but it is optional transport rather than the required primary path.

## High-Level Shape

```text
Claude Code / Codex CLI
        |
        v
Shared local wrappers and run commands
        |
        v
PKIM automation service
  - capability probe
  - policy engine
  - run logger
  - mirror exporter
  - metadata helpers
  - filing controller
        |
        +--> community DEVONthink MCP
        |
        +--> local AppleScript/JXA helpers
        |
        +--> repo manifests and logs
        |
        +--> DEVONthink databases
```

## Design Principles

### Runtime-neutral callers

The automation service should not care whether the caller is Claude Code or Codex CLI. A run is a run.

### Thin wrappers, strong contracts

Write small wrappers around meaningful operations:

- profile a record
- write approved metadata
- create a knowledge note
- create a relation note
- refresh the mirror
- file a record safely

Do not expose a soup of low-level tool calls to every prompt and hope for the best.

### Read first, write later

The architecture should make it trivial to perform safe reads and slightly painful to perform live writes. Pain is a feature here.

## Core Components

### 1. Capability probe

Purpose:

- inspect the effective local command and helper surface
- record version and schema shape where available
- detect whether required commands are available
- report auxiliary MCP availability separately if present
- refuse live operations when the surface does not match expectations

Outputs:

- capability manifest
- warnings for missing or changed commands
- machine-readable gating result

### 2. Policy engine

Purpose:

- evaluate whether an action is permitted
- distinguish imported from indexed handling
- enforce scratch vs production boundaries
- enforce dry-run requirements

Policy questions include:

- is this target database scratch or production?
- is the record imported or indexed?
- is the requested action move, replicate, or delete?
- does this runtime allow production writes for this run?

### 3. Run logger

Purpose:

- generate run IDs
- record inputs, outputs, before state, after state, and errors
- keep logs runtime-neutral

Artifacts:

- run manifest JSON
- human-readable run summary markdown
- optional per-record change entries

### 4. DEVONthink adapter layer

Purpose:

- encapsulate command-helper and optional MCP calls
- normalize differences in command output
- provide stable internal shapes for the rest of the system

This layer should convert raw command-helper responses into internal domain objects such as:

- `RecordSummary`
- `RecordProperties`
- `RecordContextPacket`
- `MutationResult`

### 5. Local helper layer

Purpose:

- close MCP gaps with deterministic local helpers
- perform custom metadata writeback
- perform mirror export orchestration
- handle edge cases where DEVONthink scripting is more reliable than the public MCP surface

This is where AppleScript/JXA helpers belong.

### 6. Mirror export layer

Purpose:

- read canonical notes
- render portable files into the mirror tree
- produce export manifests
- detect drift

### 7. Filing controller

Purpose:

- evaluate filing proposals
- perform replicate or move after policy checks
- treat indexed and imported records differently

## Internal Domain Objects

### `RecordRef`

Minimal stable pointer:

- `pkim_id`
- `dt_uuid`
- `dt_item_link`
- `database`
- `doc_role`

### `RecordContextPacket`

Contains:

- stable reference
- title and native DEVONthink `kind`
- current metadata
- extracted or native content
- raw classify suggestions
- raw compare results
- compare/classify neighbours as discovery signals, never as truth
- deterministic risk and uncertainty flags

The profiling skill may consume this packet and produce a richer interpreted profile, but the shared command surface must stay read-only and deterministic.

### `MutationIntent`

Represents a requested change before it becomes live:

- action type
- target record
- requested values
- policy classification
- dry-run output

### `MutationResult`

Represents the executed result:

- action type
- before state
- intended state
- refreshed after state
- success or failure
- rollback note

## Shared Command Surface

The system needs one stable operator-facing command surface. Suggested commands:

| Command | Purpose |
| --- | --- |
| `pkim health-check` | Probe runtime, environment, helper resolution, and scratch DB availability |
| `pkim probe-capabilities` | Record the effective local command and helper surface |
| `pkim profile <record>` | Read-only profiling pass |
| `pkim apply-metadata <record>` | Approved metadata write with refresh verification |
| `pkim create-knowledge-note <record>` | Build or update a native note from evidence |
| `pkim create-relation-note <source> <target>` | Create explicit relation note |
| `pkim sync-mirror [scope]` | Export notes to the mirror and emit manifest |
| `pkim safe-file <record>` | Replicate or move after policy evaluation |

Claude and Codex should both call these wrappers, not invent their own.

## Execution Modes

### Dry-run mode

Required for all mutation paths.

Expected behaviour:

- perform reads
- compute intended change
- emit a `MutationIntent`
- do not change DEVONthink

### Live mode

Allowed only when:

- target is permitted
- operator requested it
- run config enables it
- command surface matches the expected capability map

### Scratch mode

This is not just dry-run. Scratch mode executes live against a disposable database to validate real write semantics.

## Write Safety Design

### Before/after refresh

Every live mutation must:

1. read the existing state
2. apply the change
3. re-read the state
4. compare intended vs actual outcome

If the refreshed state does not match the intent closely enough, the run should fail noisy and log the discrepancy.

### Indexed-item rules

Indexed items require stricter gates:

- never assume path safety
- never move without explicit path policy approval
- replicate first when uncertain
- log old and new path context

### Delete rules

Delete should be absent or disabled in early live builds. If later enabled, it should require:

- production write enablement
- explicit non-default confirmation
- human-readable change summary
- trash-first semantics where possible

## Observability Design

### Required outputs per run

- `run.json`
- `summary.md`
- optional `changes.jsonl` for record-level events

### Required fields

- `run_id`
- `runtime`
- `operator_mode`
- `started_at`
- `finished_at`
- `command`
- `dry_run`
- `database_targets`
- `record_targets`
- `result`

### Useful derived metrics

- profile success rate
- mutation failure rate
- mirror drift count
- indexed-path warning count
- relation-note creation volume
- average time from evidence ingest to knowledge-linked state

## Failure Handling

### Expected failure classes

- MCP unavailable
- DEVONthink unavailable
- schema changed
- record not found
- write disallowed by policy
- post-write refresh mismatch
- mirror export failure

### Failure response rules

- fail closed for writes
- fail loud for mismatches
- leave diagnostic artifacts in `runs/` and `logs/`
- do not attempt clever hidden retries on destructive actions

## Repo Integration

The automation layer should eventually populate:

- `scripts/`
- `prompts/`
- `schemas/`
- `tests/`

Suggested structure:

```text
scripts/
  pkim
  pkim-devonthink-helper
  pkim-export-mirror
schemas/
  capability-manifest.schema.json
  run-manifest.schema.json
prompts/
  profile-record.md
  build-knowledge-note.md
tests/
  fixtures/
  integration/
  unit/
```

## Security And Robustness Defaults

- no secrets in logs
- bounded retries
- explicit timeouts
- explicit path allowlists for mirror export
- separate scratch and production configs
- explicit write enablement per run

## Practical Outcome

If this architecture is followed, the automation layer becomes a serious local operator surface rather than a pile of prompt fragments wrapped around an unstable MCP.
