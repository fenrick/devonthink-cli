# Create Knowledge Note — Prompt Contract

## Purpose

Turn a piece of evidence into a knowledge note that captures what you actually think about it — not what the document says, but what it means. The CLI handles the mechanical write; your job is the synthesis.

## Step 1 — Read the source

Run `pkim profile --record <source_ref> --format json` and read the full `plainText` from the result (or read the document directly if accessible). Do not proceed until you have read enough to synthesize.

## Step 2 — Synthesise before writing

Answer these questions in your own words before drafting anything:

1. **Main claim**: What is the central argument or finding? One sentence, not a description of what the document covers.
2. **Why it matters**: What does this add to the knowledge base? What question does it answer or complicate?
3. **Connections**: Does this support, contradict, extend, or exemplify anything already in the system?
4. **Note type**: Which type fits — `literature` (reading notes on a source), `synthesis` (your own synthesis across multiple sources), `topic` (a concept or subject anchor), `project` (project-bound thinking)?

A summary that begins "This document discusses..." is not synthesis. A summary that begins "Allen's Tickler File is a forcing function for date-commitment..." is.

## Step 3 — Extract key points

Before calling the CLI, extract three to six key points from the source — specific, concrete claims or facts that ground the summary. Key points are not sub-headings of the document; they are the atomic assertions that matter.

Good key point: "Filing into the Tickler requires choosing a specific date — undated items cannot enter the system."
Weak key point: "The Tickler File is explained in detail."

## Step 4 — Dry run

```
pkim create-knowledge-note \
  --source "<source_ref>" \
  --note-type <note_type> \
  --title "<title that names the thought, not the filing location>" \
  --summary "<one paragraph — your synthesis, not a description>" \
  --key-points "<point one>
<point two>
<point three>" \
  --format json
```

Pass `--key-points` as a newline-separated string. The exact quoting needed to embed newlines depends on your shell or execution context; the value must be newline-separated regardless. Review the `draft_body` — summary and key points should both appear with real content. Do not proceed to live write if either is empty or generic.

## Step 5 — Live write

Add `--live` to the same command (requires `PKIM_ALLOW_PRODUCTION_WRITES=true`).

```
pkim create-knowledge-note \
  --source "<source_ref>" \
  --note-type <note_type> \
  --title "<title>" \
  --summary "<summary>" \
  --key-points "<point one>
<point two>
<point three>" \
  --live \
  --format json
```

Confirm `result: ok` and record the `uuid` and `PKIM_ID` from the output.

## Quality bar for the summary

- States a claim or insight, not a description of the source structure.
- Specific enough to be useful without opening the source.
- One paragraph — three to six sentences.
- Written in first or neutral voice ("Allen argues...", "The key insight is...", not "This document contains...").
- Does not repeat the title.

## Inputs

| Input | Required | Notes |
|---|---|---|
| `source_ref` | Yes | Item link (`x-devonthink-item://...`), PKIM_ID, or UUID |
| `note_type` | Yes | `literature`, `synthesis`, `topic`, `project` |
| `title` | Yes | Names the thought, not the filing location |
| `summary` | Yes | Agent-synthesised paragraph — see quality bar above |
| `key_points` | Yes | Newline-separated atomic claims from the source — not sub-headings |

## Pre-conditions

- Source record exists and is reachable in DEVONthink.
- `PKIM-Knowledge` is open and `/Notes/<note_type>/` group exists.
- You have read the source, not just its title.

## Failure modes

| Condition | Action |
|---|---|
| Source record not found | Abort; report unresolvable reference |
| `result: error` with `mismatch` list | Do not treat as success; report fields and values |
| `draft_body` summary is empty | Fix `--summary` before going live |
| Note type not valid | Use one of: `literature`, `synthesis`, `topic`, `project` |
