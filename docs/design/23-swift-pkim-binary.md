# Swift `pkim` Binary

## Purpose

The contract for the compiled CLI introduced by [22 CLI-First Atomic Primitives](22-cli-first-atomic-primitives.md). This document is canonical for the binary's command surface, JSON envelope, project layout, and runtime behaviour. It is the artefact the Xcode implementation workstream is built against.

Doc 22 explains *why* the binary exists and what gets retired. Doc 23 explains *exactly what the binary does* — verb by verb, flag by flag, envelope by envelope.

## Scope

In scope: the CLI surface, the JSON envelope, exit codes, the read-plane and write-plane architectures, the run-manifest model, the write-gate enforcement, the project layout, and the Xcode setup walkthrough.

Out of scope: the Swift implementation itself, performance benchmarks, the MCP shim (if any), and the post-pivot rewrites of skill bodies. Those are all downstream of this contract.

## Project layout

Source of truth is a SwiftPM `Package.swift` at `pkim-binary/` (sibling to `src/`, `docs/`). Xcode opens the package directly; the build is also scriptable from the command line and from CI.

```
pkim-binary/
├── Package.swift
├── Sources/
│   ├── pkim/                      # executable target
│   │   ├── main.swift             # entry point, ArgumentParser root command
│   │   ├── Commands/              # one file per verb (~21 files)
│   │   ├── Domain/                # ported domain types (PKIMId, RecordHandle, …)
│   │   ├── MetadataCache/         # .dt file parser, mdfind wrapper
│   │   ├── Bridge/                # ScriptingBridge calls for write verbs
│   │   ├── Runtime/               # run-id, run-manifest, write-gate enforcement
│   │   └── JSON/                  # shared envelope + error types
│   └── PkimCore/                  # (optional) library target if extraction reuse appears
└── Tests/
    └── pkimTests/                 # XCTest targets per verb + per module
```

Single executable target initially. Library targets added only when a clear reuse boundary emerges (e.g. the MCP shim wanting to link `PkimCore`).

### Dependencies

- `swift-argument-parser` (Apple, SwiftPM) — CLI parsing.
- `Foundation` — JSON, file IO, `.dt` binary parsing.
- `ScriptingBridge.framework` — write verbs into DEVONthink. System framework, no SwiftPM dep.
- `/usr/bin/mdfind` (subprocess) — Spotlight queries for `search` and `mint-id`'s next-sequence scan. No SwiftPM dep; shell-out only.
- `PDFKit.framework` — `extract-text` for PDF content extraction.

Target: zero third-party SwiftPM dependencies beyond `swift-argument-parser`. If a niche file format needs a vendored parser, add it as a `Package.swift` dependency with justification in this doc.

## CLI contract

### Invocation shape

```
pkim <verb> [--flag value]… [<positional>…]
```

Every verb:

- accepts flags + positionals defined per verb below;
- accepts a `--from @<path>` form anywhere a large blob (markdown body) is needed, reading the named file;
- writes a single JSON object to stdout;
- exits with `0` on success or a non-zero code on failure (see §Exit codes);
- writes a run manifest into `runs/<run-id>/` (see §Run manifests).

### Standard JSON envelope (success)

```json
{
  "ok": true,
  "verb": "<verb-name>",
  "run_id": "<rfc3339-timestamp>-<6-hex>",
  "data": { … verb-specific … },
  "warnings": []
}
```

### Standard JSON envelope (failure)

```json
{
  "ok": false,
  "verb": "<verb-name>",
  "run_id": "<rfc3339-timestamp>-<6-hex>",
  "error_type": "<one of the error codes below>",
  "error_message": "<one-sentence human-readable>",
  "context": { … verb-specific diagnostic, optional … }
}
```

Both shapes carry `verb` and `run_id` so an agent can correlate stdout with disk artefacts unambiguously.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | success |
| `1` | usage / argument error (caught by ArgumentParser before any work) |
| `2` | invalid input (validation failed; record not found; etc.) |
| `3` | DEVONthink unreachable / write gate denied / capability probe failed |
| `4` | partial success (write succeeded but verify or post-step failed; see `data.partial` for shape) |
| `5` | I/O error reading or writing on disk (`.dt` cache, indexed file, run manifest) |
| `99` | unknown / internal error (programmer error; opens an issue) |

`error_type` values mirror these codes by name (`UsageError`, `InvalidInput`, `DEVONthinkUnreachable`, `WriteGateDenied`, `RecordNotFound`, `PartialFailure`, `IOError`, `InternalError`). One verb may define additional `error_type` values; they always map to one of these exit codes.

## Verb surface (25 atomic + 1 skill-composed)

Originally 20 atomic verbs (the §Reads / §Writes / §Auxiliary tables
below). The pivot follow-up branch added five **setup verbs** ported
from the AppleScript helpers in `scripts/` — see §Setup verbs. These
encode the canonical PKIM database/smart-group/template configuration
and are deliberately policy-laden (per the AppleScripts they replaced).
The atomic-only verb count is 20; the full binary surface is 25.

Reads and mirror verbs default to *no DEVONthink running required* (the cache plane works offline). Writes require DT to be running and the env-var write gate to be open.

Three read planes converge in the binary; each verb picks the right one per its freshness/latency budget. The §Read-plane and §Write-plane sections below name them; here we just list what each verb does and what JSON it returns.

### Reads (cache plane unless noted)

#### `pkim get <ref>`

Reads via the `.dt` cache (sub-millisecond) — may lag DT by tens of seconds.

