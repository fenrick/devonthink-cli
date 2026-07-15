# PKIM Skills

> **Runtime.** DEVONthink 4.3+'s in-app MCP server. See [../docs/design/24-dt-mcp-adoption.md](../docs/design/24-dt-mcp-adoption.md).

Four skills. Each is a named tool the LLM invokes explicitly — using named skills prevents the LLM from inventing its own version of a workflow. If you catch yourself composing ad-hoc DT MCP tool sequences that overlap one of these skills, invoke the skill instead.

## The four

### [`pkim-primer`](pkim-primer/SKILL.md) — always-on reference

**Read at the start of every session.** Establishes the shared vocabulary — record classes (EV / KN / RL / CL), tag axes, custom metadata schema, filing rules, cross-database WikiLink constraint — that every other PKIM skill and every ad-hoc DT MCP composition rests on. Carries no workflow.

Every other skill assumes this primer has been read.

### [`dt-bootstrap`](dt-bootstrap/SKILL.md) — install-and-repair

Idempotent installer for the canonical PKIM configuration in DEVONthink: group trees, custom metadata fields, text-predicate smart groups, note templates.

Fires only when the primer's preflight reports a gap — new machine, added database, or manual DEVONthink edit that broke a smart group.

### [`dt-intake`](dt-intake/SKILL.md) — the inbox sweep

Sweeps an `/Inbox` and fans out one Sonnet subagent per record for profile + enrichment + optional KN/RL authoring + filing. The parent orchestrates the batch and aggregates.

Use when: processing captures, triaging the inbox, "did you move the source files out of `/Inbox`".

### [`dt-audit`](dt-audit/SKILL.md) — graph-health

Walks six finding classes: broken RL endpoints, zombie claims (retired evidence still cited), corpus-level contradictions, dangling WikiLinks, orphan records, discipline violations.

Use weekly, before scaling ingest, or after a retirement/supersession wave. **Not** for operational reports (queue depth, metadata coverage) — those aren't part of PKIM's discipline surface.

## Cross-cutting rules

Documented once, in [`pkim-primer/SKILL.md`](pkim-primer/SKILL.md) §Core rules. Never duplicated elsewhere. Change the rule in one place; every skill inherits.

- DEVONthink is the system of record (no filesystem writes to `.dtBase2` packages).
- PKIM-Knowledge is indexed against an iCloud-synced on-disk root — that folder *is* the mirror.
- DT UUID is identity; PKIM_ID is a human-readable index.
- Cross-database references use item links, not WikiLinks.
- Every touched record ends up tagged (structural + topical axes).
- Write gate is DEVONthink's own (`Exclude from AI` / `Exclude from Chat & MCP`).

## Progressive disclosure

Every skill uses the same structure:
- `SKILL.md` — the workflow spec, always loaded when the skill triggers.
- `references/` — detail loaded on demand: the current task tells you which reference to pull.
- `assets/` — install-time content (only `dt-bootstrap/assets/` currently — the four note templates).

Don't front-load references. Read them on demand.

## Why so few skills

An earlier version of this directory had 26 skills built to sequence retired `pkim` atomic verbs. That layer is retired (see [../docs/design/24-dt-mcp-adoption.md](../docs/design/24-dt-mcp-adoption.md)). DEVONthink 4.3+'s MCP server is rich enough that most of what those skills orchestrated is now a single MCP tool call.

What remains are the four workflows that carry real judgement:

- Reading the primer (learning the model).
- Bootstrapping the configuration (installing the model).
- Sweeping the inbox (per-record judgement at scale).
- Auditing the graph (corpus-level discipline).

The one-skill-one-decision structure is deliberate. If a proposed skill would just wrap a single DT MCP tool with a rename, it's redundant. If it would just describe the model — that's [`pkim-primer`](pkim-primer/SKILL.md)'s job.
