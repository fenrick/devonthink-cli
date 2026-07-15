# Tagging discipline (mandatory across all PKIM record-touching skills)

Every PKIM record (EV, KN, CL, RL) **must** end up with a complete slash-namespaced tag set applied via `mcp__devonthink__set_record_tags` before the skill returns success. The rule is non-negotiable. This document is the canonical reference linked from every skill that creates or transitions a record.

## Why

- DEVONthink's navigation, smart groups, Tags hierarchy view, classification, and search are tag-driven. Untagged records are invisible to DT's tag-based infrastructure.
- The user has flagged untagged records as a recurring issue multiple times across sessions. Memory: `feedback_note_tags_aliases`.
- Doc 21 §Cross-database links + §Indexed-mode formalises the slash-namespaced convention because DT renders tag values with `/` as a real tree under the database's Tags group, not as flat chips. Hyphenated-flat tags discard the hierarchy and are **wrong**.

## What

Every record gets two layers of tags:

| Layer | Purpose | Example values |
| --- | --- | --- |
| **Structural** | Identifies the record's class, type, lifecycle state | `pkim/claim`, `claim/type/fact`, `claim/confidence/high`, `claim/state/approved` |
| **Topical** | Identifies the *subject* the record is about | `domain/digital-transformation`, `concept/composable-enterprise`, `entity/mulesoft`, `source/vendor-research`, `year/2021` |

Structural axes per class:

| Class | Required structural tags |
| --- | --- |
| EV (evidence) | `pkim/evidence`, `evidence/status/<state>` (approved/proposed/retired/superseded), `evidence/capture/<type>` (import/clip/scan/web/note) |
| KN (knowledge) | `pkim/knowledge`, `knowledge/type/<note-type>` (literature/synthesis/topic/project), `knowledge/status/<state>` (active/reviewed/published/archived), `knowledge/confidence/<level>` (low/medium/high) |
| CL (claim) | `pkim/claim`, `claim/type/<type>` (fact/inference/assumption/open-question), `claim/confidence/<level>` (low/medium/high), `claim/state/<state>` (approved/needs-human/etc) |
| RL (relation) | `pkim/relation`, `relation/type/<rel>` (supports/contradicts/extends/etc), `relation/status/<state>` (proposed/reviewed), `relation/confidence/<level>` (low/medium/high) |

Topical axes (open vocabulary, shared across the corpus, all record classes):

- `domain/<area>` — broad subject area (e.g. `domain/digital-transformation`, `domain/enterprise-architecture`).
- `concept/<thing>` — named concept the record is *about*. At least one is required for any record carrying substantive content.
- `entity/<organisation-or-product>` — when the record names a specific organisation, product, person, or place.
- `source/<class>` — for EVs: the source class (`vendor-research`, `industry-analyst`, `peer-reviewed`, `blog-post`, `internal-doc`). Inherited by citing KNs and CLs.
- `year/<YYYY>` or `period/<label>` — when the record is temporally bounded.
- `method/<approach>` — when methodological provenance is worth surfacing (`case-study`, `survey`, `benchmark`).

## How

- Use `mcp__devonthink__set_record_tags(uuid, tags: [...])`. Do not stuff tags into custom metadata.
- Aliases (`set_aliases`) get the semicolon-joined `<name>; <PKIM_ID>` so DT alias resolution finds the record by either form.
- For indexed records, also update the file's `Tags:` MMD header so frontmatter matches DT-side state.
- If meaningful topical tags cannot be determined from the available evidence, that's a profiling gap. **Pause and surface to the operator. Do not skip tagging.**

## Inheritance rules

- KN inherits its CLs' union of `concept/*` tags so a search on any concept hits both the KN and the relevant CL siblings.
- CL inherits `domain/*`, `entity/*`, `source/*`, `year/*` from its parent KN; `concept/*` is per-claim.
- RL inherits topical tags from both endpoints.

## Audit support

`pkim audit-discipline` should produce a `missing-tags` finding when any record lacks its structural minimum or has no topical tags. See [19 Synthesis Uplift Plan](../../docs/design/19-synthesis-uplift-plan.md) backlog.

## Linked skills (must include a "Tagging" step pointing here)

- `dt-apply-approved-metadata` — at EV/KN/CL/RL mint time
- `dt-profile-record` — when transitioning EV from inbox to profiled
- `dt-safe-file` — when filing an EV to Sources/
- `dt-build-knowledge-note` — at KN creation
- `dt-build-relation-note` — at RL creation
- `dt-build-claim-ledger` — for each CL minted from the ledger
- `dt-sweep-inbox` — when dispatching profiling work
- `dt-resolve-canonical-note` — when re-tagging on canonical merge
