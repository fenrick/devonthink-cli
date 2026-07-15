# Per-record intake workflow

The subagent's step-by-step. One record, one pass.

## 1. Read

```
mcp__devonthink__get_record_properties  uuid: <UUID>
mcp__devonthink__get_record_custom_metadata  uuid: <UUID>
mcp__devonthink__get_record_tags  uuid: <UUID>
```

Then, depending on the record's `kind`:

- **Text-native** (markdown / txt / html / formatted_note / rtf): `get_record_text`.
- **PDF / webarchive / image**: `extract_record_content` — this is chunked + AI-safe, unlike `get_record_text` which returns empty for binary formats.
- **Audio / video**: `transcribe_record` if you need the text; skip if you don't.
- **Sheet**: `get_record_text` returns the CSV/TSV verbatim.

Skip content extraction if you can classify + enrich from properties alone (rare — most decisions need the body).

## 2. Classify

Almost always **EV** (evidence) — records in `/Inbox` are new captures. If you find a KN, RL, or CL in the inbox, something has come in wrong; flag it as `needs-human` unless the operator has explicitly said "the inbox has a mixed batch."

The record's `kind` and content usually make classification obvious:

- PDFs, HTML, webarchives, formatted notes, imported files → EV
- Native markdown files under `/Notes/*` → KN/RL/CL (should not be in `/Inbox`)

## 3. Mint PKIM_ID (if absent)

Read `mdpkim_id` from the record's custom metadata. If missing:

1. Determine class (usually `EV`).
2. Get today's UTC date as `YYYYMMDD`.
3. Query DT: `mcp__devonthink__search_records query: "mdpkim_id:<CLASS>-<DATE>-*"`.
4. Parse the highest sequence number returned; new seq = max + 1. If no matches, seq = 1.
5. Format: `<CLASS>-<DATE>-<0001>` with zero-padded 4 digits.

You'll write it in step 4 with the other metadata.

## 4. Write metadata

`mcp__devonthink__set_record_custom_metadata` with `mode: "merge"`. For an EV, the required fields:

```json
{
  "pkim_id": "EV-20260715-0001",
  "docrole": "evidence",
  "evidencestatus": "proposed",
  "capturetype": "import",        // or clip/scan/web/note
  "review_state": "profiled",      // was "inbox"; will become "filed" in step 8
  "origin_uri": "...",            // if known
  "primarytopic": "..."            // your best-guess topic string
}
```

For records that already carry some of these fields, `merge` preserves the untouched ones. Double-check `dropped_fields` in the response — a non-empty array means DT rejected a value (e.g. free-text supplied to an enum field).

## 5. Update aliases

The record's `aliases` field should include the `PKIM_ID` semicolon-joined with the display name:

```
mcp__devonthink__update_record  uuid: <UUID>  aliases: "<Display Name>; EV-20260715-0001"
```

Fetch the current `aliases` first via `get_record_properties`; if it already carries the PKIM_ID, skip.

## 6. Apply tags

`mcp__devonthink__set_record_tags` — replaces the tag set. Compose:

**Structural** (from `skills/pkim-orient-and-setup/references/tag-axes.md`):

- `pkim/evidence`
- `evidence/status/<proposed|approved|retired|superseded>`
- `evidence/capture/<import|clip|scan|web|note>`

**Topical** (open vocabulary — infer from the content):

- `domain/<broad-area>` — always. Digital-transformation, enterprise-architecture, personal, work, etc.
- `concept/<named-thing>` — always. The concept the record is *about*.
- `source/<class>` — always. `source/vendor-research`, `source/industry-analyst`, `source/peer-reviewed`, `source/blog-post`, etc.
- `entity/<name>` — when the record names a specific org / product / person.
- `year/<YYYY>` — when the content is time-bounded.
- `method/<approach>` — optional; when the source's method matters.

If you can't determine meaningful topical tags, **surface as `needs-human`**. An untagged record is invisible to DT's navigation.

## 7. Author a KN (only if warranted)

Read [kn-authoring.md](kn-authoring.md). Do not routinely create a KN — only when the evidence genuinely calls for one. If you do author a KN:

1. Follow the KN authoring steps in `kn-authoring.md`.
2. Add `authored-kn:<PKIM_ID>` to the `actions_taken` array in your return summary.
3. If the new KN cites another record, author an RL — read [rl-authoring.md](rl-authoring.md).

## 8. File

Read [safe-file-rules.md](safe-file-rules.md). Determine the destination from the record's class + kind + your enrichment. Move via `mcp__devonthink__move_record`.

Then update `review_state` to `filed` with `set_record_custom_metadata mode="merge"`.

## 9. Return

Print the JSON summary per the brief. If any step returned an error or an ambiguous decision, return `verdict: needs-human` with a clear one-line reason.

## Failure modes

| Symptom | What to do |
|---|---|
| `get_record_properties` returns `{running: false}` context | DT stopped; return `verdict: error, notes: "DT not running"` |
| `set_record_custom_metadata` returns `dropped_fields: [...]` | Log which fields, retry with corrected values; if you can't correct, return `needs-human` |
| The record has `mdreview_state == "needs-human"` already | Do not overwrite; return `verdict: needs-human, notes: "already flagged for human review"` |
| `extract_record_content` returns redacted content | Fine for enrichment purposes; note in `notes` |
| The record's `location` is not `/Inbox` when you started | You've been dispatched against a stale ledger; return `verdict: error, notes: "record no longer in scope"` |