```json
"data": {
  "pkim_id": "KN-20260520-0003",
  "dt_uuid": "1B79…",
  "name": "Purpose Design",
  "record_type": "Markdown",
  "item_link": "x-devonthink-item://1B79…",
  "database_name": "PKIM-Knowledge",
  "database_path": "~/Databases/PKIM/PKIM-Knowledge.dtBase2",
  "doc_role": "knowledge",
  "review_state": "approved",
  "aliases": [ … ],
  "custom_metadata": { … },
  "is_indexed": false,
  "filename": "Purpose Design.md",
  "file_path": "/Users/…/…/PKIM-Knowledge.dtBase2/Files.noindex/…/…",
  "uti": "public.plain-text"
}
```

Top-level `doc_role` / `review_state` are lifted from `custom_metadata` for caller convenience. Three things doc-23's first sketch listed are not on this verb — `location` (no cache equivalent; defer until needed), `tags` (own verb), and `word_count` (own verb's payload includes it).

#### `pkim resolve <ref>`

`data: { ref, pkim_id, dt_uuid, item_link, database_name }`. Cache plane; one round-trip when ref is a PKIM_ID (mdfind), zero when it's a UUID or item link.

#### `pkim list <db> [--group /<path>] [--limit N]`

SB plane (`parent.children()`). `--group` defaults to `/` (database root).

```json
"data": {
  "database": "PKIM-Knowledge",
  "group": "/Inbox/",
  "returned": 12,
  "records": [
    { "pkim_id": "…", "dt_uuid": "…", "name": "…", "record_type": "Markdown", "is_group": false, "item_link": "…" }
  ]
}
```

`is_group` is true when `recordType ∈ {group, smartGroup}` *or* the record has any direct children. The fallback catches Inbox / Tags / All-PDF smart-group views that report a `recordType` outside the typed enum; empty special groups (Trash with no contents) report `is_group: false` because both signals fail — acceptable edge case.

#### `pkim search <db> [--field K=V]… [--text Q] [--limit N]`

mdfind-backed. Each `--field K=V` compiles to a `com_DEVONtechnologies_think_md<K> == "V"` predicate (supports `*` wildcards). `--text Q` compiles to `kMDItemTextContent == "Q*"`. All clauses are AND-ed with a database-scope predicate.

```json
"data": {
  "database": "PKIM-Knowledge",
  "query": "com_DEVONtechnologies_think_DatabaseName == \"PKIM-Knowledge\" && com_DEVONtechnologies_think_mddocrole == \"knowledge\"",
  "matched": 24,
  "returned": 5,
  "records": [
    { "pkim_id", "dt_uuid", "name", "record_type", "doc_role", "review_state", "item_link" }
  ]
}
```

Per-row details come from the cache parser (sub-ms each); freshness-sensitive callers re-read per row via `pkim get`.

#### `pkim body <ref>`

Indexed records → read the canonical disk file (file-as-truth). Imported records → read via SB `record.plainText` (always fresh, not the lagged cache TEXT field).

```json
"data": {
  "ref": "…",
  "dt_uuid": "…",
  "source": "indexed-file" | "sb-plain-text",
  "word_count": 412,
  "text": "…"
}
```

#### `pkim aliases <ref>`

SB plane (`record.aliases`, force-resolved). Splits DT's semicolon-or-newline-separated alias string into an array.

`data: { ref, dt_uuid, aliases: [...] }`.

#### `pkim tags <ref>`

SB plane (`record.tags`, force-resolved). NOT mdls — that path lags writes.

`data: { ref, dt_uuid, tags: [...] }`.

#### `pkim file-path <ref>`

Cache plane.

`data: { ref, dt_uuid, file_path, is_indexed }`. `is_indexed` is true when the path lives outside the `.dtBase2/Files.noindex/` tree.

### Writes

Default behaviour is to write. Add `--dry-run` to preview: the verb computes the proposed change, writes `mutation-proposal.json` under `runs/<run-id>/`, and exits `0` with `data.kind: "dry-run"` without touching DT. Without `--dry-run` the verb executes through SB and writes `mutation.json`.

Primary gate: `PKIM_ALLOW_PRODUCTION_WRITES=true`. Without it, any non-`--dry-run` invocation exits `3` with `error_type: "DEVONthinkUnreachable"` before reaching DEVONthink. Dry-runs short-circuit the gate.

On a live write the pre-read is deliberately skipped — it would just decorate the manifest at the cost of one Apple Event per touched field. The manifest's `before` slot is `null`; the post-write verify-read gives the authoritative `after`. Callers who want a diff run `--dry-run` first.

Set-Tags is the one exception: `--add` and `--remove` need the current set to compute the final list, so the pre-read stays for those modes. The full-replace `--tag` mode skips it.

#### `pkim set-metadata <ref> <K=V>…`

```
pkim set-metadata KN-20260520-0003 Review_State=approved Claim_Backed=true
```

Each `K=V` becomes one `addCustomMetaData(value, for: key, to: record, as: nil)` call (one Apple Event per delta). Empty value `K=` clears the key (`addCustomMetaData("", …)` — DT removes the key). Other keys are never touched, so date-typed values like `mdlastprofiledat` can't drift.

```json
"data": {
  "ref": "…",
  "dt_uuid": "…",
  "applied": true,
  "kind": "ok" | "dry-run",
  "changes": [{ "field": "Review_State", "before": null, "after": "approved" }],
  "touched": { "Review_State": "approved", "Claim_Backed": "true" },
  "run_dir": "/.../runs/2026-05-20T…/"
}
```

`touched` is the post-write verify-read for live runs / the projected after-state for dry-runs. Keys cleared by the call are absent (not present with empty value), preserving the cleared/empty distinction.

#### `pkim set-tags <ref> [--tag T]… [--add T]… [--remove T]…`

