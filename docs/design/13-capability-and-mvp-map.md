# Capability And MVP Map

## Purpose

This document decomposes the PKIM into capabilities and maps them to usable checkpoints.

The system is not being built in strict serial phases, but it still needs explicit definitions of “usable now” versus “not actually ready.”

## Capability Domains

| Domain | Description |
| --- | --- |
| DEVONthink topology | Databases, groups, import/index policy, mobile-safe subset |
| Identity and metadata | Stable IDs, metadata schema, review states, note typing |
| Native note system | Knowledge notes, relation notes, topic notes, templates |
| Read automation | Search, lookup, profile, compare, classify |
| Write automation | Metadata mutation, note creation, relation creation |
| Filing automation | Replicate or move under policy control |
| Mirror and portability | Export mirror, manifests, drift detection |
| Runtime operations | Shared Claude/Codex contract, environment, logs, commands |
| Safety and support | Scratch tests, rollback, observability, capability probing |

## Capability Matrix

| Capability | Human only | Assisted | Automated |
| --- | --- | --- | --- |
| Database setup | yes | yes | later |
| Metadata schema definition | yes | yes | no |
| Record profiling | yes | yes | yes |
| Knowledge note drafting | yes | yes | yes with review |
| Relation note drafting | yes | yes | yes with review |
| Metadata writeback | yes | yes | yes with verification |
| Filing imported records | yes | yes | yes in bounded cases |
| Filing indexed records | yes | yes | maybe later and only with policy |
| Mirror export | yes | yes | yes |
| Capability probing | no | yes | yes |

## Checkpoint Definitions

### Checkpoint A: Repo and runtime base

Must have:

- design register
- ops docs
- Claude and Codex root entry files
- local environment contract
- ignored local input surface

Value:

- agents can operate from the repo without making up conventions

### Checkpoint B: Information model base

Must have:

- stable ID scheme
- metadata schema
- native note templates
- relation-note rules
- mirror contract

Value:

- knowledge can be captured consistently

### Checkpoint C: Read automation base

Must have:

- health check
- capability probe
- read-only profile flow
- comparable output packet

Value:

- the system can inspect and propose without damaging anything

### Checkpoint D: Canonical note automation

Must have:

- native knowledge-note creation or update
- relation-note creation
- mirror refresh
- run manifests

Value:

- the system starts becoming a practical second brain instead of a read-only inspector

### Checkpoint E: Controlled metadata writes

Must have:

- metadata writeback helper
- post-write refresh validation
- scratch test coverage

Value:

- automation can update record state reliably

### Checkpoint F: Controlled filing

Must have:

- destination proposal
- policy evaluation
- replicate or move for imported items
- indexed-item warnings and hard stops

Value:

- curation becomes operationally useful

### Checkpoint S: Synthesis discipline in use

Inserted by [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP4.1 (2026-05-17). Sits between Checkpoint C and Checkpoint D as a hard gate — Checkpoints D, E, F, and G cannot be declared until S is met.

Must have:

- the claim schema is in use on at least one newly-authored knowledge note per week
- `pkim audit-discipline` returns zero `missing-claims` findings on `KnowledgeStatus=published` notes
- the contradiction register exists and contains at least one detected case (an empty register on a mature corpus is suspicious, not a success — see [18 Evidence Discipline And Claims](18-evidence-discipline-and-claims.md) §Contradiction handling)
- `dt-build-claim-ledger` has been invoked at least three times in the trailing 30 days
- zero `published` knowledge notes carry `Claim_Backed=no` (mirror-derived)

Value:

- knowledge notes are auditable as structured arguments, not free-prose summaries
- contradictions across the corpus are detectable rather than silently coexisting
- the synthesis problem has measurable status, gated by data not opinion

### Checkpoint G: Practical continuous operation

Must have:

- runbook-backed operation
- queue metrics
- drift detection
- failure handling
- regular mirror refresh

Value:

- the system is usable repeatedly, not just in demos

## Non-Goals For Early Checkpoints

Do not pretend early checkpoints need:

- fully autonomous destructive filing
- perfect ontology
- global graph analytics engine
- SaaS collaboration layer
- productionised daemon infrastructure

Those can come later if needed.

## Current Status

As of this design pack:

- Checkpoints A through F are in place on the shared command surface.
- Checkpoint G is in place on the shared command surface: failure handling, runbooks, mirror export, queue metrics, metadata-overview dashboards, restore-drill evidence, scale-readiness gates, graph audit, candidate provenance ledger, and workflow validation all exist on the local command surface.
- Operational truth still lives in `docs/ops/build-plan.md`; do not let this summary outrun the live command behavior.
- Treat `docs/ops/build-plan.md` as the current execution status, not the older checkpoint prose above.

## Success Criteria

The system counts as a practical second brain when:

- evidence can be profiled safely
- knowledge can be created natively **with structured claims, typed and evidence-backed**
- relations can be made explicit
- mirrors can be exported reproducibly
- approved metadata writes are reliable
- filing is policy-aware
- **synthesis-health gates are met** (WP4.2 amendment):
  - ≥80% of `KnowledgeStatus=published` notes carry at least one well-formed claim block with resolved evidence WikiLinks
  - zero unresolved corpus-level contradictions affecting `published` notes
  - the defect register growth rate is < 5% month-on-month at steady state
  - zero `published` notes carry `Claim_Backed=no`
