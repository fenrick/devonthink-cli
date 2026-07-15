# Workflows

## Purpose

The repeatable flows that move records through PKIM. Each workflow is a shape — a sequence of states and decisions — that a human or a skill executes. The skill catalogue in `skills/README.md` names the concrete tools; this document says what the flow *is*, so the shape survives even as the tool surface changes.

## Workflow set

1. **Ingest and profile** — new evidence → known record with baseline identity.
2. **Enrich reviewed evidence** — profiled record → tagged, metadata-stamped, filed.
3. **Evidence to knowledge** — approved evidence → knowledge note (optionally with claim ledger + relation notes).
4. **Relation maintenance** — surface + author RL records for meaningful edges.
5. **Portable mirror** — the on-disk indexed root of `PKIM-Knowledge` *is* the mirror; no separate workflow. Skills write via DT MCP; DEVONthink keeps the disk file coherent.
6. **Graph-health audit** — periodic corpus-wide check for broken endpoints, zombies, contradictions, orphans.
7. **Periodic claim audit** — stress-test published synthesis at a regular cadence.

The intake skill runs Workflows 1 + 2 (and touches 3 + 4 opportunistically). The audit skill runs Workflows 6 + 7. There is no separate skill for mirror refresh because there is no separate mirror.

## Workflow 1 — Ingest and profile

**Purpose.** Turn a new evidence object into a known record with identity, baseline metadata, and a preliminary read while it's still in `/Inbox`.

**Triggers.** New imported evidence; newly captured web archive / bookmark / scan; a manually captured record that has never been profiled.

**Steps.**

1. Confirm runtime health (DT running, target database open, custom metadata schema present).
2. Read the record's properties, content, and any existing tags.
3. Mint `PKIM_ID` if absent (`EV-YYYYMMDD-NNNN`).
4. Classify: almost always EV. If it looks like a KN/RL/CL in the inbox, something has come in wrong — surface as `needs-human`.
5. Produce a read-only record-context packet: proposed topic tags, likely filing destination, candidate KN directions if any.
6. Set the review outcome (`profiled` or `needs-human`) outside the profiling step itself — profiling is read-only.

**Exit condition.** The record is known enough to enter enrichment. Profiling alone does not imply final filing.

## Workflow 2 — Enrich reviewed evidence

**Purpose.** Turn a profiled record into a curated, tagged, filed evidence record before it leaves `/Inbox`.

**Triggers.** A profiled evidence record is low-risk enough to continue. The operator wants a single-pass outcome.

**Steps.**

1. Review the profile packet while the record is still in `/Inbox`.
2. Derive a better human title if the ingest title is weak.
3. Apply structural + topical tags per the tag axes discipline.
4. Write approved custom metadata (`docrole`, `evidencestatus`, `capturetype`, `origin_uri`, `primarytopic`, `review_state=approved`).
5. Update the `Aliases` field to include `PKIM_ID`.
6. Decide whether a KN authoring pass should happen now (see Workflow 3) or later.
7. Move the record to its filing destination via `move_record`.
8. Set `review_state` to `filed`.

**Exit condition.** Either the record is `filed` in its long-term location with metadata + tags settled, OR it's flagged `needs-human` with a clear reason.

**The two operate together.** In practice `dt-intake` runs Workflows 1 + 2 in one per-record subagent pass.

## Workflow 3 — Evidence to knowledge

**Purpose.** Create or update a native knowledge note from approved evidence.

**Triggers.** A profiled evidence record is worth interpreting; a topic or project note needs new source-backed content.

### Candidate triage checkpoint

Before creating a KN, review the concept set for graph bloat. Only candidates with **all** of the following proceed automatically:

- `candidate_class = canonical-note-candidate`
- `note_worthiness = high`
- `distinctness = distinct`
- `graph_value = node`

