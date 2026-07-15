# Glossary

Vocabulary index. Terms that appear across the design register + skills, defined in one place.

## Records

### evidence (EV)
Original source material, capture, archive, or referenced source object. Lives in `PKIM-Evidence-*` databases.

### knowledge note (KN)
Native markdown record in `PKIM-Knowledge` that interprets or synthesises evidence. `NoteType` sub-classifies as `literature` / `synthesis` / `topic` / `project` / `decision` / `workflow`.

### literature note
A KN focused on interpreting one source or a tightly bounded source set. Close reading; one KN per EV.

### synthesis note
A KN that draws together many EVs into a single argument or interpretation.

### topic note
A KN that defines what a concept means, what it excludes, and links to key related material.

### project note
A KN with a bounded scope — goal, context, status. Working context for a piece of work.

### relation note (RL)
First-class attributed edge between two records. Lives in `PKIM-Knowledge/Notes/Relations`. Has a `Relation_Type` from the closed vocabulary and a mandatory prose rationale.

### claim record (CL)
Individual claim promoted out of a KN's `## Claims` block into its own record. Exists so a claim can be tagged, cited, contradicted, and audited independently. Lives in `PKIM-Knowledge/Notes/Claims`.

### annotation
Source-adjacent working note attached to evidence. Working state, not canonical synthesis — if an annotation becomes durable, it graduates to a KN.

## Identifiers

### PKIM_ID
Human-readable identifier: `<CLASS>-YYYYMMDD-NNNN` (e.g. `KN-20260417-0021`). Stored as `mdpkim_id` custom metadata AND in the DT `Aliases` field. Minted once, never reassigned.

### DT UUID
DEVONthink's persistent identifier for a record. Opaque, unique across the whole system. Used in item links for cross-references.

### item link
`x-devonthink-item://<UUID>`. The clickable reference for cross-database references and for any context outside DEVONthink (mirror files, RL endpoint metadata).

### WikiLink
`[[Name|Display]]` in a note body. Resolves within one database only. Used for KN ↔ KN, KN ↔ CL, CL ↔ CL references inside `PKIM-Knowledge`.

## Metadata classification

### PROPERTY field
A custom metadata field describing a quality of the record itself. Passes the test: *if every other record disappeared, would this field still be meaningful?*

### INDEX-POINTER field
A custom metadata field pointing to another record's identity, but only where the same edge is already present as a body WikiLink. Removing the metadata does not remove the edge. Currently limited to `Source_Item`, `Target_Item` on RLs and `ParentKN_ID` on CLs.

### DERIVED field
A custom metadata field whose value is computed by automation from corpus state. Never authored by humans. Recomputable.

### edge-in-metadata (banned)
A scalar custom metadata field whose value is another record's PKIM_ID and whose intent is to express a relationship. Banned because DEVONthink doesn't treat custom metadata as graph data — the relationship would be invisible to See Also, back-references, and AI features.

## States

### review_state
Closed vocabulary controlling operational status. See [06 Operations And Safety](06-operations-and-safety.md).

### needs-human
The `review_state` value marking a record as awaiting an explicit human decision. Automation surfaces `needs-human` records in queues but never advances their state.

### error
Interrupt state. Set by automation when a run leaves inconsistent state. Requires operator review before proceeding.

### supersession
The pattern where a newer record renders an older one obsolete. Expressed as an RL of `Relation_Type: supersedes`; the older record's status flips to `superseded` (EV) or `archived` (KN/CL). Both records continue to exist.

## Claims

### claim
A single declarative statement in a KN's `## Claims` block or a CL record. Carries `type`, `confidence`, `evidence`, `contradicted_by`, optional `note`.

### claim type
Closed vocabulary: `fact` / `inference` / `assumption` / `open-question`.

### confidence band
Closed vocabulary: `low` / `medium` / `high`. Describes operational trust in the claim.

### claim ledger
The intermediate artefact built during Pass 3 of Workflow 3 (Evidence to Knowledge). A structured list of candidate claims from a set of EV records that the operator reviews before the KN is authored.

### zombie claim
A claim whose cited evidence has all retired or been superseded. The claim looks confidently backed but every citation is stale. The graph-health audit surfaces zombies.

### contradiction (corpus-level)
Two KNs citing the same EV with opposing edge classes (one supports, one contradicts), or two CLs on the same subject with mutually exclusive assertions.

## Tags

### structural tag
Slash-namespaced tag identifying the record's class and lifecycle state. Closed vocabulary per class (e.g. `pkim/knowledge`, `knowledge/type/synthesis`, `knowledge/status/reviewed`).

### topical tag
Slash-namespaced tag identifying what the record is *about*. Open vocabulary, shared corpus-wide, drawn from `domain/`, `concept/`, `entity/`, `source/`, `year/`, `method/` axes.

## Runtime

### DT MCP
DEVONthink 4.3+'s in-app MCP server. The runtime PKIM composes against. ~65 tools covering reads, writes, search, extraction, classification, bibliographic enrichment.

### skill
A named workflow the LLM invokes. Four exist: `pkim-primer`, `dt-bootstrap`, `dt-intake`, `dt-audit`. Skills carry judgement + sequencing; DT MCP tools carry mechanism.

### subagent fan-out
The pattern `dt-intake` uses — parent skill enumerates records, spawns one Sonnet-tier subagent per record with a scoped brief, aggregates returns. Batched in one message so subagents run in parallel.

### exclude from AI
DEVONthink property. Per-record or per-database. DT MCP honours it automatically — excluded records are filtered from result lists and refused as tool input.

## Mirror

### mirror
The on-disk indexed root of `PKIM-Knowledge`, iCloud-synced. Every KN/RL/CL is a `.md` file on disk. Portability surface for Git tooling, external editors, disaster recovery. Never authoritative — DEVONthink is.

### mirror drift
State where the on-disk file has been edited outside DEVONthink and the database index is stale. Detected by the `Mirror Drift` smart group; reconciled by DEVONthink's `Update Indexed Items`.