`--tag` replaces the set wholesale (set-semantic; DT dedupes). `--add` / `--remove` layer on top of the current set — these need a pre-read even on a live run because the final list depends on what's there.

```json
"data": {
  "ref", "dt_uuid", "applied", "kind",
  "changes": [{ "tag": "purpose", "change": "added" } | { … "removed" } | { … "set" }],
  "tags": [ … final tag set as DT persisted it … ],
  "run_dir": "…"
}
```

DT dedupes the input array silently; the verify-read gives the canonical persisted set.

#### `pkim set-name <ref> <name>`

```json
"data": {
  "ref", "dt_uuid", "applied", "kind",
  "before": null | "old name",   // null on live, populated on dry-run
  "after": "new name",            // post-write verify-read
  "run_dir": "…"
}
```

#### `pkim set-body <ref> --from @<path>`

Source policy mirrors `pkim body`: indexed records → write the on-disk file directly (file-as-truth); imported records → `record.setPlainText(body)` via SB. `--from @-` reads from stdin.

```json
"data": {
  "ref", "dt_uuid", "applied", "kind",
  "target": "indexed-file" | "imported-plain-text",
  "file_path": "…",
  "body_chars": N,
  "run_dir": "…"
}
```

`body_chars` on a live run is the size of what DT actually persisted (verify-read). DT silently no-ops on rich-text or binary record kinds — the verify-read will report 0 in that case.

#### `pkim move <ref> --to <group-path> [--database <name>]`

`from: nil` semantics — DT "moves all instances", so the record ends up cleanly relocated rather than leaving stale copies in tag groups or replicants. Destination group must exist (run `pkim create-group` first if not). `--database` is optional; defaults to the record's own database via the cache lookup.

Move-only. Never replicates or duplicates. (Per the user-memory entry on `dt.replicate` creating duplicates in DT4.)

```json
"data": {
  "ref", "dt_uuid", "applied", "kind",
  "before": null | "/Sources/Imported/",   // dry-run only
  "after": "/Inbox/",
  "database": "PKIM-Pilot",
  "run_dir": "…"
}
```

#### `pkim create-note <db> --group <path> --title <name> --body @<path-or-->`

Optional flags: `--type markdown|txt|rtf|html` (default markdown), `--pkim-id <id>` to use a specific ID, `--pkim-class kn|rl|ev|cl` for the mint when no ID is supplied (default `kn`). Destination group must exist.

The verb mints a PKIM_ID via the cache scan if `--pkim-id` is omitted, then calls `app.createRecordWith(props, in: parent)` (one Apple Event) with the title, type, plain text, and the PKIM_ID set as an alias. Stamps `mdpkim_id` into customMetaData via `addCustomMetaData` so the mdfind-by-PKIM_ID resolve path works on subsequent reads.

```json
"data": {
  "applied", "kind",
  "pkim_id": "KN-20260520-0007",
  "dt_uuid": "…",
  "database": "PKIM-Knowledge",
  "group": "/Inbox/",
  "title": "Purpose Design",
  "type": "markdown",
  "location": "/Inbox/Purpose Design",
  "body_chars": 412,
  "run_dir": "…"
}
```

#### `pkim create-group <db> --path <path>`

Calls `app.createLocation(path, in: db)` — idempotent. Creates any missing intermediate groups along the path.

```json
"data": {
  "applied", "kind": "created" | "exists" | "dry-run",
  "database": "PKIM-Knowledge",
  "path": "/Inbox/Sources/Imported/",
  "dt_uuid": "…",
  "existed": true | false,
  "run_dir": "…"
}
```

`existed` distinguishes "DT just made this" from "this was already here".

### Mirror / file layer

#### `pkim mirror-of <ref>`

Reads the record's `mdmirror_path` custom-metadata field and resolves against `PKIM_MIRROR_ROOT` (or `~/PKIM-mirror/`). Pure cache read; no DT round-trip. Returns `mirror_path: ""` if the record doesn't carry an `mdmirror_path` field.

```json
"data": {
  "ref", "dt_uuid", "pkim_id",
  "mirror_path": "/Users/x/PKIM-mirror/knowledge/KN-20260429-0002-purpose-design.md",
  "mirror_path_relative": "knowledge/KN-20260429-0002-purpose-design.md",
  "mirror_root": "/Users/x/PKIM-mirror",
  "exists": true | false
}
```

#### `pkim sync-record <ref>` — **skill-composed, not a binary verb**

The original spec called for a primitive that read the indexed `.md` file, read the DT record, computed the diff, applied set-metadata / set-body, and emitted a mirror DB row. That's *policy* — file-as-truth reconciliation workflow — and per the doc-22 layer rules policy lives in skill markdown, not the binary.

Skill `dt-sync-export-mirror` composes `pkim get` + `pkim body` + `pkim set-metadata` + `pkim set-body` to do the same work, with the diff rules visible in prose. The Swift binary deliberately doesn't ship this as one verb.

### Auxiliary

#### `pkim extract-text <file-path-or-ref>`

Accepts a filesystem path OR a record reference. For refs, resolves to the record's file path via the cache plane first.

Format dispatch by extension:
| Extension | Extractor |
|---|---|
| `.pdf` | PDFKit |
| `.txt`, `.md`, `.markdown` | UTF-8 read |
| `.html`, `.htm` | NSAttributedString HTML decode |
| `.rtf` | NSAttributedString RTF decode |
| anything else | `error_type: "InvalidInput"` |

Out of scope (use Python `src/pkim/extraction/` for the long tail): DOCX, PPTX, XLSX, EPUB, RTFD.

