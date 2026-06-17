---
name: dt-resolve-canonical-note
description: "Resolve one candidate concept against the existing knowledge graph and return a candidate-scoped decision: create, update, merge, supersede, or inconclusive. Make sure to use this skill before any candidate note mutation."
compatibility: Works in any runtime that can read the PKIM-Knowledge database, search by alias/title, inspect compare neighbours, and carry session context from the profile concept set.
---

# dt-resolve-canonical-note

This skill now resolves **one candidate concept at a time**.

## What this skill is for

Use it to decide whether one candidate from `candidate_notes[]` should:

- create a new canonical note
- update an existing note
- merge into a survivor note
- supersede an outdated note
- stop as inconclusive

The output is a candidate-scoped resolution packet, not a note mutation.

## Why this matters

Candidate resolution is where the system decides whether a concept deserves its own canonical identity or belongs inside something that already exists. If that decision is sloppy, the graph bloats with duplicates or compresses distinct ideas into the wrong note.

## Required inputs

- the source `ProfilePacket`
- one `candidate_notes[]` entry
- the current session resolution map
- any already-resolved upstream candidate mappings

## Workflow

1. Read the candidate concept packet.
2. Search for existing note candidates using:
   - candidate title terms
   - candidate fingerprint-adjacent terms
   - compare neighbours from the source profile
   - any notes already materialized earlier in the same session
3. Assess overlap against current notes.
4. Return exactly one resolution decision for this candidate.
5. Record whether the candidate is blocked by unresolved upstream candidate dependencies.

## How to know you are doing it right

You are doing this skill correctly when:

- the result is one candidate-scoped decision
- overlap is judged against the current graph and the current session mapping
- blocked dependencies are explicit rather than implied

You are doing it badly when:

- you resolve multiple candidates at once
- you ignore notes already created earlier in the same session
- you treat loose thematic similarity as proof of duplication

## Output

Return a resolution packet with:

- `candidate_id`
- `candidate_fingerprint`
- `resolution`
- `target_note`
- `merge_candidates`
- `blocking_dependencies[]`
- `rationale`

Valid `resolution` values:
- `create`
- `update`
- `merge`
- `supersede`
- `inconclusive`
- `blocked-by-dependency`

Use `blocked-by-dependency` when the candidate cannot yet be resolved because its upstream candidate dependency has not completed.

## MANDATORY: tag the record before returning success

Every record this skill creates, transitions, or touches must end up with the canonical slash-namespaced tag set applied via `DTWriter.set_tags`. This is non-negotiable — see [_shared/tagging-discipline.md](../_shared/tagging-discipline.md) for the full per-class axes table and inheritance rules.

Minimum check before this skill can declare success:
- Structural tags for the record's class are set (`pkim/<class>`, plus the class-specific type/status/confidence axes).
- At least one `concept/<…>` topical tag is set; `domain/`, `entity/`, `source/`, `year/` axes filled where the evidence supports them.
- Aliases include the PKIM_ID (semicolon-joined with the display name).
- For indexed records, the file's `Tags:` MMD header matches the DT-side tag set.

If meaningful topical tags cannot be determined, **pause and surface to the operator** rather than skipping. Untagged records are invisible to DT's navigation surface.

## What not to do

- Do not resolve the whole source document at once.
- Do not ignore the session’s candidate-to-note mapping.
- Do not treat thematic similarity alone as overlap.
- Do not mutate notes from this skill.

## Preferred tool path

```bash
# Typed search via the PyObjC ScriptingBridge transport (preferred).
scripts/pkim search --database "PKIM-Knowledge" --query "<candidate concept terms>" --format json

# Discovery profile for an unprofiled source record.
scripts/pkim profile --record "<source-ref>" --format json

# Deep profile when the source already exists in the corpus and the dependency
# picture (inbound/outbound citations, claim resolution, audit findings) is
# more useful than the discovery output.
scripts/pkim deep-profile --record "<source-ref>" --also-database "PKIM-Pilot" --format json
```

The legacy `pkim search-notes` command is retained for backward compatibility but goes through the same PyObjC bridge; new skills should use `pkim search`.
