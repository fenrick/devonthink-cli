---
name: dt-health-check
description: Determine whether the local PKIM runtime is actually fit to use before real work starts. Make sure to use this skill whenever the user asks to check setup, confirm the environment, troubleshoot why PKIM is failing, verify DEVONthink visibility, or before the first meaningful read or write action in a runtime, even if they only say "is this configured?" or "can we run it?".
compatibility: Works in any runtime that can inspect local environment state and DEVONthink reachability. The local `pkim health-check` and `pkim probe-capabilities` commands are preferred tool paths when available.
---

> **Runtime note.** Any `pkim <verb>`, `DTWriter.*`, or `DTReader.*` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../../docs/design/24-dt-mcp-adoption.md](../../docs/design/24-dt-mcp-adoption.md) §"Coexistence / replacement table" for the DT MCP tool that replaces each retired symbol. The skill's judgement, tag rules, and stop conditions remain valid.

# dt-health-check

This skill exists because PKIM failures are often environment failures disguised as workflow failures. If you skip the runtime check, you waste time debugging the wrong thing and you risk unsafe writes in a half-configured environment.

Your job is to determine whether the runtime is genuinely usable, what kind of work it is safe for, and what is blocking if it is not ready.

## What this skill is for

Use it to answer:

- can this runtime safely do read-only PKIM work
- can this runtime safely do approved write work
- what exactly is missing or broken

The output should let a later step proceed with confidence or stop for a specific reason.

## Why this matters

PKIM depends on a few non-negotiable surfaces:

- DEVONthink must be reachable
- the configured databases must actually be visible
- the local tool surface must resolve
- write gates must be explicit

“The repo is present” is not enough. “The command exists” is not enough. Health means the runtime can see the real system it is supposed to operate.

## Workflow

Follow this sequence.

1. Read the configured PKIM environment.
2. Identify:
   - runtime name
   - active PKIM environment
   - configured scratch database
   - configured knowledge database
   - configured export root
   - configured tool commands
   - production write gate state
3. Check whether DEVONthink is reachable from the current runtime.
4. Check whether the configured scratch database is visible.
5. Check whether the configured knowledge database is visible.
6. Check whether at least one evidence database is visible if the work depends on evidence handling.
7. Check whether the expected local tool surface is resolvable.
8. Decide what level of readiness exists:
   - read-only ready
   - write-ready
   - not ready
9. Report the result with explicit failed checks and warnings.

## How to think about the result

Treat these as hard failures:

- DEVONthink not reachable
- configured scratch database not visible when scratch operations are expected
- configured knowledge database not visible when note work is expected

Treat these as context-dependent:

- write gate disabled
  This is normal for read-only work and only a blocker for write tasks.
- optional helper binary missing
  This is a warning unless the current workflow depends on it.

Prefer partial readiness to fake certainty. If only read-only work is safe, say that plainly.

## How to know you are doing it right

You are doing this skill correctly when:

- a later agent can tell immediately whether to proceed
- missing prerequisites are named specifically
- the result distinguishes read-only readiness from write readiness
- the output is stable enough for both humans and automation

You are doing it badly when:

- you say “ok” because config exists
- you bury critical failures in warnings
- you present a generic checklist instead of the actual runtime state

## What not to do

- Do not mutate DEVONthink.
- Do not treat disabled writes as an error unless the requested task needs writes.
- Do not assume that a configured command means a working runtime.
- Do not hand-wave missing database visibility.

## Output

Produce a structured runtime-health result with:

- overall result
- pass/fail state
- per-check details
- failed checks
- warnings
- key runtime configuration needed for follow-on decisions

Canonical shape:

```json
{
  "run_id": "RUN-2026-04-17T15-10-00Z",
  "runtime": "claude-code",
  "pkim_env": "development",
  "result": "read-only-ready",
  "checks": {
    "devonthink_reachable": true,
    "scratch_database_visible": true,
    "knowledge_database_visible": true,
    "local_commands_resolvable": true,
    "mcp_available": false,
    "production_writes_enabled": false
  },
  "failed_checks": [],
  "warnings": ["mcp_available: false — MCP transport unavailable; CLI path only"],
  "runtime_config": {
    "scratch_database": "PKIM-Pilot",
    "knowledge_database": "PKIM-Knowledge",
    "export_root": "/path/to/your/checkout/mirror",
    "pkim_allow_production_writes": false
  }
}
```

Valid `result` values: `read-only-ready`, `write-ready`, `not-ready`.

Use `write-ready` only when `production_writes_enabled` is true and all databases and commands are confirmed. Use `not-ready` when any hard-failure check fails. Use `read-only-ready` for everything between those two states.

## Preferred tool path

When the local CLI is available, use:

```bash
pkim health-check --format json
pkim probe-capabilities --format json
```

Those commands are useful because they provide deterministic local evidence and run artifacts. They are not the skill. The skill is the method above.
