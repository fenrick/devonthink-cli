# Restore Drill

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/24-dt-mcp-adoption.md](../design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces it.

## Purpose

The restore-drill check replays the minimum backup-and-restore evidence required before scaling:

- resolve a live DEVONthink database package
- copy it to a local backup area
- copy that backup to a restore-test package
- open the restore-test package in DEVONthink
- verify one required group path
- record JSON evidence and a normal run manifest

This is an operational check. It does not mutate the live database package.

## Status

The compound `pkim restore-drill` and `pkim scale-readiness` Python verbs retired with the CLI-first pivot (see [../design/22-cli-first-atomic-primitives.md](../design/22-cli-first-atomic-primitives.md)). The drill is now expected to be performed by a skill workflow composing:

- `pkim probe-capabilities` — pre-flight that DT is running and the source database is open.
- A shell step (or `dt-run-restore-drill` skill body) that copies the live package, opens the copy in DT, and runs `pkim verify-database <restore-test-name>` to confirm the canonical group tree is present in the restored copy.
- `pkim health-check --database <restore-test-name>` for the final pass/fail envelope.

A native restore-drill verb is not in scope unless a real friction point re-emerges; see [doc 22 §Anti-patterns](../design/22-cli-first-atomic-primitives.md) before proposing one.

## Inputs

- `--database`
  DEVONthink database name to resolve. Default: `PKIM_DEVONTHINK_SCRATCH_DATABASE` or `PKIM-Pilot`.
- `--source-path`
  Optional direct override of the database package path. Use this only when you do not want to resolve through DEVONthink.
- `--drill-root`
  Root directory for backup, restore-test, and evidence outputs. Default: `tmp/restore-drill`.
- `--restore-name`
  Optional package name for the restore-test copy. Default: `<source-stem>-RestoreTest.dtBase2`.
- `--verify-group`
  Group path that must resolve inside the restored package. Default: `/Inbox`.

## Outputs

- `tmp/restore-drill/backup/<database>.dtBase2`
- `tmp/restore-drill/restore-test/<restore-name>`
- `tmp/restore-drill/evidence/restore-drill-summary.json`
- `runs/<run-id>/restore-drill.json`
- `runs/<run-id>/run.json`

## Failure Modes

- database is not open in DEVONthink
- resolved package path does not exist
- package copy fails
- restored copy cannot be opened in DEVONthink
- verify group path is missing in the restored copy

On failure, the command returns non-zero and still writes `runs/<run-id>/restore-drill.json` plus `run.json`.
