# PKIM Skills

> **Runtime.** DEVONthink 4.3+'s in-app MCP server. See [../docs/design/24-dt-mcp-adoption.md](../docs/design/24-dt-mcp-adoption.md).

Three skills. Each is a named tool the LLM invokes explicitly — using named skills prevents the LLM from inventing its own version of a workflow. If you catch yourself composing ad-hoc DT MCP tool sequences that overlap one of these skills, invoke the skill instead.

## The three

### [`pkim-orient-and-setup`](pkim-orient-and-setup/SKILL.md)

**Read at the start of every session.** Establishes the shared vocabulary (record classes, tag axes, metadata schema, filing rules, cross-database WikiLink constraint) and installs the canonical PKIM configuration in DEVONthink if any of it is missing.

Every other skill assumes this one has been read. It's the base layer — don't duplicate its content in the other skills.

### [`dt-intake`](dt-intake/SKILL.md)

**The inbox → filed record walk.** Sweeps a database's `/Inbox`, dispatches one Sonnet subagent per record for profile + enrichment + optional KN/RL authoring + filing, aggregates results.

Use when: processing captures, triaging the inbox, "did you move the source files out of `/Inbox`".

### [`dt-audit`](dt-audit/SKILL.md)

**Graph-health check.** Broken RL endpoints, dangling WikiLinks, zombie claims (retired evidence still cited), corpus-level contradictions, orphan records, discipline violations.

Use weekly, or before scaling ingest, or after a retirement/supersession wave. Not for operational reports (queue depth, metadata coverage) — those aren't part of PKIM's discipline surface.

## Cross-cutting rules

The rules that every skill honours. Each is documented once (in the location noted); do not duplicate.

- **Every touched record must be tagged.** Structural + topical axes. See [`pkim-orient-and-setup/references/tag-axes.md`](pkim-orient-and-setup/references/tag-axes.md).
- **RLs are first-class edges, not prose.** Every semantically load-bearing connection between records is an RL, not a `[[…]]` in a bullet list. See [`dt-intake/references/rl-authoring.md`](dt-intake/references/rl-authoring.md).
- **Cross-database references use item links, not WikiLinks.** See [`pkim-orient-and-setup/references/wikilink-and-item-link.md`](pkim-orient-and-setup/references/wikilink-and-item-link.md).
- **`set_record_custom_metadata` always with `mode="merge"`.** `replace` drops every field not in the payload — footgun.
- **File only after enriching.** A record leaves `/Inbox` only when metadata + tags + destination are settled.

## Assets and references

Each skill's `references/` holds progressive-disclosure detail — the SKILL.md is the entry doc, the references answer specific mid-workflow questions. `assets/` holds files the skill installs into DEVONthink (canonical templates, config).

Don't front-load references. Read them on demand.

## Why so few skills

An earlier version of this directory had 26 skills built to sequence pkim-verb calls. That layer is retired (see [../docs/design/24-dt-mcp-adoption.md](../docs/design/24-dt-mcp-adoption.md)). DEVONthink 4.3+'s MCP server is rich enough that most of what those skills orchestrated is now a single MCP tool call. What remains are the three workflows that carry real policy: orientation + setup, per-record intake with subagent fan-out, and graph audit.

The one-skill-one-decision structure is deliberate. If a proposed skill would just wrap a single DT MCP tool with a rename, it's redundant. If it would just describe the model — that's [`pkim-orient-and-setup`](pkim-orient-and-setup/SKILL.md)'s job.
