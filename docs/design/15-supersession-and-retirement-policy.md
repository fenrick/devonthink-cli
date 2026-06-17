# Supersession and Retirement Policy

## Purpose

This document defines when to supersede versus update a knowledge note, when to retire versus strengthen a relation note, how supersession propagates through the graph, and what state a retired record must carry.

It answers one question:

When does a change to meaning require a new record, and when does it require editing the existing one?

It does not define the skills that execute these actions. Those are in `docs/design/11-agent-skills-and-runbooks.md`.

## Boundary

- **Update** — the existing record's identity and central claim remain valid; only the expression, supporting evidence, or lifecycle state changes.
- **Supersede** — the existing record's central claim has changed enough that treating it as the same note would mislead future readers and break downstream relation edges.
- **Retire** — the existing record is no longer valid and no successor is created (knowledge notes: rarely; relation notes: when the edge itself is wrong rather than just stale).

A record that is superseded is not deleted. It is archived in place with its `Review_State` advanced to `archived` and a pointer to its successor. A record that is retired carries an explicit `RelationStatus=retired` marker.

## Knowledge Note Policy

### When to update

Update the existing knowledge note when:

- New evidence strengthens or qualifies the existing central claim without replacing it.
- The summary requires rewording for clarity without changing the claim.
- A key point needs correction for accuracy (minor factual error, imprecision).
- Additional evidence links should be added.
- The note's `Review_State` should advance (e.g. `profiled` → `approved`).

### When to supersede

Supersede (create a new note and archive the old one) when:

- The central claim has changed. The old and new versions would give a reader different answers to the same question.
- The scope of the note has expanded to cover a meaningfully different concept, such that the old note's title is now misleading.
- A merge decision from `dt-resolve-canonical-note` identifies that two notes should be unified — the merged note supersedes both inputs.
- The note is in `Review_State=error` and the intended state requires a completely new record identity (Type 5 failure in `dt-recover-failed-write`).

The threshold: if you would need to change the title to keep it honest, supersede.

### Supersession procedure for knowledge notes

1. Create the successor note via `dt-build-knowledge-note` with the new content.
2. Set `Review_State=archived` on the predecessor via `dt-apply-approved-metadata`.
3. Set `Automation_Last_Run_State=superseded-by:<successor-pkim-id>` on the predecessor.
4. Inspect all relation notes where the predecessor is `Source_Item` or `Target_Item` via `dt-reconcile-relation-edge`. For each:
   - If the relation still holds between the successor and the other endpoint, create a new relation note with the successor as endpoint and retire the old one.
   - If the relation no longer holds, retire only.

Step 4 is required. A superseded note with active relation edges pointing to it produces zombie edges that block graph reconciliation.

### Mirror state after supersession

The predecessor's mirror file (if it exists) must be updated. On the next `dt-sync-export-mirror` run:
- The predecessor note should export as archived.
- The successor note should export as a new file.

Do not delete the predecessor mirror file manually — let the mirror sync handle it.

## Relation Note Policy

### When to strengthen

Strengthen (update the existing relation note) when:

- The rationale is thin or absent but the relation type is correct.
- `RelationStatus` should advance (`proposed` → `reviewed` → `accepted`).
- New evidence makes the relation more specific but the fundamental claim (source supports/contradicts/etc. target) is unchanged.

Use `scripts/pkim update-relation-note` for this path.

### When to supersede a relation note

Supersede (create a new relation note and retire the old) when:

- The relation type is wrong (e.g. the actual relation is `contradicts` but the existing note says `supports`).
- The interpretation section reveals that the relation holds between the successor of a superseded node and the target — the old source endpoint is no longer the right one.
- A duplicate triplet audit has identified two relation notes covering the same edge — the weaker one is retired, the stronger one remains.

### When to retire a relation note

Retire without creating a successor when:

- One or both endpoints have been archived and the relation between them no longer applies in any direction.
- The relation was speculative and has been definitively ruled out after review.

