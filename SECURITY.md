# Security Policy

## Supported versions

PKIM is a single-developer project at an early stage. Only the latest commit
on `main` receives security attention. Older tags are not patched.

## Reporting a vulnerability

If you find a security issue in the PKIM design briefs, skills, or prompts
that could let an unauthorised party read, write, or destroy DEVONthink data
via the workflows this repo describes, please **do not** open a public issue.

Instead, open a [private security advisory](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository, or email the repository owner directly.

I will acknowledge within 7 days and aim to triage within 14.

## Scope

**In scope:**

- Skill workflows in `skills/` — anything that would compose DT MCP tools in a
  way that leaks data (bypasses `Exclude from AI`, sends redacted content to
  the wrong destination, produces destructive write sequences without review).
- Prompts in `prompts/` — anything that would coax an LLM into unsafe DT MCP
  tool use.
- Design briefs — architectural claims that are actually unsafe if followed.

**Out of scope:**

- Issues in DEVONthink itself, including its MCP server. Report those to
  [DEVONtechnologies](https://www.devontechnologies.com/support). This repo has
  no runtime code; write safety is DEVONthink's responsibility once the MCP
  call leaves the AI client.
- Issues in macOS or in AI clients (Claude Code, Codex CLI, etc.).
- "An attacker with shell access on your Mac can do bad things" — assume the
  threat model is "PKIM running on your own machine with your DT data".
