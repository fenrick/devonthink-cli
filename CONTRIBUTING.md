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
2. Read [`CLAUDE.md`](CLAUDE.md) for the working rules.
3. Check the open issues — your idea may already be tracked or rejected.

## Reporting bugs

Use the bug-report template under `.github/ISSUE_TEMPLATE/`. Include:

- macOS version, DEVONthink version
- Exact `pkim <verb> …` invocation and the full JSON envelope returned
- The `runs/<run-id>/` directory if the bug involved a write

## Proposing features

Use the feature-request template. Be specific about:

- Which design brief the proposal sits under (and whether it would change it)
- Whether the work belongs in the Swift binary or as a skill workflow — the
  layer rules in [`docs/design/22-cli-first-atomic-primitives.md`](docs/design/22-cli-first-atomic-primitives.md)
  are binding

## Code changes

- Open an issue first for anything non-trivial. Drive-by PRs against a
  spec-anchored repo waste both our time.
- Keep commits small and reviewable; conventional-commits style is preferred
  (`feat(pkim-binary): …`, `docs(design): …`, `chore(pivot): …`).
- The Swift binary follows [`~/.claude/rules/swift/`](https://github.com/anthropics/claude-code)
  style if you're using Claude Code; otherwise the usual: `let` over `var`,
  small protocols, structured concurrency, typed throws.
- Tests live in `pkim-binary/Tests/pkimTests/` under Swift Testing
  (`import Testing`). Live-DT suites are gated by `PKIM_BRIDGE_LIVE=1` and
  must restore pristine state.

## What probably won't be accepted

- Compound CLI verbs ("doIt"-style mega-commands) — see doc 22 §Anti-patterns.
- Re-introducing a long-lived process to amortise startup.
- Anything that mutates DEVONthink without going through the write gate.
- Changes that bypass the file-as-truth contract for indexed records.

## License

By contributing, you agree your contribution is licensed under the same MIT
License as the rest of the project.
