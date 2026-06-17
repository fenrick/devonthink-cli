# Capability Probe

## Purpose

`pkim probe-capabilities` is the required preflight for every agent session that involves writes to DEVONthink. It validates that the local runtime surface is coherent before any automation acts on live databases.

**Rule: no agent session may issue write operations without a passing probe (or its aggregator `pkim health-check`) in the same session.**

The Swift binary's [`WriteGate`](../../pkim-binary/Sources/pkim/Runtime/WriteGate.swift) holds the in-process 60-second cache of the probe result so each subsequent write inside one invocation doesn't re-probe. See [docs/design/23-swift-pkim-binary.md](../design/23-swift-pkim-binary.md) §"Write-gate enforcement".

## Checks

The probe and `health-check` report the same underlying signals:

| Check | What it verifies | Passes when |
|---|---|---|
| `devonthink-installed` | DEVONthink bundle resolvable via ScriptingBridge | `SBApplication(bundleIdentifier:)` returns non-nil |
| `devonthink-running` | DEVONthink is currently running | `app.isRunning == true` |
| `required-database-open` | The named database is open in DEVONthink | database in `app.databases()` |
| `write-gate-status` | Reports whether `PKIM_ALLOW_PRODUCTION_WRITES=true` | informational, never blocks |
| `metadata-cache-reachable` | `.dt` Spotlight metadata cache exists at `~/Library/Metadata/com.devon-technologies.think/` | directory exists |

`pkim probe-capabilities` returns the raw inputs (open databases, cache root, write-gate state, DT version). `pkim health-check [--database <name>]` aggregates them into a `result: "ok" | "failed"` checklist envelope and is what skills should call as a pre-flight.

## Exit conditions

Both verbs follow the standard envelope contract — see [doc 23 §Exit codes](../design/23-swift-pkim-binary.md):

| Outcome | Exit code | What to do |
|---|---|---|
| All blocking checks pass | `0` | proceed |
| Argument-parser failure | `1` | fix the invocation |
| Invalid input | `2` | resolve before writing |
| DEVONthink unreachable / gate denied | `3` | open DEVONthink, set the env var, re-run |
| I/O error reading the `.dt` cache | `5` | check `~/Library/Metadata/com.devon-technologies.think/` |

## Usage

```sh
# Human-readable JSON envelope to stdout
pkim probe-capabilities

# Aggregated pre-flight checklist (the usual call before any write session)
pkim health-check --database PKIM-Pilot

# Combined preflight inside a skill
pkim health-check --database PKIM-Pilot \
    && pkim probe-capabilities
```

A run manifest lands under `runs/<run-id>/` for each invocation; reads only write `invocation.json` and `stdout.json`.

## Output shape (probe)

```json
{
  "ok": true,
  "verb": "probe-capabilities",
  "run_id": "2026-05-20T...-3f7b1c",
  "data": {
    "pkim_version": "0.1.0-dev",
    "devonthink_bundle": "com.devon-technologies.think",
    "devonthink_installed": true,
    "devonthink_running": true,
    "devonthink_version": "4.1.1",
    "open_databases": ["PKIM-Knowledge", "PKIM-Pilot", ...],
    "write_gate_open": false,
    "cache_root": "/Users/x/Library/Metadata/com.devon-technologies.think",
    "cache_reachable": true,
    "cache_databases": [...]
  },
  "warnings": []
}
```

## Output shape (health-check)

```json
{
  "ok": true,
  "verb": "health-check",
  "run_id": "...",
  "data": {
    "result": "ok",
    "database": "PKIM-Pilot",
    "checks": [
      { "name": "devonthink-installed",    "passed": true, "detail": "..." },
      { "name": "devonthink-running",      "passed": true, "detail": "..." },
      { "name": "required-database-open",  "passed": true, "detail": "..." },
      { "name": "write-gate-status",       "passed": true, "detail": "writes disabled" },
      { "name": "metadata-cache-reachable","passed": true, "detail": "..." }
    ],
    "failed_checks": []
  }
}
```

`write-gate-status` is informational and never counted as a failure — it reports whether `PKIM_ALLOW_PRODUCTION_WRITES=true` without blocking the overall result.