Candidates classified `medium`, `overlapping`, `embedded`, `edge-support`, `local-detail`, `supporting-detail`, or `evidence-for-other-note` are recorded in the candidate ledger and deferred unless the operator explicitly elevates them. Deferred candidates are not silently dropped — they must appear with a triage outcome of `deferred`.

### Steps

1. Confirm the source evidence is profiled.
2. Apply the candidate triage checkpoint. Only accepted candidates proceed.
3. Select the note type (`literature` / `synthesis` / `topic` / `project`) for each accepted candidate.
4. **Pass 3 — Triangulate.** Build a claim ledger from the EV shortlist: identify candidate claims (fact / inference / assumption / open-question), classify their confidence, cite their evidence. The operator reviews the ledger before continuing.
5. Create or update the native KN in dependency order. Write the accepted claim entries into the KN's `## Claims` section (either inline as the fenced YAML block, or promote to CL records when a claim needs individual addressability).
6. Attach evidence back-references: `## Evidence links` with item links to the cited EVs.
7. Refresh aliases and note metadata.
8. If the new KN cites another KN or CL, author an RL — Workflow 4.

**Exit condition.** The KN exists in `PKIM-Knowledge`, is linked back to source evidence, and carries at least one structured claim when `KnowledgeStatus ∈ {reviewed, published}`.

### Merge vs create

Before authoring a fresh KN, check for a canonical KN on the same topic. Three shapes of check, cheapest first:

- By URL / `origin_uri` — `lookup_records` for a KN that already references this source.
- By topic — `search_records` for `mddocrole:knowledge mdprimarytopic:<topic>`.
- By similarity — DEVONthink's `find_similar_records` against the source EV.

If a canonical KN exists:
- The EV adds to it → update the canonical KN (append claims, add evidence link, RL). Don't create a duplicate KN.
- The EV contradicts it → author a new KN or CL with the counter-argument, author an RL of `Relation_Type=contradicts`, surface as `needs-human`.
- The EV supersedes it → author an RL of `Relation_Type=supersedes`, surface as `needs-human` for triage of the old KN's status.

## Workflow 4 — Relation maintenance

**Purpose.** Make meaningful edges explicit as first-class RL records.

**Triggers.** A KN cites another record in a load-bearing way (supports, contradicts, extends, supersedes, etc.); two records need a maintained relationship; graph audit surfaces a missing relation.

**Steps.**

1. Confirm both endpoints exist and are the intended pair.
2. Check for a duplicate RL — same `Source_Item`, `Target_Item`, `Relation_Type` triplet.
3. Mint `RL-YYYYMMDD-NNNN`.
4. Compose the RL body: mandatory `# Why this relation exists` prose rationale; `## Endpoints` with two WikiLinks matching the item links; `## Evidence` when `Relation_Type ∈ {supports, contradicts, supersedes}`.
5. Set metadata: `Source_Item`, `Target_Item`, `Relation_Type`, `relationstatus`, `relationconfidence`.
6. Apply structural + topical tags (topical set inherits from both endpoints).
7. File to `/Notes/Relations`.

**Exit condition.** The RL exists, both endpoints resolve, the body has the mandatory rationale, and it appears in DEVONthink's graph traversal (See Also on the endpoints).

### When NOT to author an RL

- Every WikiLink in a KN body — WikiLinks are for readable prose; RLs are for the graph.
- Every citation of an EV in `## Evidence links` — that's evidence linkage, not a semantic edge unless it's load-bearing.
- A KN mentioning a related concept in passing — mention, not edge.

## Workflow 5 — Portable mirror

**Not a workflow.** `PKIM-Knowledge` is indexed against an iCloud-synced on-disk root. Every KN, RL, CL is already a `.md` file on disk with YAML frontmatter equivalent to its MMD header. External tooling reads from there.

Skills write via DT MCP; DEVONthink keeps the on-disk file coherent with the database record. There is no separate "mirror" workflow to run.

Consequences:

