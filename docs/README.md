# PKIM Documentation Map

## Purpose

Map for operating PKIM as a knowledge operating system. Start with the smallest layer that answers the current question; load deeper contracts only when the task requires them.

Two document trees live under `docs/`:

- **`design/`** — evergreen contracts. What PKIM is, why it's shaped this way, what won't be violated. Nine numbered docs, indexed at [design/README.md](design/README.md).
- **`ops/`** — operating runbooks. Session cadence, local environment, per-database policy, restore drill. Indexed at [ops/README.md](ops/README.md).

Skills in `skills/` are self-contained and don't link out to these docs — the operational content lives inside each skill's own `references/`. Design docs and ops docs are for orientation and discipline, not per-session workflow.

## End-to-end story

PKIM exists to turn incoming material into durable, linked, reviewable knowledge:

1. Material arrives in DEVONthink.
2. The inbox is swept; each record is profiled.
3. Metadata, tags, names, candidate notes, and destinations are developed while the record is still reviewable.
4. Knowledge notes describe what the material means.
5. Relation notes make important graph edges explicit.
6. Graph checks find missing or weak connections.
7. Records are renamed and filed only after semantic enrichment is complete.
8. The on-disk indexed root of `PKIM-Knowledge` keeps the whole thing portable.

The LLM layer performs judgement through skills. DEVONthink's in-app MCP server (v4.3+) performs the bounded reads, writes, validation, and extraction. DEVONthink remains canonical for records, notes, metadata, queues, groups, and item links.

## Task-based loading

| Task | Start with | Load next |
|---|---|---|
| Understand the project | [../README.md](../README.md) | [ops/repo-operating-model.md](ops/repo-operating-model.md), [design/README.md](design/README.md) |
| Start a work session | `skills/pkim-primer/SKILL.md` | [ops/operating-rhythm.md](ops/operating-rhythm.md) |
| Process inbox records | `skills/dt-intake/SKILL.md` | [design/05-workflows.md](design/05-workflows.md) if intent needed |
| Audit graph health | `skills/dt-audit/SKILL.md` | [design/05-workflows.md](design/05-workflows.md) Workflow 6 |
| Install / repair config | `skills/dt-bootstrap/SKILL.md` | [design/04-devonthink-operating-model.md](design/04-devonthink-operating-model.md) |
| Understand a record class or field | [design/02-information-model.md](design/02-information-model.md), then [design/03-record-and-note-specification.md](design/03-record-and-note-specification.md) | — |
| Change the model | [design/README.md](design/README.md) then the relevant numbered doc | ripple to skills |

## Context layers

| Layer | Read when | Documents |
|---|---|---|
| Orientation | Understanding what this project is | [../README.md](../README.md), [ops/repo-operating-model.md](ops/repo-operating-model.md) |
| Design intent | Deciding whether an idea fits PKIM | [design/README.md](design/README.md) |
| Operating cadence | Running a session, deciding what to do next | [ops/README.md](ops/README.md), [ops/operating-rhythm.md](ops/operating-rhythm.md) |
| Skill procedure | Executing a workflow | `skills/README.md` and the four `skills/*/SKILL.md` |
| Model or schema detail | Authoring a record, understanding a field | [design/02-information-model.md](design/02-information-model.md), [design/03-record-and-note-specification.md](design/03-record-and-note-specification.md) |
| Term lookup | Not sure what something means | [design/09-glossary.md](design/09-glossary.md) |

## Reading rule

Load broad context first, then narrow contracts:

1. Read the orientation for what you need.
2. Identify the workflow or skill.
3. Load only the relevant skill or design doc.
4. Load reference tables only when the current task touches them.
5. If a task requires reading the whole docs tree, the documentation structure has failed.

## Progressive disclosure

Design docs describe intent (shape, principle, non-negotiables). Skills carry procedure (workflow, sequencing, judgement). Ops docs describe cadence and environment. Terms are defined once, in the glossary. If two pages need the same fact, one page owns it and the other links.