```json
"data": {
  "target": "<input>",
  "file_path": "/resolved/path",
  "extractor": "pdfkit" | "utf8" | "nsattributedstring-html" | "nsattributedstring-rtf",
  "word_count": N,
  "text": "…"
}
```

#### `pkim probe-capabilities`

```json
"data": {
  "pkim_version": "0.1.0-dev",
  "devonthink_bundle": "com.devon-technologies.think",
  "devonthink_installed": true,
  "devonthink_running": true,
  "devonthink_version": "4.1.1",
  "open_databases": [ "PKIM-Knowledge", "PKIM-Pilot", … ],
  "write_gate_open": false,
  "cache_root": "/Users/x/Library/Metadata/com.devon-technologies.think",
  "cache_reachable": true,
  "cache_databases": [ … database UUIDs found on disk … ]
}
```

#### `pkim health-check [--database <name>]`

Aggregates the probe into a pass/fail check list. `--database` defaults to `PKIM-Knowledge`.

```json
"data": {
  "result": "ok" | "failed",
  "database": "PKIM-Knowledge",
  "checks": [
    { "name": "devonthink-installed",        "passed": true,  "detail": "…" },
    { "name": "devonthink-running",          "passed": true,  "detail": "…" },
    { "name": "required-database-open",      "passed": true,  "detail": "…" },
    { "name": "write-gate-status",           "passed": true,  "detail": "…" },  // informational only
    { "name": "metadata-cache-reachable",    "passed": true,  "detail": "…" }
  ],
  "failed_checks": [ … names of blocking checks that didn't pass … ]
}
```

`write-gate-status` is informational and never counted as a failure — it just reports whether `PKIM_ALLOW_PRODUCTION_WRITES=true`.

#### `pkim mint-id --type <kn|rl|ev|cl> [--date YYYYMMDD] [--sequence N]`

Default: scans the live cache via `mdfind 'com_DEVONtechnologies_think_mdpkim_id == "<CLASS>-<DATE>-*"'` for the highest sequence, returns max + 1. With `--sequence N` supplied, skips the scan and uses N as-is (recovery / test path).

```json
"data": {
  "pkim_id": "KN-20260520-0007",
  "type": "kn",
  "date": "20260520",
  "sequence": 7
}
```

Single-user assumption — no distributed-lock complexity. Two concurrent calls on the same day/class could race; the recommended pattern is to mint and immediately call `create-note` so the new record's ID is registered before the next mint scans.

### Setup verbs (canonical PKIM bootstrap)

These five verbs encode the canonical PKIM database/smart-group/
template configuration — a direct port of the AppleScript helpers
that used to live in `scripts/`. They are *not* atomic primitives
under the doc-22 layer rules: each one composes multiple Apple Events
and hardcodes PKIM policy (database names, group paths, smart-group
predicates, template content). The policy lives in
`Sources/pkim/Setup/PKIMSetup.swift`.

Future variation (a different group shape, additional smart groups)
should be expressed as a config file the verb reads at runtime rather
than by editing `PKIMSetup.swift`. For the canonical PKIM bootstrap
the hardcoded shape is the contract.

#### `pkim setup-database <name> [--shape knowledge|evidence]`

Creates the canonical group tree for the database. Shape is inferred
from the name (`PKIM-Knowledge` → `knowledge`, `PKIM-Evidence-*` and
`PKIM-Pilot` → `evidence`); override with `--shape`. Idempotent —
`createLocation` returns the existing group when the path is already
present. Write-gated; supports `--dry-run`.

```json
"data": {
  "applied", "kind",
  "database": "PKIM-Knowledge",
  "shape": "knowledge",
  "groups": [
    { "path": "/Inbox", "existed": true,  "created": false, "error": null },
    { "path": "/Notes", "existed": false, "created": true,  "error": null }
  ],
  "run_dir": "…"
}
```

#### `pkim verify-database <name> [--shape knowledge|evidence]`

Read-only. Returns `result: "ok" | "failed"` plus a per-group
present/absent list and the failed paths.

```json
"data": {
  "result": "ok",
  "database": "PKIM-Knowledge",
  "shape": "knowledge",
  "checks": [{ "path": "/Inbox", "present": true }, …],
  "failed_paths": []
}
```

#### `pkim verify-smart-groups [--database <name>]`

Read-only. Checks every canonical smart group from
`PKIMSetup.smartGroups` against every database that group is supposed
to live in. With `--database`, restricts to one DB.

```json
"data": {
  "result": "ok",
  "database": null,
  "checks": [
    { "name": "Needs Filing", "database": "PKIM-Knowledge", "present": true, "predicate": "mdreview_state==\"approved\"", "error": null }
  ],
  "failed": []
}
```

#### `pkim fix-smart-groups [--database <name>]`

Deletes and recreates the text-predicate smart groups (5 of the 10
canonical) so they match metadata written via JXA / SB. Background:
DT's GUI smart-group picker emits binary `NSPredicate`s that query the
internal field index; JXA writes go to the raw customMetaData dict;
only text predicates match those. "Is empty / is not empty" smart
groups (the other 5) work out of the box and are deliberately left
alone. Write-gated; supports `--dry-run`.

```json
"data": {
  "applied", "kind",
  "database": null,
  "changes": [
    { "name": "Needs Filing", "database": "PKIM-Knowledge", "deleted": 1, "created": true, "predicate": "mdreview_state==\"approved\"", "error": null }
  ],
  "run_dir": "…"
}
```

#### `pkim install-templates [--database <name>]`

Installs the four canonical PKIM note templates under
`<database>/Templates/`. Defaults to `PKIM-Knowledge`. Idempotent:
existing templates with the same name are skipped. Write-gated;
supports `--dry-run`.

