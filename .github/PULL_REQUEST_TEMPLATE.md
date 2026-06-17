## What this changes

<!-- 1-3 sentences. The behaviour or shape, not the diff. -->

## Why

<!-- The motivation. Link the issue if one exists. -->

## Design brief touched

<!-- Which doc(s) in docs/design/ this change anchors to. If the brief
     itself changes, that change must be in this PR. -->

## How it was tested

- [ ] `swift build` clean
- [ ] `swift test` passes (70+ tests)
- [ ] Live SB tests run (`PKIM_BRIDGE_LIVE=1 swift test`) — if write paths changed
- [ ] Tried the verb manually against a scratch database

## Checklist

- [ ] Commits follow conventional-commits style
- [ ] No new file-private helpers that duplicate existing `DTBridge` / `DTRecordAccess` accessors
- [ ] Write paths still go through `runWriteVerb` and `WriteGate.require`
- [ ] No long-lived process or warm-cache state introduced (doc 22 anti-pattern)
- [ ] No compound "doIt"-style verb (doc 23 anti-pattern)
