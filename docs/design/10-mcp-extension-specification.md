# MCP Extension Specification

> **SUPERSEDED 2026-05-16** by [20 Bridge And MCP Architecture](20-bridge-and-mcp-architecture.md), and **further obsoleted 2026-05-20** by [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md).
>
> The "wrap and extend the vendored community MCP" stance recorded here was replaced first by an owned Python MCP transport (doc 20), and is now retired entirely: PKIM no longer treats MCP as the primary runtime. The runtime is a compiled CLI (doc 22); an MCP host integration, if needed, is a thin shim that `exec`s the CLI.
>
> The content below is retained for historical context only. Do not act on it.

## Purpose

This document defines how the existing community DEVONthink MCP should be expanded into a practical PKIM automation substrate.

The user requirement is not “use the MCP as-is.” It is to rapidly uplift LLM and MCP automation against a local DEVONthink installation until it becomes a practical second brain.

That requires more than merely consuming the posted server. It requires a deliberate extension plan.

## Assessment (2026-04-18)

`mcp-server-devonthink` v1.9.0 (dvcrn) was evaluated as an external optional transport. The companion `devonthink-cli` project is the same codebase extracted as a CLI; it adds no new capabilities and has the same custom metadata gap.

**Architecture assessment:** The MCP server is built on string-template JXA — JXA scripts generated via template literals and executed by spawning `osascript -l JavaScript` per call. This works but carries: string injection risk (partially mitigated by escaping), JXA quirks documented in the vendor CLAUDE.md (bracket notation required, no console.log, object literals return undefined), and a process-spawn-per-call performance model. The project is functional but built around workarounds.

**Key finding from sdef analysis:** DEVONthink exposes `customMetaData` as a read/write dictionary on every record. Setting any key writes to the corresponding custom metadata field; reading returns all defined fields as a dictionary. This single property closes the custom metadata write gap without additional workarounds.

**Decision:** Fork is retained as an optional future extension path, but the approved current write surface is the shared local command layer. Step 15 does not introduce a second transport. The authoritative routes remain the local wrapper commands backed by JXA and AppleScript where already proven.

## Starting Point

The approved automation surface is the shared local command layer. MCP remains useful as an optional transport and extension point, not as the required primary runtime.

The community MCP is already useful for:

- search
- record lookup
- content reads
- metadata reads
- tagging
- some creation and movement actions
- compare and classify

It is not, on its own, the finished system.

## Extension Strategy

### Wrap first

The first step is not to fork. It is to create a stable internal adapter that:

- probes the effective command surface
- normalizes responses
- adds safety rules
- hides tool volatility from prompts

### Add deterministic helpers

Where the MCP lacks a robust native action, implement local helpers and surface them through the same operator-facing command set.

### Fork only on real protocol need

Fork the MCP only if:

- required information cannot be obtained cleanly via wrapping
- helper indirection becomes more complex than a focused upstream change
- safety-critical write behaviour must live inside the transport layer

## Required Capability Domains

### Domain 1: Capability introspection

Needed because community MCPs drift.

Required operations:

- list tools
- inspect schemas
- record version and compatibility
- compare against a pinned expected capability set

### Domain 2: Native record profiling

Required operations:

- fetch content
- fetch properties
- search by query
- compare and classify
- list nearby or grouped records

### Domain 3: Metadata mutation

Required operations:

- set low-risk standard properties
- write custom metadata safely
- refresh and confirm post-write state

This is one of the most important extension gaps.

### Custom metadata write policy

- use native operations where possible
- use AppleScript/JXA helpers where MCP coverage is insufficient
- verify the refreshed record after every write

### Domain 4: Knowledge-note creation

Required operations:

- create native markdown note
- update existing note content
- attach or refresh metadata
- add aliases or stable lookup hooks

### Domain 5: Relation-note creation

Required operations:

- create relation note from template
- bind source and target item links
- refresh and verify

### Domain 6: Filing control

Required operations:

- propose destination
- replicate
- move under policy
- inspect indexed risk before mutation

### Domain 7: Mirror export support

Required operations:

- identify changed records
- extract canonical note content
- emit portable markdown
- produce export manifests

## Candidate New Internal Tools

