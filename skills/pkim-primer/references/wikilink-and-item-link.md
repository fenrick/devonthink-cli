# WikiLinks vs item links

Two ways to reference another record in a note body. They are not interchangeable.

## WikiLink — `[[Name|Display]]`

- **Resolves inside one database only.** DEVONthink's markdown renderer looks up the target by name within the current database. It does not search other databases.
- **Use for KN ↔ KN, KN ↔ CL, CL ↔ CL, KN ↔ RL** — anything inside `PKIM-Knowledge`.
- **Do not use for EV references.** EVs live in `PKIM-Evidence-*` (different database). A `[[EV-...|Name]]` in a KN body renders as text, not a clickable link.
- **Rendering:** DT 4.3's new markdown renderer supports WikiLinks. Callouts, citations, and CriticMarkup are also new.

## Item link — `x-devonthink-item://<uuid>`

- **Resolves across databases.** DT's URL scheme takes a UUID and jumps to the record wherever it lives.
- **Use for KN → EV** (or any cross-database reference).
- **Also fine for within-database.** But WikiLinks are more readable in the source, so prefer them within `PKIM-Knowledge`.

## Composition patterns

### KN citing EVs (cross-database)

```markdown
## Evidence links

- [Local-first software, Kleppmann et al](x-devonthink-item://1B79...)
- [Riffle case study](x-devonthink-item://2C8A...)
```

### KN linking related KNs (within `PKIM-Knowledge`)

```markdown
## Related notes

- [[Composable Enterprise Boundary]]
- [[API-Led Connectivity Critique]]
```

### CL citing its parent KN (within `PKIM-Knowledge`)

```markdown
## Parent

- [[KN-20260429-0002 — Purpose Design]]
```

### CL citing EV (cross-database)

```markdown
## Evidence

- [MuleSoft trends report](x-devonthink-item://3D9B...)
```

### RL body — the endpoints are already in metadata

The `Source_Item` and `Target_Item` custom metadata fields carry the authoritative item links. The RL body's prose can reference the endpoints by display name; the linking is metadata-side, not body-side.

## How to fetch the item link for a record

The DT MCP result for `create_record`, `get_record_properties`, and most tools carries `referenceURL` — that's the item link. Use it verbatim.

## Why the constraint exists

DT's cross-database resolution is expensive; the WikiLink lookup is scoped to the current database for performance. Item links are UUID-native, so they resolve in constant time regardless of which database the target is in.

## Auditing

The `dt-audit` workflow's "dangling WikiLinks" check catches `[[...]]` in KN bodies that don't resolve — usually the fix is to convert them to item links (if the target was cross-database) or to correct the name (if the target moved). The check does not fire on item links because DT resolves those unconditionally.
