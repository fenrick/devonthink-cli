# Agent Runtime Surface

## Purpose

Codex CLI and Claude Code need to operate against the same repository contract. This file defines the shared surface so one runtime does not invent a workflow the other cannot follow.

## Supported Runtimes

| Runtime | Root instruction file | Expectation |
| --- | --- | --- |
| Codex CLI | `AGENTS.md` | Follow the repo contract and keep changes aligned with the design register |
| Claude Code | `CLAUDE.md` | Follow the repo contract and keep changes aligned with the design register |

The root instruction files can differ in wording. They should not differ in repository rules.

## Shared Rules

- Start from `docs/design/README.md` for design work.
- Use `docs/ops/` for runtime, repo, and environment conventions.
- Treat `inputs/` as local-only and untracked.
- Write transient outputs to `runs/`, `logs/`, or `tmp/`.
- Use the same local MCP and helper commands regardless of which agent runtime is driving them.
- Do not let either runtime bypass the DEVONthink safety model.

## Runtime-Neutral Tooling Contract

### Single command surface

Both runtimes should call the same local wrappers or commands for:

- MCP startup
- scratch-database validation
- export mirror sync
- metadata writeback
- filing operations

If Codex uses one script and Claude uses another, the system will drift. Avoid that.

### Single environment contract

Both runtimes should respect the same `.env` variables and default paths documented in [local-environment.md](local-environment.md).

### Single log surface

Run manifests and logs should be readable without knowing which agent created them. Include run IDs, timestamps, target database, action type, and post-action state.

## Practical Rule

Build local adapters and scripts as if the caller is anonymous. The runtime should be interchangeable; the contract should not.

