# PKIM Smart Groups Setup

> **Runtime note (2026-07-15).** Any `pkim <verb>` reference below is historical. The runtime is DEVONthink 4.3+'s in-app MCP server; see [../design/07-runtime.md](../design/07-runtime.md) for how skills compose DT MCP.

## Purpose

Step-by-step guide for creating the 10 canonical PKIM smart groups in DEVONthink.

Use this when building or repairing queue visibility in DEVONthink. It is a setup checklist, not the workflow policy for what to do with each queue.

Smart groups are usually installed by the [`dt-bootstrap`](../../skills/dt-bootstrap/SKILL.md) skill; this document is the manual reference for the operator who wants to do it by hand or to verify what bootstrap produced. `dt-bootstrap` uses text predicates (which match records whose metadata is written via MCP); the DEVONthink GUI picker emits binary predicates that don't match — that's why bootstrap rebuilds smart groups the GUI created.

---

## How to create a smart group

1. In the DEVONthink sidebar, select the target database.
2. **File > New > Smart Group** (or right-click the database → New Smart Group).
3. Name it exactly as shown.
4. Click the `+` button to add conditions.
5. Set the **Match** dropdown at the top: **All** (AND) or **Any** (OR) as indicated.
6. For each condition: choose the attribute from the first dropdown, then the operator, then the value.
7. Click **OK**.

To add a **Custom Metadata** condition: first dropdown → **Custom Metadata** → choose the field name from the sub-menu → set operator and value.

---

## Smart group definitions

### 1. Needs Profile

**Database scope:** All five databases (create once per database, or use a global smart group)
**Match:** Any

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: PKIM_ID | is empty | — |
| Custom Metadata: Review_State | is empty | — |

**Purpose:** Surfaces any record that has not yet been profiled (no PKIM_ID or no Review_State set).

---

### 2. Needs OCR

**Database scope:** Evidence databases (Personal, Work, Server, Pilot)
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Needs_OCR | is checked | — |

**Purpose:** Records flagged as requiring OCR processing.

---

### 3. Needs Knowledge Note

**Database scope:** Evidence databases (Personal, Work, Server, Pilot)
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Knowledge_Link_State | is empty | — |

**Purpose:** Evidence records not yet linked to a knowledge note.

---

### 4. Needs Relation Note

**Database scope:** PKIM-Knowledge
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Relation_Gap_State | is not empty | — |

**Purpose:** Knowledge notes flagged as needing a relation note to capture a gap.

---

### 5. Needs Filing

**Database scope:** All five databases
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Review_State | is | approved |

**Purpose:** Records approved for the next enrichment or filing step. Do not treat this queue as "move immediately"; confirm title, tags, note linkage, and real destination first.

Note: DEVONthink smart groups cannot easily express "location contains Inbox OR Working" as a nested OR-AND condition. The Review_State=approved condition is the primary gate; the operator reviews the location manually.

---

### 6. Indexed Risk

**Database scope:** Evidence databases (Personal, Work, Server, Pilot)
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Indexed_Risk_State | is not empty | — |

**Purpose:** Evidence records flagged with a path or refresh risk for indexed content.

---

### 7. Mirror Drift

**Database scope:** PKIM-Knowledge
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Mirror_State | is | stale |

**Purpose:** Knowledge notes whose mirror export is out of date.

---

### 8. Automation Error

**Database scope:** All five databases
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Automation_Last_Run_State | is | error |

**Purpose:** Records where the last automation run left an error state.

---

### 9. Needs Human Review

**Database scope:** All five databases
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Review_State | is | needs-human |

**Purpose:** Records that have been flagged as requiring a human decision before automation can proceed.

---

### 10. Ready for Mirror

**Database scope:** PKIM-Knowledge
**Match:** All

| Attribute | Operator | Value |
|---|---|---|
| Custom Metadata: Review_State | is | approved |
| Custom Metadata: KnowledgeStatus | is | active |

**Purpose:** Knowledge notes that are approved and active — the set that should be included in the next mirror export.

---

## After creation

Confirm the groups are present and their predicates match the canonical set by running the [`dt-bootstrap`](../../skills/dt-bootstrap/SKILL.md) skill. Its Phase 3 verify step reports every canonical smart group as `already-present` or `created`. A smart group whose predicate diverges from the canonical text form is flagged by [`dt-audit`](../../skills/dt-audit/SKILL.md).

---

## Done condition

- [ ] All 10 smart groups created with the names exactly as shown above.
- [ ] Each smart group returns non-empty results when test records exist matching the condition.
- [ ] `dt-bootstrap` reports every canonical smart group as `already-present` or `created`.
