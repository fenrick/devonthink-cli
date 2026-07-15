# Canonical configuration

The shape PKIM expects to find in DEVONthink. `pkim-orient-and-setup` §Setup installs any of this that's missing; the other skills assume it's present.

## Databases

Five canonical databases. Only PKIM-Knowledge is indexed against an iCloud-synced on-disk root; the other four keep their `.dtBase2` packages on local disk (not cloud-synced).

| Database | Purpose | On-disk root |
|---|---|---|
| `PKIM-Knowledge` | Native knowledge notes (KN, RL, CL) | Indexed against `~/…/PKIM/Knowledge/` (iCloud) |
| `PKIM-Evidence-Personal` | Personal-domain evidence | Local |
| `PKIM-Evidence-Work` | Work-domain evidence | Local |
| `PKIM-Evidence-Server` | Server / infra evidence | Local |
| `PKIM-Pilot` | Scratch / test database | Local |

## Group trees

### `PKIM-Knowledge` (shape: `knowledge`)

- `/Inbox`
- `/Notes`
- `/Notes/Literature`
- `/Notes/Synthesis`
- `/Notes/Relations`
- `/Notes/Topics`
- `/Notes/Projects`
- `/Notes/Claims`
- `/Templates`
- `/Operations`
- `/Archive`

### Evidence-style DBs (shape: `evidence`)

Applies to `PKIM-Evidence-Personal`, `-Work`, `-Server`, and `PKIM-Pilot`.

- `/Inbox`
- `/Sources`
- `/Sources/Imported`
- `/Sources/Indexed`
- `/Captures`
- `/Captures/Web`
- `/Captures/Bookmarks`
- `/Captures/Scans`
- `/Working`
- `/Review`
- `/Archive`

## Smart groups (text predicates only)

DEVONthink's GUI smart-group picker emits **binary** NSPredicates that don't match records whose metadata is written via MCP. Every canonical smart group uses a **text** predicate.

| Smart group | Predicate | Scope (databases) |
|---|---|---|
| `Needs Profile` | `mdreview_state!="approved" && mdreview_state!="filed"` | all five |
| `Needs OCR` | `mdneeds_ocr==true` | four evidence DBs |
| `Needs Knowledge Note` | `mdreview_state=="approved" && mdknowledge_link_state!="linked"` | four evidence DBs |
| `Needs Relation Note` | `mdrelation_gap_state=="open"` | `PKIM-Knowledge` |
| `Needs Filing` | `mdreview_state=="approved"` | all five |
| `Indexed Risk` | `mdindexed_risk_state!=""` | four evidence DBs |
| `Mirror Drift` | `mdmirror_state=="stale"` | `PKIM-Knowledge` |
| `Automation Error` | `mdautomation_last_run_state=="error"` | all five |
| `Needs Human Review` | `mdreview_state=="needs-human"` | all five |
| `Ready for Mirror` | `mdreview_state=="approved" && mdknowledgestatus=="active"` | `PKIM-Knowledge` |

Smart groups live at the database root (`/{name}`), created via `mcp__devonthink__create_record` with `type: "smart-group"`, `search predicate`, and `destination` set to the database's root UUID.

## Note templates

Four canonical templates under `PKIM-Knowledge/Templates/`. Bodies live in `../assets/`:

| Template name | Body |
|---|---|
| `Knowledge Note` | `../assets/knowledge.md` |
| `Relation Note` | `../assets/relation.md` |
| `Topic Note` | `../assets/topic.md` |
| `Project Note` | `../assets/project.md` |

Create each via `mcp__devonthink__create_record` with `type: markdown`, `content: <template body>`, `destination: <templates group UUID>`.

## Custom metadata fields

See [metadata-schema.md](metadata-schema.md). Every field auto-registers on first write, so setup verifies each field is present by reading `mcp__devonthink__list_custom_metadata_fields` and writing missing ones against a scratch record in `PKIM-Pilot`.
