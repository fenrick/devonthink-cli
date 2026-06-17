# Principles And Decisions

## Purpose

This document defines the non-negotiable design principles and core architectural decisions for PKIM.

Use it when deciding whether a proposed workflow, automation path, or filing policy fits the system. Do not use it for command syntax, schema detail, or run sequencing.

## Design Principles

### Authority model

- DEVONthink is authoritative for native records, metadata-in-context, item links, queues, and note state.
- The repo is authoritative for automation code, schemas, prompts, tests, logs, and export logic.
- The export mirror is authoritative only as a portability and publishing representation, never for in-app state.

### DEVONthink-first, not DEVONthink-only

DEVONthink is the canonical environment for evidence, knowledge notes, relation notes, metadata, links, queues, and local review. The repository exists to support design, automation, exports, testing, and operational control around that environment.

### Native knowledge, portable mirrors

Knowledge notes are authored and maintained as DEVONthink Markdown records. Exported markdown mirrors exist so Git, LLM tooling, and external scripts can work against normal files without treating the database package as an editable filesystem.

### What this system is not

This is a document-and-link graph with structured relation notes. It is not a native property-graph database.

### Separate evidence from knowledge

Evidence records preserve originals, captures, and references. Knowledge records hold summaries, synthesis, relation notes, and operator-authored thinking. The system is easier to automate when those object types have different rules.

### Deterministic local automation

Agent orchestration must compose deterministic local tools, not rely on opaque client-side magic. Where the community MCP is insufficient, add small local adapters with explicit contracts and tests.

The shared local command surface is the approved operator path. MCP is optional transport, not the required primary runtime.

### Safety over convenience

Read actions can be liberal. Writes must be approval-gated, auditable, and reversible. Delete, move, and metadata mutation are privileged operations.

### Concentrated context

Use multiple focused databases rather than one giant dumping ground. Knowledge quality, DEVONthink AI utility, and automation reliability all get worse when context is diluted.

### Native first, repo second

Smart groups, smart rules, metadata overview sheets, and native DEVONthink queues are the default operational views. Move queue or status handling outward only when native DEVONthink stops short.

## Core Decisions

### Canonical note format

- Canonical in-app format: DEVONthink Markdown documents with MultiMarkdown metadata headers.
- Canonical external mirror format: regular markdown files with explicit frontmatter or generated metadata blocks as needed by tooling.

### Stable identity

- Mint `PKIM_ID` once.
- Use `DT_UUID` and `x-devonthink-item://` links as the native reference layer.
- Treat file paths as descriptive, never authoritative.

### External control planes

- No mandatory Notion or other SaaS layer.
- If collaboration later requires one, it must mirror from stable identifiers rather than replace DEVONthink state.

### MCP strategy

- Start from the existing community DEVONthink MCP.
- Extend outward with local helpers and wrappers before considering a hard fork.
- Fork only when the protocol surface itself must change.

### Repo role

This repo owns:

- evergreen design docs
- automation contracts and prompts
- scripts and adapters
- tests
- exported mirrors and manifests, when those are intentionally committed

### Ontology control

Do not let tags, relation types, note types, review states, or queue names drift into an uncontrolled ontology. Extend them only through an explicit reviewed schema change.

### Decision 2026-05-16 — Graph edges live in note bodies

**Statement.** Graph edges live in note bodies as `[[PKIM_ID|Name]]` WikiLinks. Custom metadata describes properties of the record, not relationships to other records.

**Rationale.** DEVONthink's native graph awareness — See Also, back-references, item-link traversal, AI suggestions — operates over body content, WikiLinks, item links, and replicants. Custom metadata fields are flat scalars invisible to those mechanisms. Storing a relationship as a metadata field (e.g. a scalar `RelatedTo=KN-123`) is fake graph: it costs schema surface and gives nothing back in DT's UI, search, or AI features. The principle keeps the system honest about what DT can and cannot do, and concentrates the graph where DT actually reads it.

**Allowed exceptions.**

- **Identity pointers on relation notes** (`Source_Item`, `Target_Item`) are indexing aids that duplicate body WikiLinks. They are not edges themselves; the body WikiLinks are.
- **Derived dashboard counters** computed by the export mirror (e.g. `Claim_Backed`, evidence counts) are properties of the record, written back from analysis. They must not be authored by humans or treated as authoritative graph data.

**Banned patterns.**

- Any metadata field whose value is another record's `PKIM_ID` and whose intent is to express a relationship (e.g. `RelatedTo`, `Supersedes`, `Contradicts` as scalar pointers on the source record).
- Comma-separated lists of `PKIM_ID`s in metadata used as adjacency lists.
- Custom metadata used as a substitute for a relation note.

