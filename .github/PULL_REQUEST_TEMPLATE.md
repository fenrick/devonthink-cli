## What this changes

<!-- 1-3 sentences. The behaviour or shape, not the diff. -->

## Why

<!-- The motivation. Link the issue if one exists. -->

## Design brief touched

<!-- Which doc(s) in docs/design/ this change anchors to. If the brief
     itself changes, that change must be in this PR. -->

## How it was tested

- [ ] Walked through the change against a scratch DEVONthink database via DT MCP
- [ ] All referenced skills / prompts read cleanly end-to-end
- [ ] Cross-references (WikiLinks, item links) resolve as expected

## Checklist

- [ ] Commits follow conventional-commits style
- [ ] No new PKIM-owned runtime layer between skills and DT MCP (doc 24 anti-pattern)
- [ ] No "safer helper" wrappers around DT MCP tools (doc 24 anti-pattern)
- [ ] Cross-database references use item links, not `[[Name|Display]]` WikiLinks
- [ ] `PKIM_ID` treated as metadata field, not runtime identity
