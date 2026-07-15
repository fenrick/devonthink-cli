# Corpus-level contradictions

Two records in the corpus assert mutually exclusive things. Within-KN contradictions are caught at authoring time (via `contradicted_by` on the claim block); this audit is for the cross-KN cases where two authors reach opposing conclusions without knowing about each other.

## Detection — shared-EV opposing edges

The clearest signal: two KNs cite the same EV, one via an RL of `Relation_Type: supports`, the other via `contradicts`. That's a corpus contradiction.

Walk RLs:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:relation"
  limit: 1000
```

Build an in-memory index: `{target_ev_uuid → [(rl_uuid, source_kn_uuid, relation_type)]}`.

For each `target_ev_uuid` with more than one incoming RL, look for opposing types:

| Type A | Opposing types |
|---|---|
| `supports` | `contradicts` |
| `extends` | (none — extends doesn't strictly oppose anything) |
| `contradicts` | `supports` |
| `supersedes` | (special — see below) |
| `precedes` | (none) |
| `exemplifies` | (none) |
| `summarizes` | (none) |

## Detection — supersession chains

Sometimes contradictions manifest as: KN_A cites EV_old (supports), KN_B cites EV_new which supersedes EV_old (contradicts). The audit catches this by walking supersession chains:

1. For each RL with `Relation_Type: supersedes`, note the pair (source, target).
2. For each KN citing the *target* of a supersession, check the KN's own claims against the successor. If the KN would draw the opposite conclusion from the successor, that's a latent contradiction.

Full walk is expensive; do it only when the zombie-claim audit surfaces retirements — the two problems overlap.

## Detection — same-subject opposing CLs

CL records make same-subject contradictions cheap to find:

```
mcp__devonthink__search_records
  database_uuid: <PKIM-Knowledge>
  query: "kind:markdown mddocrole:claim mdprimarytopic:<topic>"
```

For each pair of CLs on the same primary topic:

- If both are `fact` and their assertions contradict (semantic check — LLM judgement), flag.
- If one is `high` confidence and the other is `low`, the corpus is unresolved on that topic — surface as a lower-severity finding.

## Finding shape

```json
{
  "class": "corpus-contradiction",
  "records": ["<KN_A-UUID>", "<KN_B-UUID>"],
  "pkim_ids": ["KN-...", "KN-..."],
  "shape": "shared-evidence-opposing-rl" | "supersession-chain" | "opposing-cls",
  "shared_evidence": "<EV-UUID>",         // for shared-EV case
  "relation_types": ["supports", "contradicts"],
  "status": "open"
}
```

## Persistence across runs

The contradiction register is stateful. Between audit runs, contradictions can be:

- `open` — newly detected, or persisting from last run.
- `acknowledged` — the operator has seen it and chosen not to resolve yet (both KNs marked `contradicted_by` each other in their `## Claims` blocks).
- `resolved` — one KN was retired, or the claims were reconciled.

Carry forward `acknowledged` / `resolved` status from the previous audit run's register. The register lives in the audit output — not a runtime state (per doc 24 we don't do run manifests).

## Triage guidance

- **Open contradictions** — the operator triages by reading both KNs, deciding which one is right, and either retiring the loser or reconciling the claims.
- **Persistently open contradictions across many runs** — indicates the corpus is genuinely uncertain about that topic. That's fine as long as it's `acknowledged`.
- **Fresh contradictions after a retirement wave** — expected. The retirement changed the evidence landscape.

## Auto-fix

None. Contradictions are the point of the audit — they're for human resolution.

## Anti-patterns

- **Flagging every RL with opposing types as a contradiction.** Two KNs can both correctly cite an EV with opposing edges if they interpret different aspects of it — that's a nuanced disagreement, not necessarily a contradiction. Surface it, but with a soft severity.
- **Trying to reconcile automatically.** The whole point is that humans arbitrate.
- **Ignoring supersession chains.** A KN's evidence being superseded is silent — the KN body still reads confidently. The audit is the only trigger to check.
