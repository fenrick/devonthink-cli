---
name: dt-profile-record
description: Read one DEVONthink record and produce a read-only PKIM profile packet with a deterministic concept set, candidate graph, and staged graph-build scaffolding. Make sure to use this skill whenever the user asks to profile, analyse, classify, triage, or draft graph-ready note scaffolding for a DEVONthink record.
compatibility: Works in any runtime that can read a DEVONthink record and optionally access compare/classify signals. The local `pkim profile` command is the preferred deterministic tool path when available.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-profile-record

This skill exists because dense records rarely map cleanly to one note. The job is no longer "find the note". The job is to interpret the source into a concept set that downstream note resolution and edge-building can act on safely.

## What this skill is for

Use it to answer:

- what this record is
- what distinct concepts it contains
- which concepts are strong enough to become canonical note candidates
- which concepts are deferred, supporting, or only edge-support
- what candidate graph the source implies before any write action happens

The output is a read-only concept-set assessment, not a note mutation.

## Why this matters

Profiling is the point where raw evidence becomes structured candidate work. If this step collapses distinct concepts too early or invents certainty it does not have, every downstream note and relation decision gets worse.

## Preconditions

- **OCR readiness for image/scan-class records.** If the record is a PDF without an OCR text layer (or a scan, or any kind whose `plainText` is empty), profiling produces an empty concept set and the skill cannot proceed honestly. Run OCR before profiling, or — if OCR is not available — flag the record `Review_State=needs-human` with a one-line comment explaining why. Do **not** invent a concept set from filename or DT classify groups alone.
- **The record exists in DEVONthink.** Anything that needs to come from a filesystem path must be ingested first.

## Candidate-triage checkpoint (inline restatement)

This skill's output drives the candidate-triage checkpoint defined in [`05-workflows.md` §Workflow 3](../../docs/design/05-workflows.md#candidate-triage-checkpoint). Only candidates with **all four** of the following advance automatically to `dt-resolve-canonical-note`:

| Field | Required value |
| --- | --- |
| `candidate_class` | `canonical-note-candidate` |
| `note_worthiness` | `high` |
| `distinctness` | `distinct` |
| `graph_value` | `node` |

Anything else (`medium`, `overlapping`, `embedded`, `edge-support`, `local-detail`, `supporting-detail`, `evidence-for-other-note`) is recorded in the candidate ledger with `triage_outcome=deferred` and waits for explicit operator elevation. Deferred candidates are not silently dropped — they remain visible in the ledger and re-trigger on corroborating evidence.

## Workflow

1. Resolve the source record and read the command packet from `pkim profile --record "<ref>" --format json`.
   - **For records that already exist in the corpus** (you want the dependency picture, not the discovery work): run `pkim deep-profile --record "<ref>" --format json` instead. It composes the bridge metadata, parsed `## Claims` block, mirror dependency graph (inbound + outbound citations with edge class + source section), audit-discipline findings against the record, and field-classification status. Use the discovery profile when the record is unprofiled; use deep-profile when you want to understand how the record sits in the existing graph.
2. Read the source content, metadata, compare neighbours, and candidate concept set.
   - **For long documents** (more than ~5000 words, 10 pages, or any PDF/book-length source): the profile command reads only a shallow excerpt. Use `pkim extract-text --record "<ref>" --format json` to extract the full text, then read the introduction, section headings, and conclusion before forming the concept set. Do not rely on DEVONthink's summary or the first screen alone — dense books will appear to have one weak candidate when they contain nine strong ones.
3. Review each `candidate_notes[]` entry:
   - confirm the concept is distinct, deferred, supporting, or edge-support
   - confirm its note-worthiness and dependency type
   - confirm the proposed existing neighbours are plausible
4. Review each `candidate_edges[]` entry:
   - confirm the proposed relation type is defensible
   - confirm the source anchors actually support the edge
   - confirm whether the edge should remain blocked until candidate resolution
5. Produce a read-only assessment over the concept set:
   - which candidates should enter canonical resolution now
   - which should be deferred
   - which edges are promising but blocked
6. If the user wants execution, hand off to the staged downstream flow:
   - `dt-resolve-canonical-note` per candidate
   - `dt-build-knowledge-note` per resolved candidate
   - `dt-build-relation-note` after edge rebinding
   - `dt-reconcile-relation-edge`
   - `dt-inspect-graph-neighbourhood`

## How to know you are doing it right

You are doing this skill correctly when:

- simple documents remain a 1-candidate special case
- dense documents yield multiple candidates without forcing them all into note creation
- candidate IDs and fingerprints are preserved in the assessment
- candidate-to-candidate and candidate-to-existing-note edges are both explicit
- no write decision is made from profiling alone

You are doing it badly when:

- every meaningful paragraph becomes a note candidate
- the source still effectively produces one privileged note and everything else becomes commentary
- candidate dependencies are inferred ad hoc rather than read from the packet
- blocked edges are silently dropped

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `mcp__devonthink__set_record_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## MANDATORY: relation notes (RL) are part of every end-to-end walk

A Workflow-3 walk that produces a KN + N CLs but zero RLs is **incomplete**. Every cross-citation in a CL's reasoning prose, every KN-to-KN topical overlap, every claim that corroborates / contradicts / extends / exemplifies / supersedes an existing record must be expressed as a first-class RL record — not just hinted at in prose.

Why this matters:
- The mirror graph's edges, contradiction detection, and supersession propagation all run over RL records, not over prose hints.
- WikiLinks inside CL reasoning are informal; RLs are auditable, taggable, and survive refactor-on-touch.
- Without RLs, the corpus is a collection of independent literature notes; with RLs, it becomes the connected argument the project is for.

**How to apply** at every walk:
- For each CL whose reasoning cites another KN or CL, mint an RL with the appropriate `Relation_Type` (supports / contradicts / extends / exemplifies / summarizes / references / precedes / supersedes — closed vocabulary, see doc 08).
- For each KN pair sharing substantive topical overlap, mint an RL capturing the connection.
- File RLs at `/Notes/Relations/` (indexed alongside `/Notes/Claims/` and `/Notes/Literature/`).
- Tag RLs per the canonical axes: `pkim/relation`, `relation/type/<…>`, `relation/status/<proposed|reviewed>`, `relation/confidence/<low|medium|high>`, plus inherited topical tags from both endpoints.

If no cross-citations exist for a fresh CL set, that's a profiling gap — pause and surface to the operator rather than silently producing an isolated KN.

## What not to do

- Do not write to DEVONthink.
- Do not bypass candidate triage and jump directly to note creation.
- Do not treat compare/classify as truth.
- Do not collapse the concept set back into one note just because the old workflow expected that.
- Do not materialize edges from this skill.
- Do not rely on the profile command's shallow excerpt for dense PDFs or books. If the document is long, always run `extract-text` first.

## Output

Produce a read-only assessment keyed by the command packet's candidate IDs and fingerprints. The output should explicitly state:

- `ready_for_resolution_candidates[]`
- `deferred_candidates[]`
- `supporting_candidates[]`
- `blocked_edges[]`
- `execution_notes`

Use the command packet's `candidate_notes[]`, `candidate_edges[]`, and `candidate_resolution_map[]` fields as the canonical shared surface.

## Preferred tool path

```bash
pkim profile --record "<ref>" --format json
```

Read `prompts/profile-record.md` for the full command-level field contract.