Retirement sets `RelationStatus=retired`. Do not delete relation notes. A retired note provides audit history and prevents the same edge from being recreated without evidence.

### Supersession procedure for relation notes

1. Create the new relation note via `dt-build-relation-note` with the corrected type or rationale.
2. Set `RelationStatus=retired` on the old note via `scripts/pkim update-relation-note --relation-status retired`.
3. Set `Automation_Last_Run_State=superseded-by:<successor-pkim-id>` on the old note via `dt-apply-approved-metadata`.

The old note remains in place with `RelationStatus=retired`. It will appear in audit scans but not in active graph traversal (skills filter by `RelationStatus != retired`).

## Graph propagation rules

When a knowledge note is superseded, the following propagation is required before the session ends:

| What exists | Required action |
|---|---|
| Relation notes with predecessor as `Source_Item` | Re-evaluate each; recreate with successor or retire |
| Relation notes with predecessor as `Target_Item` | Re-evaluate each; recreate with successor or retire |
| Mirror file for predecessor | Let `dt-sync-export-mirror` handle on next run |
| `Knowledge_Link_State` on evidence records pointing to predecessor | Update to successor PKIM_ID via `dt-apply-approved-metadata` |
| Knowledge notes that cite the superseded evidence record | Flip each to `KnowledgeStatus=needs-review` via `pkim.mirror.propagation.propagate_supersession` (WP3.1) |

Partial propagation — superseding the note without reconciling the edges — is worse than not superseding at all. It produces zombie edges. If there is not enough time to complete propagation in one session, do not supersede. Update instead, and defer supersession until the full propagation can be completed.

### Evidence supersession → KN review (WP3.1)

When an **evidence record** is retired or superseded, every knowledge note that cites it must be flipped to `KnowledgeStatus=needs-review` so the operator can re-ground each claim before the note is considered authoritative again. Without this propagation, retired evidence quietly invalidates synthesis that still looks current.

The propagation is implemented by [`pkim.mirror.propagation.propagate_supersession`](../../src/pkim/mirror/propagation.py): given a set of retired EV PKIM_IDs and a live mirror graph, it identifies dependent KNs (via body WikiLinks in `Evidence links` / `Evidence` / `Claims` sections **and** via parsed claim-block `evidence_links` rows) and writes the new status back through `DTWriter.set_knowledge_status`.

Operational rules:

- KNs already at `KnowledgeStatus=needs-review` are not rewritten (idempotent re-runs are safe).
- KNs at `KnowledgeStatus=archived` are excluded — they're already retired.
- The flip is approval-gated at the command layer; the propagation function assumes `PKIM_ALLOW_PRODUCTION_WRITES=true` and a passing capability probe.
- Failed writes are reported but do not abort the pass; partial propagation is acceptable when surfaced in the run manifest.

Clearing `needs-review` after re-grounding requires explicit operator action — the system does not auto-promote `needs-review` back to its previous status. See [08 Record And Note Specification](08-record-and-note-specification.md) §Review State Model.

## State a retired record must carry

A knowledge note with `Review_State=archived`:
- `Review_State`: `archived`
- `Automation_Last_Run_State`: `superseded-by:<successor-pkim-id>` or `retired:<reason>`
- Body: unchanged from the last version before archival

A relation note with `RelationStatus=retired`:
- `RelationStatus`: `retired`
- `Automation_Last_Run_State`: `superseded-by:<successor-pkim-id>` or `retired:<reason>`

Without these fields, retired records become invisible debris — they fail audit checks and cannot be recovered or traced.

## Anti-patterns

- Superseding a note and leaving its relation edges pointing to the archived version (zombie edges).
- Retiring a relation note by deleting it — deletion removes audit history.
- Updating a note whose central claim has changed rather than superseding it (produces misleading knowledge state).
- Superseding without propagating to evidence `Knowledge_Link_State` fields (leaves evidence records pointing at archived notes).
- Creating a new relation note as a supersession without retiring the old one (produces duplicate triplets).
