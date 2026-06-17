---
name: Bug report
about: Something the binary does that the spec says it shouldn't
title: 'bug: '
labels: bug
---

## What happened

<!-- One sentence. The behaviour you observed. -->

## What you expected

<!-- One sentence. What the spec / docs say should happen. -->

## Repro

```bash
# Exact command line:
pkim <verb> --flag value
```

JSON envelope returned (paste verbatim):

```json
{ "ok": ..., "verb": "...", ... }
```

If this was a write: include `runs/<run-id>/mutation.json` (or
`mutation-proposal.json` for dry-runs).

## Environment

- macOS version:
- DEVONthink version:
- `pkim` build (commit hash or version):
- Database affected (PKIM-Knowledge / PKIM-Evidence-* / PKIM-Pilot / other):

## Design brief touched

<!-- Which doc in docs/design/ describes the contract you think was violated.
     If you can't tell, leave blank. -->
