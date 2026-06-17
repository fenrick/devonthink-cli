import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim set-tags <ref> --tag T [--tag T]…` — set the macOS Finder
/// tags on one DEVONthink record.
///
/// Semantics:
///   - Each `--tag T` adds (or keeps) one tag in the final set.
///   - The verb is **set-semantic**: the resulting tag list is exactly
///     what was supplied, with DT-side deduplication. To remove a tag,
///     omit it from the call.
///   - `--add T` / `--remove T` flags layer on top of the current
///     tag set so a caller can do incremental edits without supplying
///     the whole list.
///   - `--dry-run` (default) emits a proposal envelope without
///     touching DT; the default (write) writes through `setTags:`.
///
/// Backing AppleScript verb: `record.setTags:` — one Apple Event
/// regardless of how many tags the caller supplied. Type preservation
/// hazard doesn't apply (tags are not custom metadata).
struct SetTags: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-tags",
        abstract: "Set the macOS Finder tags on one DEVONthink record.",
        discussion: """
            DEVONthink dedupes the supplied tag list. Tags inherited via
            the Tags hierarchy are reflected back at read time but the
            authoritative direct tag set is what the caller supplies
            here.
            """
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    @Option(name: .long, help: "Replace the tag set with these tags (repeatable).")
    var tag: [String] = []

    @Option(name: .long, help: "Add this tag to the current set (repeatable).")
    var add: [String] = []

    @Option(name: .long, help: "Remove this tag from the current set (repeatable).")
    var remove: [String] = []

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "set-tags") { runId in
            try WriteGate.require(dryRun: dryRun)
            guard !tag.isEmpty || !add.isEmpty || !remove.isEmpty else {
                throw PkimError.invalidInput("at least one of --tag, --add, --remove is required")
            }

            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)

            // The diff (added/removed) and the post-tag list are
            // different things:
            //   - dry-run needs the diff (the whole point of dry-run).
            //   - live needs the post-tag list (to verify what DT
            //     persisted; setTags is set-semantic and may dedup).
            // When --add or --remove is used, we still need a pre-read
            // even on a live run, because the final tag list is `before`
            // mutated by the deltas — there's no way to apply
            // "remove tag T" without knowing the current set. When
            // --tag is used alone (full replace), no pre-read is
            // needed for the write itself.
            let needsPreRead = !add.isEmpty || !remove.isEmpty || dryRun
            let before: [String] = needsPreRead ? Self.readTags(record) : []
            let after = Self.computeAfter(before: before, replace: tag, add: add, remove: remove)
            let changes: [TagChange]
            if !dryRun, !needsPreRead {
                // Full-replace live: changes recorded against an
                // unknown before; we just list the new set as "set".
                changes = after.map { TagChange(tag: $0, change: "set") }
            } else {
                changes = Self.diff(before: before, after: after)
            }

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<TagChange>(
                    runId: runId,
                    verb: "set-tags",
                    ref: ref,
                    dtUuid: DTRecordAccess.uuid(record),
                    applied: !dryRun,
                    changes: changes
                ),
                applied: !dryRun
            )

            var actually: [String]?
            if !dryRun {
                record.setTags?(after as NSArray)
                // Verify what DT actually stored (it dedupes the input
                // and may drop unrecognised tags).
                actually = Self.readTags(record)
            }

            return SetTagsPayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                changes: changes,
                tags: actually ?? after,
                runDir: manifest.runDir.path
            )
        }
    }

    /// Force-resolve the lazy SBObject the `tags` accessor returns.
    static func readTags(_ record: DEVONthinkRecord) -> [String] {
        DTRecordAccess.tags(record)
    }

    static func computeAfter(
        before: [String],
        replace: [String],
        add: [String],
        remove: [String]
    ) -> [String] {
        // --tag replaces the set wholesale; --add and --remove layer
        // on top of either the replacement set OR the current set.
        var working = replace.isEmpty ? before : replace
        let removeSet = Set(remove)
        working.removeAll { removeSet.contains($0) }
        for t in add where !working.contains(t) {
            working.append(t)
        }
        return working
    }

    static func diff(before: [String], after: [String]) -> [TagChange] {
        let beforeSet = Set(before)
        let afterSet = Set(after)
        var changes: [TagChange] = []
        for t in afterSet.subtracting(beforeSet).sorted() {
            changes.append(TagChange(tag: t, change: "added"))
        }
        for t in beforeSet.subtracting(afterSet).sorted() {
            changes.append(TagChange(tag: t, change: "removed"))
        }
        return changes
    }
}

struct TagChange: Encodable, Sendable, Equatable {
    let tag: String
    let change: String  // "added" | "removed"
}

struct SetTagsPayload: Encodable, Sendable {
    let ref: String
    let dtUuid: String
    let applied: Bool
    let kind: String
    let changes: [TagChange]
    let tags: [String]
    let runDir: String
}
