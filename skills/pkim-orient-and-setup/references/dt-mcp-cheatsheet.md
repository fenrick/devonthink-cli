# DT MCP tool cheatsheet

The ~65 DEVONthink MCP tools you'll actually reach for, grouped by task. Full schemas live in the tool descriptions themselves — this is a "which tool do I want" index.

## Preflight

- `is_running` — DT process check
- `get_databases` — list open databases (returns UUIDs + special-group UUIDs)
- `list_custom_metadata_fields` — canonical schema check
- `get_selected_records` / `get_current_record` — what the human has focused in the GUI

## Reads (single record)

- `get_record_properties` — name, type, location, dates, metrics, custom metadata (via a separate call), tags. `path` field only for indexed records.
- `get_record_custom_metadata` — just the custom metadata dict
- `get_record_text` — raw body for text-native records; empty string for PDFs/images/webarchives (use `extract_record_content` for those)
- `get_record_tags` — the tag list
- `get_record_annotation` — annotation record
- `get_record_children` / `get_record_parents` — direct navigation
- `get_record_links` / `get_record_external_references` — what this record links to
- `get_record_unlinked_wiki_links` — WikiLinks in the body that don't resolve
- `get_record_duplicates` / `get_record_versions` — dedupe + history
- `get_imported_record_path` — on-disk path for imported records (indexed records get it via `get_record_properties`)

Batch mode: pass `uuids: [...]` to any single-record read to fetch many at once.

## Discovery

- `search_records` — the powerhouse. DT query syntax with boolean, wildcards, numeric, date, `md<field>:` custom-metadata predicates, sub-criteria. Read the tool description — the syntax is rich.
- `lookup_records` — exact match by exactly one attribute (name, URL, path, location, filename, comment). Use this for "does this URL already exist" dedup checks; use it for group-by-location resolution.
- `get_group_tree` — recursive group hierarchy
- `list_database_tags` — vocabulary check

## Writes

- `create_record` — creates a new record. Type `markdown` for KN/RL/CL, `text`/`rtf`/`html`/`bookmark`/`sheet` for evidence when relevant. For **indexed** creates, write the `.md` file to disk first then `import_file mode="index"` — `create_record` produces imported records, not indexed.
- `create_group_path` — idempotent nested-group creation (mkdir -p).
- `import_file` — bring a file on disk into DT (`mode: "import"` copies into `.dtBase2`, `mode: "index"` references in place).
- `update_record` — non-content properties (name, comment, url, tags).
- `update_record_content` — body writes. Modes: `append`, `insert`, `replace`, `patch` (unified diff — use for large-document edits).
- `set_record_custom_metadata` — the metadata write. **Always pass `mode="merge"`** unless you deliberately want to drop untouched fields.
- `set_record_tags` — full-replace tag set.
- `set_record_annotation` — annotation body.
- `set_record_reminder` / `clear_record_reminder` — reminders.
- `move_record` — relocate (preferred over replicate + trash).
- `duplicate_record` / `replicate_record` — copies; use rarely.
- `merge_records` — combine two records.
- `trash_record` — soft delete.
- `open_record` — focus in DT GUI.

Batch mode: writes accept `uuids: [...]` for parallel application.

## Content operations

- `convert_record` — deliberate format change.
- `export_record` — write outside DT.
- `capture_web_page` — pull a live URL.
- `ocr_record` — OCR a scanned PDF or image.
- `transcribe_record` — audio/video to text.
- `extract_record_content` — get textual content out of PDFs / images / web archives (chunked + AI-safe). This is the "PDF body for AI" tool, not `get_record_text`.
- `extract_record_highlights` / `_mentions` / `_visuals` — richer extraction subtypes.
- `summarize_record_highlights` / `_mentions` — synthesis.

## AI / semantic

- `classify_record` — DT's built-in classifier proposes groups. Uses DT's ML, not the caller's — real complement.
- `find_similar_records` — DT's similarity engine.
- `chat_response` — send a prompt to DT's chat with record context.
- `research_topic` — richer research chain.

## Bibliographic

- `resolve_doi_metadata` — enrich by DOI.
- `resolve_book_metadata` — enrich by ISBN.
- `download_pdf_from_doi` — fetch and import.
- `search_crossref` — search academic index.

## Redaction + exclusion (built-in, not caller-side)

- Per-record `Exclude from AI` — DT MCP refuses to operate on excluded records both as input and in result lists.
- Per-database `Exclude from Chat & MCP` — blocks an entire database.
- PII redaction — emails, links, credit cards, phone numbers, tokens, labelled secrets — applied on AI-facing tools (`chat_response`, `research_topic`, `extract_record_content` for AI consumption). Raw reads via `get_record_text` are unredacted.

## Common patterns

- "**Look up a record by PKIM_ID**": `search_records query: "mdpkim_id:<PKIM_ID>"` — DT returns the UUID + brief.
- "**Read a KN's body and its custom metadata together**": one batch call each — `get_record_text` and `get_record_custom_metadata`, both with the same UUID.
- "**Create a KN and stamp its PKIM_ID + tags in one flow**":
  1. `create_record` type `markdown`, name, content, destination
  2. `set_record_custom_metadata` mode `merge` with `pkim_id`, `docrole`, `review_state`
  3. `set_record_tags` with the structural + topical tag set
- "**Patch a large KN body with a small change**": `get_record_text` first, build a unified-diff patch against exactly that content, `update_record_content mode="patch"` with the patch.

## What NOT to do

- Do not modify files inside a `.dtBase2` package via the filesystem. The MCP warns explicitly — direct writes corrupt the database.
- Do not call `set_record_custom_metadata mode="replace"` unless you intend to drop every field not in the payload. This is a common footgun.
- Do not use WikiLinks `[[...]]` for cross-database references. See [wikilink-and-item-link.md](wikilink-and-item-link.md).