```json
"data": {
  "applied", "kind",
  "database": "PKIM-Knowledge",
  "templates": [
    { "name": "Knowledge Note", "existed": false, "created": true, "error": null }
  ],
  "run_dir": "…"
}
```

## Operating costs (measured)

Numbers from the live bench suite running against the dev machine's actual DT + 119k-file `.dt` cache + 10 open databases. Debug build except where noted; release-build cycle times match within ±2 ms because the work is dominated by IPC and dyld, not Swift execution.

### Fixed costs (per invocation)

| Cost | Wall clock | Notes |
|---|---|---|
| Process startup (dyld + code-signing) | ~30 ms cold, ~480 ms first-after-build | One-time per `pkim` invocation. Can't be optimised away — set by the OS loader. |
| `DTBridge.connect` (SBApplication init + sdef parse) | ~30 ms cold, ~22 ms warm | Paid once per process when a verb touches SB. Reads via the cache plane skip this entirely. |
| First mdfind subprocess | ~50 ms | Fork/exec + Spotlight query. |

### Per-operation costs

| Operation | Wall clock | Plane |
|---|---|---|
| `.dt` cache parse, one record | 0.2 ms | Cache |
| `findRecord` scoped to one database | 0.33 ms | Cache |
| `findRecord` cross-database scan (9 DBs) | 1.57 ms | Cache |
| `mdfind` content-predicate query (any corpus size) | 50–65 ms | mdfind |
| `MetadataCache.highestSequence` (mint-id scan) | 55 ms | mdfind |
| SB `record.uuid` / `name` / `location` | 0.4–0.8 ms | SB |
| SB `getRecord(uuid:in:)` | 1.1 ms | SB |
| SB `databases()` | 1.8 ms | SB |
| `addCustomMetaData` per key (in-process) | 1.2 ms | SB |
| `addCustomMetaData("")` clear per key (in-process) | 1.1 ms | SB |
| `setTags` (one Apple Event, any-N tags) | 15 ms | SB |
| `setName` | 13 ms | SB |
| `moveRecord` | 3 ms | SB |

### End-to-end cycle times (full process spawn)

These are wall-clock times for `pkim <verb> …` invocations including process startup. Useful for estimating how long a skill workflow will take.

| Verb (cold) | Wall clock | Notes |
|---|---|---|
| `pkim mint-id --type kn` | ~85 ms | startup + mdfind scan |
| `pkim get <uuid>` | ~70 ms | startup + cache read |
| `pkim get <pkim-id>` | ~85 ms | + mdfind to resolve PKIM_ID → UUID |
| `pkim tags <ref>` | ~180 ms | startup + SB connect + property read |
| `pkim body <ref>` (imported) | ~180 ms | startup + SB connect + plainText read |
| `pkim set-metadata <ref> K=V` | ~230 ms | startup + SB connect + write + verify |
| `pkim list <db> --group / --limit 5` | ~200 ms | startup + SB connect + children() |
| `pkim search <db> --field K=V` | ~110 ms | startup + mdfind + cache-row decode |
| `pkim extract-text <pdf>` | ~80 ms + size-dependent | PDFKit |
| `pkim probe-capabilities` | ~70 ms | startup + SB connect + databases() |

### Skill-workflow estimates

A few sample scenarios so future skill authors can budget realistically:

- **Sweep 500 records, set one metadata field each**: 500 × 230 ms ≈ **115 s** wall-clock. The startup + SB-init cost dominates; if this becomes a real hotspot, the future `pkim batch < commands.jsonl` verb would collapse it to one process doing 500 atomic writes ≈ **15 s**.
- **Audit walk of one PKIM-Knowledge database (117 records)**: 117 × 70 ms ≈ **8 s** via `pkim list` + `pkim get` per record. Or one bulk-parse via the cache parser directly ≈ **27 ms** if a future hot-path needs it.
- **Create 10 notes**: 10 × ~400 ms (create-note is heavier than set-metadata because it does the createRecordWith + addCustomMetaData stamp) ≈ **4 s**.

These targets are loose. The cache plane and the SB plane have very different characteristics — a workflow that's cache-dominated is much cheaper than one that touches SB per record.

## Read-plane architecture

Three planes, each with a different freshness/latency trade-off. Verbs pick whichever plane fits their contract.

### 1. `.dt` Spotlight cache

Path: `~/Library/Metadata/com.devon-technologies.think/<DB-UUID>/<bucket-2-hex>/<record-UUID>.dt`.

Format (reverse-engineered on this branch — confirmed by 119k-file scan on the dev machine):

```
For each field:
  4 bytes   magic: "DTst" (text/binary) | "DTda" (8-byte CFAbsoluteTime date)
  4 bytes   tag (ASCII, e.g. "NAME", "UUID", "_key", "UTI ")
  for DTst: 4 bytes big-endian length + 4 reserved + payload
  for DTda: 8 bytes payload (no length, no reserved)
```

Standard tags: `DBID`, `NAME`, `PATH`, `TITL`, `ALIA`, `UUID`, `KIND`, `TEXT`, `FILE`, `UTI `, `MTDT`. Custom metadata as paired `_key` / `_val` fields — an orphan `_key` (followed by another `_key` or end-of-fields) records an empty value, matching DT's actual shape.

**Sub-millisecond per record.** Mmap-able, no DT round-trip required. Used by: `get`, `resolve` (PKIM_ID resolution), `file-path`, `mirror-of`, search-result row decoration.

**Lags writes by tens of seconds** — DT's Spotlight importer batches updates. Verbs that must see same-session writes use the SB plane instead.

### 2. `mdfind` (Spotlight index)

