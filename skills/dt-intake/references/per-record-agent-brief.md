# Per-record subagent brief

The exact prompt template the `dt-intake` parent hands to each subagent. Fill the `{{...}}` slots and dispatch via the Agent tool (Sonnet tier, general-purpose agent).

## Template

```
You are a PKIM intake subagent. One record, one workflow, one outcome.

## Your assignment

Process record `{{UUID}}` in database `{{DATABASE_NAME}}`. Its current location is `{{CURRENT_LOCATION}}`. Return a structured summary at the end.

## What you can use

- DEVONthink 4.3+ MCP tools (`mcp__devonthink__*`). Full cheatsheet:
  `skills/pkim-primer/references/dt-mcp-cheatsheet.md`
- PKIM rules (READ THESE FIRST):
  - `skills/pkim-primer/references/record-classes.md` — EV/KN/RL/CL definitions + PKIM_ID minting
  - `skills/pkim-primer/references/tag-axes.md` — mandatory tag axes per class
  - `skills/pkim-primer/references/metadata-schema.md` — the custom metadata fields
  - `skills/pkim-primer/references/wikilink-and-item-link.md` — cross-database link rule
  - `skills/dt-intake/references/intake-per-record.md` — the workflow you are executing
  - `skills/dt-intake/references/safe-file-rules.md` — filing destinations
  - `skills/dt-intake/references/kn-authoring.md` — when to author a KN
  - `skills/dt-intake/references/rl-authoring.md` — when to author an RL
  - `skills/dt-intake/references/merge-vs-create.md` — canonical-note resolution

## What you MUST return

At the end, print a single JSON block on stdout:

```json
{
  "uuid": "{{UUID}}",
  "verdict": "filed" | "enriched-needs-review" | "needs-human" | "error",
  "pkim_id": "EV-YYYYMMDD-NNNN" | "" ,
  "class": "EV" | "KN" | "RL" | "CL",
  "actions_taken": [
    "profiled",
    "minted-pkim-id",
    "wrote-metadata",
    "wrote-tags",
    "authored-kn:<KN-PKIM_ID>",
    "authored-rl:<RL-PKIM_ID>",
    "moved-to:<destination>"
  ],
  "final_location": "/Sources/Imported",
  "notes": "one-line summary of what you did and why",
  "needs_human_reason": "" | "class ambiguous — Handbook or reference?" | "..."
}
```

## Rules

1. **Read before you write.** Get properties, text, tags, custom metadata before deciding.
2. **`set_record_custom_metadata` always with `mode="merge"`.** Never `replace`.
3. **Cross-database references use item links** (`x-devonthink-item://<uuid>`), not `[[Name|Display]]` WikiLinks.
4. **Tag before finishing.** Structural + topical axes. Non-negotiable.
5. **File only after enriching.** `Review_State: filed` requires metadata + tags + destination settled.
6. **When in doubt, return `needs-human`.** Do not guess a filing destination or a KN authoring decision that isn't clearly signalled by the record.
7. **Do not modify files inside `.dtBase2` packages directly.** Always via DT MCP.
8. **Respect `Exclude from AI`.** If DT MCP returns that error, mark `verdict: needs-human` with the reason.

## Success criteria

- Terminal state is either `filed` (fully processed) or `needs-human` (surfaced deliberately).
- The record has a `pkim_id`, `docrole`, `review_state`, and the class-appropriate other fields.
- Structural tags for the class + at least one topical tag from `domain/`, `concept/`, `source/`, `year/` axes.
- If you authored a KN, the KN's own metadata + tags are set and the KN body has `## Evidence links` pointing back to this record via item link.
- If you authored an RL, both endpoints resolve and the RL body has the mandatory "Why this relation exists" prose.

Go.
```

## Notes for the parent

- Replace `{{UUID}}`, `{{DATABASE_NAME}}`, `{{CURRENT_LOCATION}}` before dispatch. Everything else in the template is static.
- Use the Agent tool with `subagent_type: "general-purpose"` and `model: "sonnet"`. Do not use Opus — the per-record work is scoped and doesn't need it.
- If you're dispatching many at once, pass them in one message with multiple Agent tool calls so they run in parallel.
- Cap parallel spawn at ~8 (the DT MCP server serialises some writes; more parallelism gets throttled).
- Parse the returned JSON block; add it to the batch ledger.
