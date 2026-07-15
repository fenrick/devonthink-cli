# Contributing to PKIM

Thanks for the interest. PKIM is a personal knowledge operating system built
around DEVONthink; the repo is primarily my own working surface, so the bar
for accepting external changes is "the contribution genuinely fits the design
intent and the maintainer can support it long-term." That's a real bar — most
proposals will be better as a fork.

## Before opening anything

1. Read [`docs/design/README.md`](docs/design/README.md). The design briefs are
   the contract. If a proposed change disagrees with one of them, the design
   brief needs to change first (in the same branch).
2. Read [`docs/design/24-dt-mcp-adoption.md`](docs/design/24-dt-mcp-adoption.md)
   for the runtime — the DEVONthink 4.3+ MCP server is what skills compose.
   There is no PKIM-owned runtime layer.
3. Read [`CLAUDE.md`](CLAUDE.md) for the working rules.
4. Check the open issues — your idea may already be tracked or rejected.

## Reporting bugs

Use the bug-report template under `.github/ISSUE_TEMPLATE/`. Include:

- macOS version, DEVONthink version, AI client (Claude Code, Codex, etc.).
- The exact DT MCP tool call and the JSON response you saw.
- Which skill (if any) was orchestrating the call.

## Proposing features

Use the feature-request template. Be specific about:

- Which design brief the proposal sits under (and whether it would change it).
- Whether the work belongs in a skill workflow, a prompt, or the design register.
  There is no PKIM-owned runtime; adding "a new PKIM tool" almost always means
  either composing existing DT MCP tools in a skill, or asking DEVONthink to
  extend its MCP surface (out of scope for this repo).

## Code changes

- Open an issue first for anything non-trivial. Drive-by PRs against a
  spec-anchored repo waste both our time.
- Keep commits small and reviewable; conventional-commits style is preferred
  (`docs(design): …`, `feat(skill): …`, `chore: …`).
- Skills follow the shape documented in `skills/README.md`: `SKILL.md` frontmatter,
  purpose, inputs, outputs, preconditions, postconditions, failure modes,
  related skills.

## What probably won't be accepted

- Anything that reintroduces a PKIM-owned runtime layer between skills and DT MCP.
- Skills that wrap DT MCP tools in "safer" helpers that add opinion — DT MCP
  is the trusted layer.
- Compound "doIt"-style skills that hide multiple orthogonal decisions in one
  workflow. Skills should be legible.
- Anything that treats `PKIM_ID` as a runtime identity rather than as a
  metadata field (DT UUID is identity — see doc 24).

## License

By contributing, you agree your contribution is licensed under the same MIT
License as the rest of the project.
