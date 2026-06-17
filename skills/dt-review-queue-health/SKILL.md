---
name: dt-review-queue-health
description: Inspect PKIM queue metrics and determine whether the queue surface reflects healthy operational flow, backlog, or hidden failure. Make sure to use this skill whenever the user asks what is piling up, whether queues are healthy, why automation feels stuck, or what the highest-priority operational cleanup is.
compatibility: Works in any runtime that can call the shared `scripts/pkim queue-metrics` command and inspect the returned queue counts.
---

# dt-review-queue-health

This skill exists because queue counts are not self-explanatory. A queue is either routine work, a genuine blocker, or evidence that the routing model is lying.

## What this skill is for

Use it to answer:

- which queues currently matter
- whether there is operational blockage
- whether queue counts reflect healthy flow or failure accumulation
- what should be handled first

The result should be a prioritised operational read, not a raw queue dump.

## Why this matters

PKIM relies on queue state for action routing. If queue interpretation is sloppy:

- real failures get buried
- stale junk looks urgent
- the operator works the wrong queue first

Queue review is how you turn counts into action.

## Workflow

1. Run:
   ```bash
   scripts/pkim queue-metrics --format json
   ```
2. Read totals and per-database group counts.
3. Separate:
   - failure queues
   - hygiene queues
   - normal working queues
4. Prioritize:
   - `Automation Error`
   - `Mirror Drift`
   - `Indexed Risk`
   - `Needs Human Review`
   - then routine workload queues
5. If counts look suspicious, inspect whether test fixtures or non-operational records are polluting the queue.

## How to know you are doing it right

You are doing this skill correctly when:

- failure queues are treated first
- queue counts are interpreted in context
- obvious junk or seed pollution is called out

You are doing it badly when:

- you present every queue as equally important
- you ignore per-database distribution
- you treat stale fixture counts as real operational work

## What not to do

- Do not stop at totals if one database is obviously the real source.
- Do not recommend bulk cleanup without identifying the queue source first.
- Do not call the system healthy while failure queues are non-zero.

## Output

Produce a short queue-health review with:

- the queues that matter now
- the highest-priority operational issue
- whether the queue surface looks trustworthy
- the next action

## Preferred tool path

```bash
scripts/pkim queue-metrics --format json
```
