# Implementation Work Packages

## Purpose

This document turns the design into buildable work packages.

The system is not being delivered as isolated “phases,” but work still needs decomposition, dependency logic, and an execution order that reflects leverage and risk.

## Delivery Posture

Build the whole system as one coherent architecture, but sequence work by:

- dependency
- leverage
- safety
- speed to usable output

## Work Package Set

### WP-01: DEVONthink baseline setup

Scope:

- create baseline databases
- create top-level groups
- define metadata fields
- establish note templates

Outputs:

- working DEVONthink topology
- documented metadata schema in practice
- initial template notes

Dependencies:

- none

Why early:

- everything else depends on real objects and real naming

### WP-02: Scratch database and validation harness

Scope:

- establish `PKIM-Pilot`
- create safe test fixtures
- define representative records and note cases

Outputs:

- repeatable scratch validation surface
- seed records for automation tests

Dependencies:

- WP-01

Why early:

- you should not test write behaviour on production libraries like an idiot

### WP-03: Shared command surface

Scope:

- create repo command wrappers
- establish runtime-neutral entry points
- define help output and stable command names

Outputs:

- `pkim` command or equivalent wrapper
- shared environment usage

Dependencies:

- repo hygiene base

Why early:

- Claude and Codex need the same door into the system

### WP-04: Capability probing

Scope:

- inspect effective local command and helper surface
- emit capability manifest
- compare against expected command set

Outputs:

- capability probe tool
- committed or generated capability manifest

Dependencies:

- WP-03

Why early:

- helper and command drift is a real risk, and optional MCP transport can drift separately

### WP-05: Read-only profiling

Scope:

- fetch properties and content
- run compare/classify
- emit profile packets

Outputs:

- read-only profile command
- profile packet schema

Dependencies:

- WP-04
- WP-02

Why early:

- immediate utility with low risk

### WP-06: Native note creation

Scope:

- create or update knowledge notes
- establish template application rules
- link evidence and aliases

Outputs:

- note creation wrapper
- note template contract

Dependencies:

- WP-01
- WP-05

Why here:

- this is where the system starts producing actual second-brain value

### WP-07: Relation-note creation

Scope:

- create relation-note templates
- support source/target link injection
- validate relation-note structure

Outputs:

- relation-note wrapper
- validation rules

Dependencies:

- WP-06

### WP-08: Custom metadata writeback

Scope:

- build deterministic metadata helper
- support bounded approved writes
- verify post-write state

Outputs:

- metadata write wrapper
- mutation result schema

Dependencies:

- WP-02
- WP-04

Risk:

- one of the more likely interface pain points

### WP-09: Mirror export

Scope:

- export changed native notes
- write portable markdown
- emit export manifest
- detect drift

Outputs:

- mirror sync command
- manifest schema

Dependencies:

- WP-06

Why important:

- preserves Git, external analysis, and portability value

### WP-10: Filing controller

Scope:

- destination proposal
- replicate or move logic
- indexed risk handling

Outputs:

- safe filing wrapper
- filing policy rules

Dependencies:

- WP-05
- WP-08

### WP-11: Logs and observability

Scope:

- run manifests
- summaries
- error classes
- simple metrics extraction

Outputs:

- consistent run artifacts
- basic operational visibility

Dependencies:

- WP-03

### WP-12: Prompt and skill pack

Scope:

- repo-carried prompts
- skill definitions or contracts
- examples for Claude and Codex

Outputs:

- prompt files
- skill docs

Dependencies:

- WP-03
- WP-05
- WP-06

## Suggested Execution Order

Recommended practical order:

1. WP-01 DEVONthink baseline setup
2. WP-02 Scratch database and validation harness
3. WP-03 Shared command surface
4. WP-04 Capability probing
5. WP-05 Read-only profiling
6. WP-06 Native note creation
7. WP-09 Mirror export
8. WP-07 Relation-note creation
9. WP-08 Custom metadata writeback
10. WP-11 Logs and observability
11. WP-10 Filing controller
12. WP-12 Prompt and skill pack

This order biases toward:

- early usable value
- low-risk reads first
- making canonical knowledge notes before fighting filing automation

## Acceptance Criteria By Package

### Minimum standard

Each package should leave behind:

- implementation artifact
- design doc alignment
- test or validation path
- operational note on how to use it

### Example

`WP-05 Read-only profiling` is not done until:

- it runs
- it returns stable profile packets
- it can be exercised from both Claude and Codex
- it writes no state
- it has an example fixture or runbook

## Parallelisable Streams

These can run in parallel without much collision:

- WP-01 and template drafting for WP-06
- WP-03 and WP-11
- WP-04 and schema work
- WP-09 and mirror schema design

## Hard Dependencies

Do not skip:

- scratch validation before live writes
- capability probing before trusting the MCP
- note model before mirror export
- metadata schema before writeback

## Final Build Intent

When these packages are done, the repo will stop being a design placeholder and become the operational and development surface you asked for.
