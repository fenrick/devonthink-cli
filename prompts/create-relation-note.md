# Create Relation Note — Prompt Contract

## Purpose

Make an explicit, typed connection between two records and articulate why it exists. The relation note is not a pointer — it is the argument for the edge. A relation note without a real rationale is noise.

## Step 1 — Understand both records

Before choosing a relation type, read both the source and target records (use `pkim profile` or read directly). You need to understand what each claims before you can assert how they relate.

## Step 2 — Determine the relation type

Work through the vocabulary honestly. Most relations are not `references` — if you find yourself defaulting to it, you probably haven't articulated the connection yet.

| Type | When to use |
|---|---|
| `supports` | Source provides reasoning, evidence, or empirical grounding for target's claim |
| `contradicts` | Source challenges, refutes, or is in tension with target |
| `extends` | Source builds on or elaborates a point target makes |
| `summarizes` | Source is a compression or synthesis of target content |
| `references` | Source cites target; relationship is structural, not epistemic (use sparingly) |
| `exemplifies` | Source is a concrete case or instance of something target asserts |
| `precedes` | Source is logically or temporally prior to target |
| `supersedes` | Source replaces or significantly updates target |

If you cannot decide between two types, the ambiguity is information — put it in the rationale.

## Step 3 — Write the rationale first

Write the rationale before calling the CLI. A good rationale:

- Names the specific claim or passage in the source that creates the relation.
- Names what exactly in the target it connects to.
- States the logical or epistemic link — not just "these are both about X".
- Is one to three sentences. Longer is fine if the connection is complex.

A rationale that says "Source provides grounding for target" without saying *what* grounds *what* is not a rationale. A rationale that says "Allen's constraint that a Tickler File item must have a specific date forces explicit commitment, which supports the claim in KN-20260419-0005 that date-attachment is what separates deferred work from abandoned work" is.

## Step 4 — Dry run

```
pkim create-relation-note \
  --source "<source_ref>" \
  --target "<target_ref>" \
  --relation <relation_type> \
  --rationale "<your rationale — specific, named, argued>" \
  --format json
```

Review `draft_body`. The rationale you wrote should appear under `## Why This Relation Exists`. Check that source and target item links are correct.

Add `--reviewed` only if you have checked both records carefully and are confident in the relation. Default is `proposed`.

## Step 5 — Live write

```
pkim create-relation-note \
  --source "<source_ref>" \
  --target "<target_ref>" \
  --relation <relation_type> \
  --rationale "<rationale>" \
  [--reviewed] \
  --live \
  --format json
```

Confirm `result: ok`. Record the `PKIM_ID` for the new relation note.

## Inputs

| Input | Required | Notes |
|---|---|---|
| `source_ref` | Yes | Item link, PKIM_ID, or UUID |
| `target_ref` | Yes | Item link, PKIM_ID, or UUID |
| `relation_type` | Yes | Must be from the canonical vocabulary above |
| `rationale` | Yes | Specific, named, argued — not generic |
| `reviewed` | No | Flag; omit unless you have read both records carefully |

## Pre-conditions

- Both records exist and are reachable in DEVONthink.
- You have read both records, not just their titles.
- `rationale` names specific claims, not just topics.
- `PKIM-Knowledge/Notes/Relations/` group exists.

## Failure modes

| Condition | Action |
|---|---|
| Source or target not found | Abort; report which reference is unresolvable |
| `relation_type` not in vocabulary | Abort; list valid types |
| `rationale` empty | Abort; a relation note without rationale is invalid |
| `result: error` with `mismatch` list | Report fields; do not treat as success |
| You cannot articulate a specific rationale | Do not create the relation; the connection may not be real |
