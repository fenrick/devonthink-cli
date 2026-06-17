# Scripts

## Purpose

This directory exists for shell-only helpers that fall outside the Swift
`pkim` binary's atomic-verb surface. After the CLI-first pivot (doc 22)
and the AppleScript ports (doc 23), most operations are verbs on `pkim`
itself.

Scripts do not replace skills. A skill decides the method and safety
boundary; the `pkim` binary executes a bounded operation and emits
evidence.

## Current contents

Just this README. The five PKIM bootstrap AppleScripts that used to
live here have been ported to native `pkim` verbs:

| Retired AppleScript | New verb |
|---|---|
| `setup-database-groups.applescript` | `pkim setup-database <name>` |
| `verify-database-setup.applescript` | `pkim verify-database <name>` |
| `verify-smart-groups.applescript` | `pkim verify-smart-groups [--database <name>]` |
| `fix-smart-group-predicates.applescript` | `pkim fix-smart-groups [--database <name>]` |
| `install-note-templates.applescript` | `pkim install-templates [--database <name>]` |

See `pkim help <verb>` for the contract.

## Adding new scripts

Before adding one:

- If it's a multi-step workflow over `pkim` verbs, write a skill in
  `skills/` instead.
- If it's a single bounded operation that belongs on the runtime hot
  path, add it as a `pkim` verb under `pkim-binary/Sources/pkim/Commands/`.
- Only fall back to a shell script when neither fits — usually a
  cross-tool glue script (osquery / Spotlight / shell pipeline) that
  has no business inside the binary.

Do not add personal scratch scripts here and pretend they are
infrastructure.