These may exist as wrapper commands first and MCP tools later.

| Tool | Purpose |
| --- | --- |
| `probe_capabilities` | Build effective capability manifest |
| `write_custom_metadata` | Write and verify custom metadata fields |
| `create_knowledge_note_from_record` | Create or update a native knowledge note from evidence |
| `create_relation_note` | Create explicit relation records |
| `export_record_mirror` | Export a single native note to the mirror |
| `export_changed_mirrors` | Export a changed set with manifest |
| `evaluate_filing_policy` | Decide whether move or replicate is even allowed |
| `safe_move_record` | Policy-aware move with refresh verification |

## Current Routing Decision (Step 15)

The current write surface is deliberately conservative. Each write path has one approved route:

| Write path | Current route | Why this route is authoritative now |
| --- | --- | --- |
| `pkim apply-metadata` | JXA only | Custom metadata read/merge/write and refresh verification are already reliable through `customMetaData`. |
| `pkim create-knowledge-note` | AppleScript create + JXA enrich | AppleScript handles markdown record creation reliably; JXA then sets body and metadata with refresh verification. |
| `pkim create-relation-note` | AppleScript create + JXA enrich | Same proven pattern as knowledge-note creation; no second transport adds value yet. |
| `pkim ensure-group-path` | AppleScript create location + JXA validate | AppleScript is the stable create path for groups; JXA handles preflight and verification. |
| `pkim safe-file` | JXA only | Policy evaluation, move/replicate, indexed path checks, and post-write verification already live here. |
| `pkim sync-mirror` | JXA only | The command surface already reads and updates canonical note state through JXA. |

The capability manifest now records both the authoritative command list and the write-route summary. That keeps the route decision machine-readable instead of burying it in prose.

## What Requires MCP Extension

Keep this list short and explicit:

- only future routes that cannot be handled cleanly by the current command layer
- transport consolidation only if reliability improves materially
- any new MCP-native path must preserve the existing command contracts instead of bypassing them

## Wrapper vs MCP-native Decision Matrix

| Need | Wrapper is enough | Needs MCP or helper change |
| --- | --- | --- |
| schema probing | yes | no |
| dry-run policy gating | yes | no |
| run logging | yes | no |
| custom metadata writeback | yes | no |
| native note templating | yes | no |
| relation-note creation | yes | no |
| export mirror generation | yes | no |
| indexed path risk checks | yes | no |

## Internal Contract For Wrapped Actions

Every wrapped action should expose:

- a stable input shape
- a stable output shape
- explicit dry-run support where mutation exists
- explicit before/after state for writes
- machine-readable errors

Example internal contract:

```json
{
  "action": "write_custom_metadata",
  "dry_run": true,
  "target": {
    "pkim_id": "EV-20260417-0007",
    "dt_uuid": "..."
  },
  "requested_changes": {
    "Review_State": "approved",
    "PrimaryTopic": "PKIM design"
  },
  "policy_result": {
    "allowed": true,
    "risk_level": "low"
  }
}
```

## Capability Manifest

The system should maintain a committed capability reference document or generated artifact that records:

- pinned MCP package/version
- effective command list
- authoritative write-route summary
- commands relied on by the system
- local helper replacements where native MCP support is missing
- compatibility notes

This manifest should be regenerated intentionally, not casually.

## Scratch Validation Requirements

Before using any live write feature:

1. run capability probe
2. validate scratch database connectivity
3. run representative write test
4. verify post-write state
5. verify mirror and logging side effects if relevant

## Prompting Implications

The agent should not be told to “figure it out from the raw tool list” every time. That is how systems become inconsistent and dangerous.

Instead:

- wrap low-level volatility behind stable commands
- document the contracts
- let prompts focus on intent, not protocol archaeology

## Extension Deliverables

The finished extension program should leave behind:

- wrapper scripts or services
- helper scripts for metadata and export gaps
- capability manifest
- tests
- prompt templates
- operational runbooks

## Step 15 Result

The current result is:

1. one authoritative local command surface
2. one machine-readable capability manifest that includes command and write-route coverage
3. no silent second transport for existing write paths
4. MCP retained as optional extension transport rather than hidden runtime dependency
