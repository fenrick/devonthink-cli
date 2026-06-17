# PKIM Smart Groups Setup

## Purpose

Step-by-step guide for creating the 10 canonical PKIM smart groups in DEVONthink.

Use this when building or repairing queue visibility in DEVONthink. It is a setup checklist, not the workflow policy for what to do with each queue.

Smart groups are created in the DEVONthink UI. Run `verify-smart-groups.applescript` after each database to confirm names and record predicate strings.

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

Run the verify script to confirm all groups exist and capture their predicate strings:

```bash
osascript scripts/verify-smart-groups.applescript
```

Record the predicate strings output in the Notes section of `docs/ops/build-plan.md` Step 04. The predicate strings are needed if smart groups ever need to be recreated or migrated.

---

## Done condition

- [ ] All 10 smart groups created with the names exactly as shown above
- [ ] Each smart group returns non-empty results when test records exist matching the condition
- [ ] `osascript scripts/verify-smart-groups.applescript` shows all groups found
- [ ] Predicate strings recorded in build-plan.md Step 04 Notes