- Portability is passive. Files on disk are always current with the database.
- Filename convention: `<CLASS>-YYYYMMDD-NNNN-<slug>.md`.
- The database and the disk root move together — moving one without the other breaks the index.
- Cloud-sync latency applies. A KN written from device A may take seconds to appear on device B; skills that read across devices should tolerate this.

If disk-side drift is ever detected (a file edited outside DEVONthink), the `Mirror Drift` smart group surfaces it. DEVONthink's `Update Indexed Items` reconciles.

## Workflow 6 — Graph-health audit

**Purpose.** Confirm the corpus's graph is still coherent. Detect broken endpoints, dangling references, retired-evidence citations, contradictions, orphans.

**Triggers.** Weekly cadence; before scaling ingest; after a wave of EV retirements or supersessions; when a smart group produces suspicious results.

**Steps.** Walk the six finding classes:

1. **Broken RL endpoints** — every RL's `Source_Item` / `Target_Item` resolves.
2. **Zombie claims** — every KN's `## Claims` and every CL's `## Evidence` cites at least one non-retired EV.
3. **Corpus contradictions** — two records asserting opposing conclusions on the same evidence.
4. **Dangling WikiLinks** — `[[...]]` in KN/CL bodies that don't resolve inside the database.
5. **Orphan records** — CLs without a resolvable parent KN; literature/synthesis KNs with no evidence; RLs with malformed endpoints.
6. **Discipline violations** — untagged records; missing required metadata; RLs without prose rationale; published KNs without a `## Claims` block.

**Severity.** Broken endpoints, zombies, and contradictions are high. Dangling WikiLinks and orphans are medium. Discipline violations are low.

**Outputs.** A findings list ranked by severity. Auto-fix only two subsets: (a) dangling WikiLinks that unambiguously map to a cross-DB item link, (b) untagged CLs / RLs whose topical set is inheritable from their parent / endpoints. Everything else routes to human triage.

**Exit condition.** All six classes have been walked to their natural end. A partial audit that says "clean" is worse than no audit — always state scope explicitly.

## Workflow 7 — Periodic claim audit

**Purpose.** Stress-test published synthesis. Surface zombie claims, missing evidence, weak confidence, and unresolved contradictions before they accumulate.

**Triggers.** Monthly cadence; after a large EV supersession event; on demand before a publish wave.

**Steps.**

1. Run the discipline audit (Workflow 6) to get the structural report.
2. Walk the corpus for corpus-level contradictions.
3. For each KN in scope (default: `KnowledgeStatus ∈ {reviewed, published}`), audit its `## Claims` block: verify every `fact` / `inference` claim's evidence resolves and is non-retired.
4. Classify defects by severity. Route:
   - `missing-claims` / `missing-evidence-link` → re-build the claim ledger.
   - `corpus-contradiction` → human triage; both records may flip to `needs-human`.
   - `dangling-wikilink` → resolve to correct target or item link.
   - `zombie-claim` → review whether the claim still holds; possibly demote confidence or retire.

**Outputs.** A ranked findings list per KN. The audit doesn't apply fixes for the claim-specific findings — every one needs operator judgement.

**Exit condition.** Every published KN either passed the audit or has a triage decision recorded.

## Workflow composition rules

- Profiling before enrichment.
- Enrichment before filing.
- Knowledge capture requires profiled evidence.
- A graph pass runs before calling a note batch operationally complete.
- Relation maintenance depends on stable source and target records.
- The audit runs against the whole corpus, not against subsets — partial audits mislead.

## Anti-patterns

- Filing unprofiled or semantically undeveloped items.
- Treating `approved` as a synonym for "move it now" — approval means "ready for the next bounded step".
- Building custom queues when DEVONthink smart groups would work.
- Sequencing an ad-hoc series of DT MCP calls that overlap a named workflow — invoke the workflow instead.
- Declaring an audit "clean" on a partial walk.