For content-predicate queries (next-sequence scan, `search --field K=V`, `search --text Q`), shell out to `/usr/bin/mdfind`. DT's mdimporter exposes custom metadata as `com_DEVONtechnologies_think_md<key>` attributes plus database name as `com_DEVONtechnologies_think_DatabaseName`.

**~50 ms wall-clock** for any query, independent of corpus size. The honest path: v1 of `mint-id` walked every `.dt` file (~25 s for 119k records); switching to mdfind on the indexed `mdpkim_id` attribute dropped it to 55 ms. Same speedup applies to any content predicate. Documented as a finding because future contributors will be tempted to re-derive this.

### 3. ScriptingBridge (SB)

The typed Swift protocols generated by [SwiftScripting](https://github.com/tingraldi/SwiftScripting) from DT's `.sdef` (regenerate via `pkim-binary/scripts/regen-dt-bridge.sh`). One Apple Event per property read or write.

**Always fresh** — reflects DT's current state with no indexing lag. Cost: ~30 ms `DTBridge.connect` (paid once per process) + ~1 ms per Apple Event. Used by every write verb and by `tags` / `aliases` / `body` / `list` reads where same-session-write freshness matters.

Some properties (`uuid`, `location`, `referenceURL`, `customMetaData`) come back as lazy `SBObject` specifiers — the typed accessor returns `Any` and the caller must invoke `.get()` on the result to force resolution. The bridge helpers (`DTRecordAccess.uuid`, `DTCustomMetadata.read`) handle this transparently.

## Write-plane architecture

Per-key atomic writes via DT's application-level verbs, NOT whole-dict replace of `customMetaData`. The path:

1. Resolve `<ref>` to a live `DEVONthinkRecord` via `resolveLiveRecord(_:bridge:)`.
2. (Dry-run only) read the current values of just the touched fields, for the diff.
3. Write each delta as one Apple Event:
   - `set-metadata` → `app.addCustomMetaData(value, for: key, to: record, as: nil)` per key; empty value clears the key.
   - `set-tags` (full replace) → `record.setTags(array)`. With `--add`/`--remove`, one pre-read + one setTags.
   - `set-name` → `record.setName(string)`.
   - `set-body` → indexed: write the disk file. Imported: `record.setPlainText(body)`.
   - `move` → `app.moveRecord(record, from: nil, to: target)` (move-all-instances).
   - `create-note` → `app.createRecordWith(props, in: parent)`, then `addCustomMetaData` to stamp `mdpkim_id`.
   - `create-group` → `app.createLocation(path, in: db)`.
4. Verify-read (live runs only) — re-read the touched fields. DT silently no-ops on incompatible record classes and `addCustomMetaData`'s Bool return lies (always false); the post-read is the only honest source of truth.
5. Emit `mutation.json` with the verify-read result.

**Why per-key, not whole-dict:**

The earlier whole-dict approach (`setCustomMetaData:`) had to read the whole dict first to preserve untouched keys. That read introduced a type-preservation hazard: NSDate-typed values like `mdlastprofiledat` round-tripped through string formatting drifted by hours-to-days. The per-key atomic path can't corrupt other keys because it never touches them. Type drift is structurally impossible.

**Why no pre-read on live:**

On `--dry-run` we read before, project the after, emit the diff — that's the verb's purpose. On a live write the pre-read was decorative — it filled the `before` slot in `mutation.json` at the cost of one Apple Event per key. The verify-read after gives the authoritative state; the manifest's `before` is `null` on live and callers who want a diff run `--dry-run` first.

Single Apple Event per delta. No long-running session, no caching across invocations. Each invocation's bridge handle is constructed in `main`, used, and torn down.

## Run manifests

Every invocation writes `runs/<run-id>/` with:

```
runs/<run-id>/
├── invocation.json          # verb, argv, env (filtered), start/end timestamps, exit code
├── mutation.json            # writes only; before/after for each affected field
├── mutation-proposal.json   # dry-runs only; same shape as mutation.json minus "applied"
└── stdout.json              # exact bytes the binary printed
```

`<run-id>` format: `<rfc3339-timestamp>-<6-hex>` (e.g. `2026-05-20T18-32-04Z-3f7b1c`). Sortable by name.

The `runs/` directory is git-ignored (already configured for the Python runtime).

## Write-gate enforcement

A live write requires both:

1. `PKIM_ALLOW_PRODUCTION_WRITES=true` in the environment.
2. A passing `probe-capabilities` result, cached for 60 s in-process to amortise the cost across a live invocation that contains internal sub-steps. The cache lives only for the lifetime of the process and is not persisted to disk.

`--dry-run` short-circuits both — it never reaches DEVONthink, so it neither needs nor checks the gate.

If a binary instance reaches a write call without these conditions met, it fails fast with exit code `3` before any DT interaction. The dry-run path is unaffected.

## Domain types

Ported from `src/pkim/domain/`. Swift struct definitions live in `Sources/pkim/Domain/`. Frozen-by-default (`struct`, not `class`); `Codable` so JSON envelopes are derived from the type, not hand-rolled.

- `PKIMId` — `class: PKIMClass` enum (`kn`, `rl`, `ev`, `cl`), `date: String`, `sequence: Int`.
- `RecordHandle` — fields mirrored from doc 22 retirement table.
- `DocRole`, `ReviewState` — enums matching doc 00 §`DocRole` / §`Review_State` vocabularies (closed sets).
- `RelationType` — enum matching doc 00 §`Relation_Type` vocabulary.
- `Classification` — enum (`property`, `indexPointer`, `derived`).
- `WikiLink`, `Claim`, `MultiMarkdownHeader` — direct ports.

The Swift JSON output for these is the snake_case form, derived via `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`. Verbs that wrap them in `data: { … }` get this for free.

## Test approach

`Tests/pkimTests/` under [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`, `@Test`, `#expect`). 70 tests / 15 suites at the time of writing.

Three layers, identified by `@Suite` name suffix:

- **Pure unit** — `Domain/`, `JSON/`, the `.dt` TLV parser, the byte-level sequence scanner. No DT, no filesystem, no Spotlight. Run anywhere.
- **Live cache** — exercises the cache parser against the user's actual `~/Library/Metadata/com.devon-technologies.think/`. Gated by `PKIM_BRIDGE_LIVE=1`. Reads only; no mutations.
- **Live SB + bench** — `DTBridgeBench`, `SetMetadataBench`. Connects to a running DT and runs read/write round-trips against the PKIM-Pilot scratch database. Gated by `PKIM_BRIDGE_LIVE=1`. Restores pristine state after each test where practical (set-tags is set-semantic and silently dedupes; perfect restoration of duplicate tags is not always possible).

Bench tests print summary lines (`mean=X p95=Y max=Z`) via `print` rather than `Issue.record` — `Issue.record` is flagged as a test failure by Swift Testing, so we use print and trust the test framework's stdout capture.

Run shapes:
- `swift test` — unit + live cache + live SB if env-var is set; skips the live suites otherwise.
- `PKIM_BRIDGE_LIVE=1 swift test` — runs everything.
- `swift test --filter SetMetadataBench` — narrow to one suite when iterating on perf.

Coverage target: 80% over the binary's own code (excluding `Bridge/Generated/`, which is mechanically generated by the sdp pipeline and re-validated by the regen script's live tests).

## Xcode setup walkthrough (for the implementation workstream)

Run on a clean checkout of `pivot/cli-first` (or a successor branch). The user will execute these steps; the agent then works inside the resulting workspace.

### 1. Create the SwiftPM package

```bash
cd /path/to/your/checkout
mkdir pkim-binary && cd pkim-binary
swift package init --type executable --name pkim
```

This generates `Package.swift`, `Sources/pkim/main.swift`, and `Tests/pkimTests/`.

### 2. Add ArgumentParser

Edit `Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "pkim",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "pkim", targets: ["pkim"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "pkim",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "pkimTests", dependencies: ["pkim"]),
    ]
)
```

### 3. Open in Xcode

```bash
open Package.swift
```

This opens the package as a workspace. Xcode resolves dependencies and indexes the source on first launch. The executable target appears as a runnable scheme.

### 4. Verify the toolchain

In Xcode:

- Confirm the toolchain is **Swift 5.10** or later (Xcode 15.3+).
- Confirm the deployment target is **macOS 13+** (Ventura). `ScriptingBridge`, PDFKit, and `mdfind` are all older than that; the floor is set by `swift-argument-parser` and Swift 6 strict concurrency.
- Build the empty executable scheme (⌘B). Confirm it produces `pkim` under `.build/`.

### 5. Wire up the Xcode MCP bridge

Xcode 26+ ships an MCP bridge at `xcrun mcpbridge`. Register it as a project-scope MCP server so Claude Code can drive the open Xcode window — read/write files, build, run tests, fetch build logs, render SwiftUI previews, search documentation:

```bash
claude mcp add --scope project --transport stdio xcode -- xcrun mcpbridge
```

This writes `.mcp.json` at the repo root (project scope, committed). Claude Code prompts to approve the server on next session start.

No "External Build System" target or other Xcode wiring is needed. A SwiftPM package opened via `open Package.swift` is already its own build system — Xcode runs `swift build` under the hood; ⌘B and ⌘U work natively. The MCP bridge gives agents programmatic access to that same machinery from outside the GUI.

### 6. Hand the workspace back

Once the package builds and tests run, signal "ready" and I'll start implementing verbs against this doc — beginning with `Domain/` (port of `legacy/src/pkim/domain/`) and the JSON envelope module, then the `.dt` cache parser, then verbs in priority order from the table in §Verb surface.

### Repo-side prep before Xcode opens

The implementation workstream runs on a successor branch (`feat/swift-pkim`), not `pivot/cli-first`. Before opening Xcode:

```bash
git checkout main
git merge --no-ff pivot/cli-first      # land the pivot's design + quarantine
git checkout -b feat/swift-pkim
```

The pivot branch is then preserved as a historical record of the decision. Doc 22, doc 23, and the retirement map travel with it onto main.

## Lessons learned (institutional memory)

Findings from the build that future contributors will save time on by reading first. Each is in a commit message somewhere; this is the consolidated index.

### 1. PyObjC ScriptingBridge introspection is the real cost, not Apple Events

The pivot started under the hypothesis that Apple Events were the bottleneck in the old Python runtime. Profiling the Swift baseline showed the actual cost split: ~30 ms process startup (dyld + code-signing), ~30 ms `SBApplication.init` (dynamic glue construction from the sdef), then sub-ms per Apple Event. The Python PyObjC version paid all three plus per-property bridge-crossing tax on every property access (millions of crossings during corpus walks). Static-glue Swift via SwiftScripting eliminates the per-property tax structurally; the sdef parse becomes a ~10 ms one-time cost.

If a future contributor wants to bring DT scripting access into a different language, this is the architectural choice that mattered most.

### 2. `@objc optional protocol` in Swift doesn't dispatch through SB

First pass at the bridge declared DT's interfaces as `@objc optional protocol` and cast `SBApplication` to them. The casts succeeded but the calls didn't reach SB's message forwarder — every `databases()` returned `nil`, every property read returned empty. Caught only because the bench reported `databases() [n=0]` while DT was clearly running.

Two viable paths: KVC + `performSelector` directly (works but loses type safety, and some properties — `type`, `uuid` — aren't KVC-compliant or return lazy `SBObject` specifiers), or generated headers via the sdp pipeline (compiles to real method dispatch through SB). We landed on the second; the first is in commit history as the v1 implementation.

### 3. `mdfind` is the answer for content-predicate queries

`mint-id`'s first implementation walked every `.dt` file in every database to find the highest sequence number for a given class/date. Correct, ~25 s on the dev machine's 119k-file cache. Switching to a single `mdfind 'com_DEVONtechnologies_think_mdpkim_id == "<CLASS>-<DATE>-*"'` dropped it to ~55 ms — Spotlight already indexes DT's custom metadata as `com_DEVONtechnologies_think_md<key>` attributes. Same speedup applies to `search` and any content-predicate read.

Future contributor: when reaching for "scan every record for a field value", reach for `mdfind` first.

### 4. `addCustomMetaData` is the right write path, not `setCustomMetaData`

The legacy memory entry warned that `setValue:forKey:` raised `NSUnknownKeyException` for keys not registered in DT's schema. Following that advice we used `setCustomMetaData:` (whole-dict replace). That works but forces a read-before-write to preserve untouched keys — and the read+write+verify cycle round-trips other keys' NSDate values through string formatting, drifting them by hours-to-days.

DT's application-level `addCustomMetaData(value, for:, to:, as:)` is a different surface: it sets one key without touching others, auto-registers unknown keys (probed live and confirmed), and accepts `""` to clear. Two practical caveats: it coerces non-string values to strings (probe wrote `NSNumber(42)` → received `"42"`), and its `Bool` return is unreliable (always false even on successful writes — so always verify-read).

### 5. DT's silent no-op on writes makes verify-reads non-negotiable

DT silently ignores `addCustomMetaData` / `setPlainText` / similar setters on record classes that don't accept them. No exception, no false return. The only honest signal is to re-read the field after the write. Every write verb in the binary does this; the cost is one Apple Event per touched field, but the alternative is a CLI that lies about whether it persisted.

### 6. The Spotlight surface lags writes by tens of seconds

Reading via `mdls` or via the `.dt` cache parser after a write-through-SB returned stale data for ~tens of seconds — DT's Spotlight importer batches updates. Originally affected `pkim tags` and `pkim aliases` (both read via cache initially) and `pkim body` (read the cache's `TEXT` field). All three switched to live SB reads.

Generalised rule: any verb whose answer must round-trip with same-session writes uses the SB plane (`resolveLiveRecord`). Verbs where staleness is acceptable use the cache plane (`resolveRecord`). Doc-23 §Read-plane names both.

### 7. `sbhc.py` corner cases

The SwiftScripting generator handled DT's 5709-line sdef in one shot with three observed corner cases:

- `record.type` is a Swift keyword; sbhc.py renamed it to `recordType` with `DEVONthinkDataType` enum result. Works.
- `record.uuid` and a handful of other text-typed properties come back as lazy `SBObject` specifiers rather than `String`. The `.get()` resolution dance is needed; see `resolvedString` in `DTBridge.swift`.
- `app.search` (the scripting verb) has its direct-parameter (the query string) dropped from the generated signature. We avoid the issue by going through `mdfind` instead — different code path, doesn't matter.

Run `pkim-binary/scripts/regen-dt-bridge.sh` to refresh after DT updates its scripting dictionary. The three corner cases are documented in the script's comments.

### 8. CLI defaults should match user expectations, not paranoia

The original write verbs defaulted to dry-run with `--live` opt-in. Real CLI ergonomics is the opposite: tools do what they say. Safety stays via `PKIM_ALLOW_PRODUCTION_WRITES=true` — must be in the environment for any write. `--dry-run` becomes the explicit opt-in tester.

### 9. Pre-reads on live writes are wasted Apple Events

The first set-metadata implementation read each touched key's current value to fill the `before` slot in the run manifest. Decorative; cost = one Apple Event per key. On a live run we have the verify-read after; the `before` slot is `null` on live (populated on dry-run) and callers who want a diff run `--dry-run` first.

### 10. is_group detection on root-level DT groups needs a fallback

DT's Inbox / Tags / All-PDF-Documents smart group views return `recordType` values outside the `DEVONthinkDataType` enum. `pkim list` uses a two-signal heuristic: `recordType ∈ {group, smartGroup}` OR `children().count > 0`. Catches the populated cases; empty special groups (Trash with no contents) still report `is_group: false`. Acceptable; documented.

## Out of scope for this doc

- The Swift implementation itself (verb by verb code).
- Per-verb performance budgets (added once measurable).
- The MCP shim's exact code (a separate decision: build only if a host demands MCP integration).
- Skill body rewrites (separate workstream against the new binary).

## Anti-patterns this doc forbids

- Adding a "doIt" mega-verb that takes a JSON workflow. The CLI surface is atomic; orchestration is a skill responsibility.
- Embedding policy in the binary (filing rules, review-state transitions, supersession sequencing). Policy lives in skills.
- Holding state in memory across invocations. Each process is born and dies.
- Reintroducing Python anywhere on the runtime hot path. The mirror module (KEEP-TRANSITIONAL in doc 22) is the only Python that survives, and it consumes `pkim` CLI output rather than calling DT.
- Letting `ScriptingBridge` calls leak outside `Sources/pkim/Bridge/`. The cache parser, mdfind subprocess wrapper, and verb implementations must not import `ScriptingBridge` directly; they go through `DTBridge` and friends.
