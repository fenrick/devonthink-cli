# Security Policy

## Supported versions

PKIM is a single-developer project at an early stage. Only the latest commit
on `main` receives security attention. Older tags are not patched.

## Reporting a vulnerability

If you find a security issue — anything that could let an unauthorised party
read, write, or destroy DEVONthink data via `pkim` — please **do not** open a
public issue.

Instead, open a [private security advisory](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository, or email the repository owner directly.

I will acknowledge within 7 days and aim to triage within 14.

## Scope

In scope:

- The `pkim` Swift binary's write gate, dry-run handling, and run-manifest
  output
- Any path that could let `pkim` mutate DEVONthink without
  `PKIM_ALLOW_PRODUCTION_WRITES=true` being set
- Any path that could exfiltrate `.dt` cache contents or DEVONthink record
  text to a network destination — the binary should never do this

Out of scope:

- Issues in DEVONthink itself (report to DEVONtechnologies)
- Issues in macOS frameworks PKIM depends on (PDFKit, ScriptingBridge,
  Foundation)
- "An attacker with shell access on your Mac can do bad things" — assume the
  threat model is "PKIM running on your own machine with your DT data"
