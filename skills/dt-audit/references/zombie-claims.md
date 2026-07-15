# Zombie claims

A claim is a zombie when every EV it cites has been retired or superseded. The claim still looks confidently backed if you just read the KN body, but every citation is stale — the claim is unsupported.

Detecting zombies is the audit's most important job. New evidence loops make claims stronger over time; retirement loops silently weaken them.

## Detection

Two shapes of claim:

### A — inline claims in a KN's `## Claims` block

For each KN in `PKIM-Knowledge`:

1. Read the body: `mcp__devonthink__get_record_text uuid: <KN-UUID>`.
2. Parse the `## Claims` block. Each claim has an `evidence` array of item-link references (see doc 18 for the YAML schema).
3. For each `evidence` link, extract the UUID and check the target's `evidencestatus` via `get_record_properties` + `get_record_custom_metadata`.
4. Classify per claim:
   - `all-active` — every cited EV has `evidencestatus: approved` (or unset with a non-retired state)
   - `partial` — at least one cited EV is retired/superseded, at least one active
   - `zombie` — every cited EV is retired/superseded, OR no evidence cited at all

Only `fact` and `inference` claims are audited. `assumption` and `open-question` may have zero evidence by design.

### B — CL records

For each CL in `PKIM-Knowledge`:

1. Read the body: `mcp__devonthink__get_record_text uuid: <CL-UUID>`.
2. Find the `## Evidence` section. Each line is a bullet with an item link.
3. Same classification as above.

## Finding shape

```json
{
  "class": "zombie-claim",
  "uuid": "<KN or CL UUID>",
  "pkim_id": "KN-20260503-0002",
  "claim_text": "Local-first systems reduce sync overhead...",
  "claim_type": "fact" | "inference",
  "claim_confidence": "high",
  "retired_evidence_uuids": ["EV-20260101-0007", "EV-20260215-0002"],
  "verdict": "zombie" | "partial"
}
```

## Triage guidance

- **`zombie` on a `KnowledgeStatus: published` KN** — high priority. Route to human triage. The KN either needs new evidence (search for successors of the retired EVs) or the claim retires.
- **`partial` on a `high` confidence claim** — medium priority. Confidence should probably drop to `medium` until new evidence lands.
- **Zombies on `KnowledgeStatus: active` (unreviewed) KNs** — lower priority; the KN itself hasn't been sign-off'd, so the zombie doesn't yet mislead any downstream reader.

## Auto-fix

None. Every zombie needs human judgement — either find new evidence, restate the claim, or retire it. The audit surfaces; the operator decides.

## Chasing successors

When triaging, look for supersession chains: an EV marked `superseded` often has an RL of `Relation_Type: supersedes` pointing to its successor.

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: 'kind:markdown mddocrole:relation mdrelation_type:supersedes mdsource_item:"x-devonthink-item://<retired-EV-uuid>"'
```

If a successor is found, the fix is to update the claim's evidence citations from the retired EV to the successor. This is a human decision (the successor may not actually support the same claim).

## Anti-patterns

- **Marking a claim zombie because *some* evidence is retired.** That's `partial`, not `zombie`. The audit distinguishes them.
- **Auto-retiring a zombie claim.** The claim's author had a reason; the retirement of its evidence doesn't automatically retire the claim.
- **Ignoring `assumption` claims.** They don't need evidence, so they can't zombie — correct. But if their reasoning depended on now-retired context, they still need review — that's a discipline check, not a zombie check.
