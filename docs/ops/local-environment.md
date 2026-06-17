# Local Environment Contract

## Purpose

Keep runtime configuration explicit so agents do not guess where to write, which database to hit, or whether production writes are allowed.

## Baseline Variables

| Variable | Purpose |
| --- | --- |
| `PKIM_ENV` | Logical environment name such as `development` or `scratch` |
| `PKIM_ALLOW_PRODUCTION_WRITES` | Hard gate for any write path touching non-scratch DEVONthink libraries |
| `PKIM_RUN_ROOT` | Directory for per-run artifacts |
| `PKIM_LOG_ROOT` | Directory for logs |
| `PKIM_TMP_ROOT` | Directory for temporary files |
| `PKIM_EXPORT_ROOT` | Directory for exported markdown mirrors |
| `PKIM_DEVONTHINK_SCRATCH_DATABASE` | Disposable test database name |
| `PKIM_DEVONTHINK_KNOWLEDGE_DATABASE` | Canonical knowledge database name |
| `PKIM_DEVONTHINK_MCP_COMMAND` | Exact pinned launch command or wrapper for the DEVONthink MCP |
| `PKIM_CODEX_COMMAND` | Optional explicit Codex CLI command path or wrapper |
| `PKIM_CLAUDE_COMMAND` | Optional explicit Claude Code command path or wrapper |

Use [.env.example](../../.env.example) as the starting point. Keep the real `.env` local and untracked.

## Building the `pkim` binary

The runtime is the Swift package at `pkim-binary/`. The Python runtime was retired by the CLI-first pivot (see [docs/design/22-cli-first-atomic-primitives.md](../design/22-cli-first-atomic-primitives.md)).

- `cd pkim-binary && swift build` — debug binary at `.build/debug/pkim`.
- `cd pkim-binary && swift build -c release` — release binary at `.build/release/pkim`.
- `cd pkim-binary && swift test` — unit + offline-cache tests. Set `PKIM_BRIDGE_LIVE=1` to opt in to the live-DT suites.
- Put `.build/debug/pkim` (or release) on `PATH` for skill workflows that invoke `pkim` directly.

`pyproject.toml` survives only as a stub so a stray `uv pip install` at the repo root degrades gracefully; the repo has no Python runtime to install.

## Operational Rules

- Default to `PKIM_ALLOW_PRODUCTION_WRITES=false`.
- Production write enablement should happen per run, not as a permanently committed local default.
- Treat the MCP command as versioned infrastructure. Change it intentionally and record the reason.
- If multiple agent runtimes are used, point them at the same local wrappers and environment defaults.
- Separate scratch and production database names at configuration level.