**Where this is implemented and enforced.** See [19a Metadata Is Not The Graph](19a-metadata-is-not-the-graph.md) for the rationale in full, [03 Information Model](03-information-model.md) for the structural rules, [08 Record And Note Specification](08-record-and-note-specification.md) for the contract changes, and [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.2–WP0.4 for the audit and enforcement work packages.

### Decision 2026-05-16 — MultiMarkdown headers are the canonical native note format

**Statement.** Native DEVONthink Markdown notes use MultiMarkdown (MMD) metadata headers at the top of the file, not YAML frontmatter. The export mirror continues to use YAML frontmatter for portability with external tooling.

**Rationale.** DEVONthink natively parses MMD metadata headers and maps the standard keys (`Title`, `Aliases`, `Tags`, `Author`, `Keywords`, `URL`, `Date`) into its corresponding native properties. YAML frontmatter does not receive the same treatment — it sits in the body as opaque text. Using MMD headers gives DT the canonical hooks it needs (especially `Aliases` for `PKIM_ID` discovery) without round-tripping through scripted metadata writes. PKIM-specific custom metadata fields (`PKIM_ID`, `DocRole`, `Review_State`, `KnowledgeStatus`, etc.) continue to be set via JXA on the DT record; the MMD header carries them as human-readable lines for portability but is not the authoritative store for them.

**Reverses.** The earlier anti-pattern entry in [08 Record And Note Specification](08-record-and-note-specification.md) §Anti-Patterns that listed MultiMarkdown metadata headers as a format to avoid. That entry is removed in this change.

**Scope.**

- Native notes (KN, RL, topic, project, annotation): MMD headers at the top, separated from body by a blank line.
- Mirror files: YAML frontmatter remains the canonical format. The mirror exporter translates MMD → YAML.
- The two formats remain semantically equivalent; round-trip parity is testable.

**Where this is implemented and enforced.** See [08 Record And Note Specification](08-record-and-note-specification.md) §Native Knowledge Note Spec and §Relation Note Spec for the updated templates; [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.5 for the migration; [00 Source Reconciliation](00-source-reconciliation.md) for the explicit reversal of the prior anti-pattern.

### Decision 2026-05-16 — PyObjC ScriptingBridge replaces JXA as the canonical transport to DEVONthink

**Statement.** PKIM's transport to DEVONthink is PyObjC + `ScriptingBridge.framework`, dispatched in-process. The `osascript`-spawning JXA layer at `src/pkim/jxa.py` is deprecated and retained only as a short-term fallback for write paths until they are ported. New code does not import it.

**Rationale.** Every JXA call forks `osascript`; corpus-wide reads (graph audits, mirror sync, claim ledger construction) are dominated by that fork/exec cost rather than DEVONthink's actual work. ScriptingBridge dispatches Apple Events in-process and returns typed Cocoa objects, removing the subprocess boundary and the per-call serialisation tax. The result is a typed, debuggable, mypy-checkable surface that can be exercised without spawning a shell.

**Implications.**

- `src/pkim/bridge/` is the only module permitted to import `ScriptingBridge`, `Foundation`, `AppKit`, or `objc`.
- The bridge package owns conversion (`bridge/convert.py`) and exceptions (`bridge/errors.py`).
- Reads are migrated first; writes follow once the gate model is wired through (see [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6g).

**Where this is implemented.** [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), `src/pkim/bridge/`, [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6 sub-sequence.

### Decision 2026-05-16 — `dt-pkim-mcp` replaces the vendored community DEVONthink MCP

**Statement.** PKIM owns its MCP transport. A new server, `dt-pkim-mcp`, is built in Python on the official `mcp` SDK and shares the bridge / domain / commands stack with the existing CLI. The vendored `mcp-server-devonthink` v1.9.0 is retired and removed once `dt-pkim-mcp` reaches parity with the read surface PKIM uses.

**Rationale.** The vendored MCP is built on string-template JXA. Sitting on top of it would compound the very fork/exec problem the bridge decision removes, and would keep the string-injection surface and JXA quirk catalogue in the workflow. DEVONthink themselves have started canvassing the community about what an official MCP should do; building our own well-typed server is the better foundation regardless of where the upstream lands. Owning the MCP also lets PKIM expose synthesis-aware tools (claim ledgers, audit reports, contradiction registers) that have no equivalent upstream.

**Supersedes.** [10 MCP Extension Specification](10-mcp-extension-specification.md). The "wrap first, fork only when the protocol surface itself must change" stance is replaced by "own the MCP, share the bridge."

**Where this is implemented.** [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), `src/pkim/mcp/`, [19 Synthesis Uplift Plan](19-synthesis-uplift-plan.md) WP0.6f.

### Version targeting

If a feature claim is based on newer DEVONthink 4.2.x material while the operational target is still 4.1, the docs must say so plainly. “Probably similar” is not the same as “validated locally.”
