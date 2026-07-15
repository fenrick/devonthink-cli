# Local Environment Contract

## Purpose

Keep runtime configuration explicit so agents do not guess where to write or which database to hit.

## Runtime

The runtime is DEVONthink 4.3+'s in-app MCP server. See [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md). No Python or Swift runtime lives in this repo.

To enable the DEVONthink MCP server:

1. In DEVONthink, open **Settings > AI > MCP** and start the server.
2. Copy the server URL / launch command from that panel.
3. Register the MCP server with your AI client:
   - **Claude Code**: `claude mcp add --scope user --transport stdio devonthink -- <launch command>` (or use the URL form if the DT settings offer one).
   - **Codex CLI**: use the equivalent MCP registration command for your client.
4. Confirm the server appears in your client's MCP inventory and the `mcp__devonthink__is_running` tool responds `{running: true}`.

## Baseline Variables

The `.env.example` variables that used to configure a PKIM-owned runtime are largely obsolete. Only these matter now:

| Variable | Purpose |
| --- | --- |
| `PKIM_DEVONTHINK_SCRATCH_DATABASE` | Disposable test database name (`PKIM-Pilot` by convention). Used by human/skill workflows when they need a safe write target. |
| `PKIM_DEVONTHINK_KNOWLEDGE_DATABASE` | Canonical knowledge database name (`PKIM-Knowledge`). |

Use [.env.example](../../.env.example) as the starting point. Keep the real `.env` local and untracked.

## Operational Rules

- All DEVONthink mutations go through the DT MCP server. Do not modify files inside a `.dtBase2` package directly — the MCP tools explicitly warn that direct filesystem manipulation corrupts the database.
- Per-record `Exclude from AI` and per-database `Exclude from Chat & MCP` are the write gates. DT MCP honours both automatically.
- Cross-database references (any KN → EV citation across `PKIM-Knowledge` ↔ `PKIM-Evidence-*`) use `x-devonthink-item://<uuid>` item links, not `[[Name|Display]]` WikiLinks — the renderer only resolves WikiLinks within one database.
- Separate scratch (`PKIM-Pilot`) and production database names at configuration level.
