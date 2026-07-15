# Operations And Safety

## Purpose

Write gates, review states, supersession rules, and the safety posture the whole system enforces. Every skill and every ad-hoc DT MCP composition honours the discipline described here.

## Write gates

The write gate lives in DEVONthink. There is no PKIM-side override.

### Per-record — `Exclude from AI`

Any record with the DEVONthink property `Exclude from AI` set:

- Is filtered out of `search_records`, `find_similar_records`, `classify_record`, `chat_response`, and the link-traversal tools' result lists.
- Refuses input to any DT MCP tool that names it — the tool returns an error rather than silently obeying.

Skills honour this automatically because DT MCP does. There is no bypass. If a workflow needs to touch a `-excluded` record, the human toggles the flag off in DEVONthink first.

### Per-database — `Exclude from Chat & MCP`

The `Exclude from Chat & MCP` flag on the database properties panel blocks the entire database from MCP access. Encrypted and revision-proof databases are excluded by default. Same enforcement shape as per-record — DT MCP refuses.

### Environment posture

There is no `PKIM_ALLOW_PRODUCTION_WRITES` env var. There is no PKIM-side gate. Writes fire the moment a skill calls a DT MCP write tool against a non-excluded record.

That means:

- Skills use dry-run patterns internally — read first, propose, act. Not "propose then flip a global write gate".
- The `PKIM-Pilot` database is the scratch surface. Every skill that needs to test a write path does so there.
- Operator confirmation lives *inside* the workflow, not around it. A skill that's about to author a KN reads back the merge-vs-create judgement before creating.

## Review state model

The review-state vocabulary is closed. Adding a state requires updating this document + [02 Information Model](02-information-model.md) + the audit.

| State | Meaning |
|---|---|
| `inbox` | Arrived. No useful operator meaning yet. |
| `profiled` | Class and baseline metadata set. |
| `needs-human` | Automation deliberately paused. Requires human decision. |
| `approved` | Safe for the next bounded automation step. |
| `blocked` | Stuck. Cannot proceed without intervention. |
| `filed` | In long-term filing destination. |
| `mirrored` | KN-only. Mirror export completed and verified. |
| `archived` | Intentionally inactive. |
| `error` | Automation left inconsistent state. Interrupt. |

### The `needs-human` gate

`needs-human` is the deliberate human-in-the-loop mechanism. Records flip to `needs-human` from any state when:

- The intake skill can't confidently classify a record.
- The audit finds a contradiction requiring a human choice.
- The audit finds a zombie claim on a `published` KN.
- A merge-vs-create judgement is ambiguous.
- Any skill hits a decision it deliberately doesn't make.

**Automation must not progress a `needs-human` record's state.** Automated workflows skip these records — they remain visible in the `Needs Human Review` smart group but are excluded from processing. Clearing the flag is human-only: the reviewer either revises the record and sets the next normal state, or retires it.

### The `error` state

`error` is an interrupt. It can be set from any state when automation fails. It doesn't imply a fixed recovery path — the specific error determines what is done next. A common pattern:

1. A skill's write returns unexpected data.
2. The skill sets `review_state=error`, `automation_last_run_state=error`, and stops for this record.
3. The `Automation Error` smart group surfaces it.
4. The operator investigates. Recovery either re-runs the skill (having fixed the underlying issue) or hand-corrects and resets `review_state`.

### Transitions

Allowed transitions:

```
inbox → profiled → {needs-human | approved | error}
needs-human → {approved | blocked | archived}    (human-driven)
approved → filed                                   (agent or human)
approved → mirrored                                 (agent, KN-only)
blocked → profiled                                  (human)
filed → archived                                    (retention decision)
mirrored → approved                                 (canonical note changed)
any → error                                          (automation failure)
error → profiled                                     (human)
```

Any other transition is invalid. The audit flags illegal transitions when it walks records.

## Supersession

Supersession is how the corpus retires stale material without losing the trail.

### The pattern

1. A newer record renders an older one obsolete. Both continue to exist in the database — supersession does not delete.
2. Author an RL of `Relation_Type: supersedes` from the newer record to the older.
3. Update the older record's status:
   - EV: `evidencestatus=superseded`.
   - KN: `knowledgestatus=archived`, `review_state=archived`.
   - CL: `review_state=archived`.
4. The audit's zombie-claim walk uses `evidencestatus=superseded` as a signal — claims citing only superseded EVs get flagged.

### Propagation

When an EV is superseded, every KN citing it may now carry a stale claim. Two responses:

- **Immediate**: run Workflow 7 (Periodic Claim Audit) against the affected KNs. The zombie check surfaces claims that need attention.
- **Passive**: leave it until the next scheduled audit. Fine if the supersession isn't urgent.

### When to retire vs supersede

- **Retire (`review_state=archived`, no successor)**: the record is genuinely obsolete and nothing replaces it. Rare.
- **Supersede (`supersedes` RL to successor)**: the record's role is now filled by a newer one. Most retirements are supersessions.

The distinction matters for the audit. A retired-with-no-successor record makes any citing KN a zombie candidate; a superseded-with-successor record lets the operator re-point the citation.

## Tagging discipline

Every touched record ends up tagged before the skill returns success. Two mandatory layers — structural (closed vocabulary per class) and topical (open vocabulary, shared corpus-wide). Full axes in [03 Record And Note Specification](03-record-and-note-specification.md).

Untagged records are invisible to DEVONthink's navigation surface. This is not stylistic — it's a functional failure mode.

## Named versions

Knowledge notes use DEVONthink's own revision model as the first layer of history. Named versions are appropriate for:

- Significant synthesis revisions.
- Important relation-note changes.
- Publishing / sharing milestones.
- Automation-generated updates that change substantive content.

Named versions are created **before** the change, not after — that gives a clean rollback point. Skills that mutate substantive content on `KnowledgeStatus ∈ {reviewed, published}` records must create a named version first.

## Rollback and recovery

### The rollback contract

- DEVONthink Trash is the first stop for accidental deletion. Records in Trash are recoverable via the DEVONthink UI or `mcp__devonthink__lookup_records include_trashed: true`.
- Named versions on KN records allow reverting body content.
- Custom metadata writes are inherently reversible — DT MCP's `set_record_custom_metadata mode="merge"` doesn't destroy untouched fields. A wrong value is corrected by writing the right one.
- File-as-truth on indexed KN records: the on-disk `.md` is coherent with the DEVONthink record. If the record is trashed, the file is trashed. If the file is trashed outside DEVONthink, the record shows a missing-file state and DEVONthink's `Update Indexed Items` reconciles.

### Recovery patterns

- **Accidental delete** → recover from DEVONthink Trash. Set `review_state` back to a sensible state.
- **Wrong metadata write** → the `set_record_custom_metadata` verify-read shows the actual state; correct with another `mode="merge"` call.
- **Corrupted body** → revert to the named version created before the change.
- **Skill left inconsistent state** → the skill sets `review_state=error` and surfaces. The operator investigates before any re-run.

## Safety anti-patterns

- Bypassing DEVONthink's `Exclude from AI` / `Exclude from Chat & MCP` gates by any mechanism.
- `set_record_custom_metadata mode="replace"` when merge is intended — replace drops every field not in the payload.
- Automation acting on `needs-human` records.
- Delete without going through Trash first.
- Mutating a `KnowledgeStatus=published` KN's body without creating a named version.
- Auto-advancing state on a record after an `error`.
