# Design Register

## Purpose

The evergreen design contract for PKIM. Nine documents, each answering one question. Read them in order the first time; refer to them by number thereafter.

## The nine

| Doc | Answers |
|---|---|
| [01 Purpose And Principles](01-purpose-and-principles.md) | Why does PKIM exist? What won't be violated? |
| [02 Information Model](02-information-model.md) | What kinds of records exist? What identities matter? |
| [03 Record And Note Specification](03-record-and-note-specification.md) | What are the exact fields, note templates, and validation rules? |
| [04 DEVONthink Operating Model](04-devonthink-operating-model.md) | How is PKIM shaped inside DEVONthink? Databases, groups, smart groups, filing? |
| [05 Workflows](05-workflows.md) | How does material move through the system? |
| [06 Operations And Safety](06-operations-and-safety.md) | What are the write gates, review states, and supersession rules? |
| [07 Runtime](07-runtime.md) | How does PKIM actually run? DT MCP + four skills. |
| [08 Repo Hygiene](08-repo-hygiene.md) | What lives in this repo? What gets committed? |
| [09 Glossary](09-glossary.md) | Local vocabulary — one place to look up a term. |

## Reading order

**New to PKIM.** Read 01 → 02 → 04 → 05 → 07 in order (why, what, where, how, runtime). Skim 03, 06, 08, 09 as reference.

**Operating a session.** Skills carry procedure; design docs describe intent. In a live session you rarely need to open a design doc — the primer skill (`skills/pkim-primer`) has the operational content.

**Changing the model.** Any structural change (record class, tag axis, metadata field, workflow) starts in the relevant design doc, then ripples to the skills. The design doc is the source of truth for shape; skills follow.

## Load lean

Never load the whole design pack before acting. The nine docs are numbered so a task can name the smallest useful context:

| If the question is about... | Read |
|---|---|
| Whether an idea fits PKIM's intent | 01 |
| What kind of record something should be | 02, then 03 for the schema |
| A specific field or template | 03 |
| Where a record lives in DEVONthink | 04 |
| How to move a record through its lifecycle | 05 |
| Write safety or review state | 06 |
| How skills compose DT MCP | 07 |
| What to commit or gitignore | 08 |
| A term you can't remember | 09 |

## Relationship to skills

Design docs describe **intent** — what the system is, why it's shaped this way, what won't be violated.

Skills in `skills/*/SKILL.md` carry **operational policy** — how to do things, in what order, with what judgement.

Skills are self-contained; they don't link out to design docs. Design docs cross-reference each other freely but don't reach into skills. When intent and procedure disagree, the design doc is the source of truth for shape and the skill is the source of truth for procedure.

## Authority model

- **DEVONthink** is authoritative for records, native metadata, item links, queues, and canonical content.
- **This repo** is authoritative for design, skills, prompts, and operational history — not for canonical data.
- The **on-disk indexed root** of `PKIM-Knowledge` (iCloud-synced) is a portability surface. It reflects what's in DEVONthink; it is not authoritative on its own.
