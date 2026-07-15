# Runtime

## Purpose

How PKIM actually runs. The mechanism layer (DEVONthink's MCP server), the operational layer (skills), and how they compose.

## The runtime is DEVONthink's MCP server

DEVONthink 4.3+ ships an in-app MCP server (~65 tools). Every mutation of DEVONthink state — read, write, search, extract, classify — goes through it. There is no PKIM-owned runtime layer between skills and DEVONthink.

Requirements:

- macOS Sequoia or later.
- DEVONthink 4.3+ (Pro edition for the MCP server).
- An MCP-capable AI client (Claude Code, Codex CLI, or similar) with the DEVONthink MCP server registered.

Registration: DEVONthink's **Settings > AI > MCP** panel exposes the server's launch command. The client registers it once and the MCP tools become available under the `mcp__devonthink__*` prefix.

## What DT MCP does that PKIM doesn't need to

The DT MCP server carries a lot of responsibility the PKIM operating layer would otherwise have to build:

- **Type-safe writes.** `set_record_custom_metadata mode="merge"` preserves untouched fields, auto-registers new fields with the right type inferred from the value, and validates set-fields against their enum vocabularies.
- **File-as-truth on indexed records.** `update_record_content` writes the on-disk file for indexed records, keeps the database record coherent. No PKIM-side reconciliation needed.
- **Batch mode.** Reads and writes accept `uuids: [...]` for parallel application.
- **Search.** DT's query syntax spans boolean, wildcards, numeric, date, custom-metadata predicates, sub-criteria.
- **AI features.** `classify_record`, `find_similar_records`, `chat_response`, `research_topic` use DEVONthink's own ML.
- **Bibliographic enrichment.** `resolve_doi_metadata`, `resolve_book_metadata`, `download_pdf_from_doi`, `search_crossref`.
- **Content extraction.** `extract_record_content` handles PDFs, web archives, images with chunking and PII redaction. `ocr_record`, `transcribe_record` for scanned images and audio/video.
- **Exclusion enforcement.** Per-record `Exclude from AI` and per-database `Exclude from Chat & MCP` are honoured automatically. There is no bypass.

## Skills are the operational layer

Four named skills carry the workflow judgement. Each is a tool the LLM invokes explicitly.

| Skill | Role |
|---|---|
| `pkim-primer` | Session-start reference. Record classes, tag axes, metadata schema, filing rules, cross-DB WikiLink constraint. Every other skill assumes this has been read. |
| `dt-bootstrap` | Idempotent installer. Creates group trees, custom metadata fields, text-predicate smart groups, note templates. Fires only when the primer's preflight reports a gap. |
| `dt-intake` | Inbox sweep. Fans out one Sonnet subagent per record for profile + enrichment + optional KN/RL authoring + filing. Aggregates. |
| `dt-audit` | Graph-health check. Walks six finding classes: broken RL endpoints, zombie claims, corpus contradictions, dangling WikiLinks, orphan records, discipline violations. |

Full skill catalogue and progressive-disclosure structure in `skills/README.md`.

## Why named skills, not ad-hoc composition

DT MCP's tool surface is rich. An LLM could in principle compose `search_records` + `get_record_properties` + `set_record_custom_metadata` + `set_record_tags` + `move_record` on its own for every inbox record. It could. It also would drift — different orderings, different judgement about when to stop, different tag decisions across sessions.

Named skills are guardrails. When the LLM catches itself composing a DT MCP sequence that overlaps a skill's workflow, it invokes the skill. The workflow shape is preserved because it has a name.

This is why `dt-intake` exists even though its per-record work is only a dozen MCP calls. The value isn't the calls — it's the sequencing + judgement + subagent-fan-out pattern that makes 50 records processable in one sweep.

## Subagent fan-out

`dt-intake` runs a **subagent-per-record** pattern:

1. Parent skill enumerates the inbox via `search_records`.
2. For each record, parent spawns one Sonnet-tier general-purpose subagent with a per-record brief (UUID + tag rules + workflow reference).
3. Subagents run in parallel (batched in one tool call — cap ~8 to avoid MCP-server contention).
4. Each subagent returns a structured JSON summary: verdict (`filed` / `enriched-needs-review` / `needs-human` / `error`), actions taken, notes.
5. Parent aggregates.

Why:
- **Context isolation.** Each subagent gets one record's worth of context. No pollution from earlier records in the batch.
- **Explicit instructions.** The brief is exact — one record, one workflow, one outcome.
- **Sonnet not Opus.** Per-record judgement is bounded; a smaller model handles it cheaper and faster.
- **Parallelism.** A 50-record sweep is roughly 50 seconds of wall-clock, not 25 minutes.

`dt-audit` uses subagent fan-out selectively. Most of its finding-class walks are corpus-level queries that don't benefit from per-record subagents. Fan-out kicks in when the follow-up count exceeds ~50 and the per-record read + judgement is substantial (dangling WikiLinks or zombie claims on large corpora).

## Where policy lives

Design docs describe **intent** — what the system is, why it's shaped this way, what won't be violated.

Skills carry **operational policy** — how to do things, in what order, with what judgement.

There is no overlap by design. Reading a design doc tells you what the corpus should look like; reading a skill tells you how to make it that way. When the two disagree, the design doc is the source of truth for shape, and the skill is the source of truth for procedure.

## What retired to get here

The commit history has the trail. Briefly:

- A PyObjC + community-MCP bridge. Retired 2026-05.
- A Swift `pkim` CLI with 25 atomic verbs, custom write gate, run manifests. Retired 2026-07 after DEVONthink 4.3 shipped its own MCP server.
- 26 skills that sequenced the retired CLI. Collapsed to the four named above.

None of the retired layers survive in the current runtime. The design intent — DEVONthink as system of record, skills as the operational layer, safety through DEVONthink's own gates — is unchanged.

## Anti-patterns

- Introducing a PKIM-owned runtime layer between skills and DT MCP. DT MCP is the trusted layer.
- Wrapping DT MCP tools in "safer" helpers that add opinion.
- Recreating PKIM_ID as a runtime identity. It's a metadata field; DT UUID is identity.
- Skills that sequence DT MCP calls in ad-hoc combinations that overlap another skill's workflow. Invoke the skill.
- Sending records marked `Exclude from AI` to any AI-facing tool. DT MCP enforces this; skills should never work around it.
