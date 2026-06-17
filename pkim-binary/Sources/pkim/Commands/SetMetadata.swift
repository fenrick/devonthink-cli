import ArgumentParser
import Foundation

/// `pkim set-metadata <ref> K=V…` — set or clear custom-metadata
/// fields on one DEVONthink record.
///
/// Semantics:
///   - Each `K=V` argument writes that value to key `K` via
///     `addCustomMetaData` — one Apple Event per delta. Other keys on
///     the record are never read or touched, so date-typed values can't
///     drift via lossy string round-trips.
///   - `K=` (empty value) clears the key.
///   - `--dry-run` previews; default is to write.
///   - Writing requires `PKIM_ALLOW_PRODUCTION_WRITES=true`; without
///     it, exits with `DEVONthinkUnreachable` and never reaches DT.
///   - On dry-run, the verb reads the current value of each touched
///     key for the diff. On a live run the pre-read is skipped — DT's
///     verify-read after the write gives the authoritative post-state.
///
/// After a live write, the verb re-reads the touched keys and reports
/// the persisted values. DT silently no-ops custom-metadata writes
/// against record classes that don't accept them, so the post-read is
/// the only honest source of truth.
struct SetMetadata: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-metadata",
        abstract: "Set or clear custom-metadata fields on one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    @Argument(help: "One or more KEY=VALUE pairs. Empty VALUE clears the key.")
    var assignments: [String] = []

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "set-metadata") { runId in
            try WriteGate.require(dryRun: dryRun)
            let updates = try Self.parseAssignments(assignments)
            guard !updates.isEmpty else {
                throw PkimError.invalidInput("at least one KEY=VALUE pair is required")
            }

            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)

            // Read-before only on dry-run (so we can show before/after
            // diffs without touching DT). On live we skip the read
            // entirely — the work would just decorate the manifest at
            // the cost of one Apple Event per key.
            let changes: [MetadataFieldChange]
            if !dryRun {
                changes = Self.projectedChanges(updates: updates)
            } else {
                var before: [String: String?] = [:]
                for (key, _) in updates {
                    before[key] = DTCustomMetadata.read(record, key: key, bridge: bridge)
                }
                changes = Self.diff(before: before, updates: updates)
            }

            let manifest = try RunManifest.create(runId: runId)
            let artefact = MutationArtefact<MetadataFieldChange>(
                runId: runId,
                verb: "set-metadata",
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                applied: !dryRun,
                changes: changes
            )
            try manifest.writeMutation(artefact, applied: !dryRun)

            // Apply each delta atomically. addCustomMetaData("") clears
            // a key; any other value sets or updates it. One Apple Event
            // per delta.
            var actuallyApplied: [String: String?]?
            if !dryRun {
                for (key, value) in updates {
                    DTCustomMetadata.write(record, key: key, value: value, bridge: bridge)
                }
                // Verify-read is non-negotiable: DT silently no-ops the
                // setter on record classes that don't accept custom
                // metadata, and `addCustomMetaData`'s Bool return lies
                // (always false). The post-read is the only honest
                // source of truth for whether the write took effect.
                var after: [String: String?] = [:]
                for (key, _) in updates {
                    after[key] = DTCustomMetadata.read(record, key: key, bridge: bridge)
                }
                actuallyApplied = after
            }

            return SetMetadataPayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                changes: changes,
                touched: Self.touchedMap(actuallyApplied ?? Self.projected(updates: updates)),
                runDir: manifest.runDir.path
            )
        }
    }

    // MARK: - Internals

    static func parseAssignments(_ raw: [String]) throws -> [(key: String, value: String)] {
        var out: [(String, String)] = []
        for assignment in raw {
            guard let equalsIndex = assignment.firstIndex(of: "=") else {
                throw PkimError.invalidInput(
                    "expected KEY=VALUE, got: \(assignment)",
                    context: ["assignment": assignment]
                )
            }
            let key = String(assignment[..<equalsIndex])
            let value = String(assignment[assignment.index(after: equalsIndex)...])
            guard !key.isEmpty else {
                throw PkimError.invalidInput(
                    "empty key in: \(assignment)",
                    context: ["assignment": assignment]
                )
            }
            out.append((key, value))
        }
        return out
    }

    /// Compute the diff between the pre-write state for each touched
    /// key and the requested update. Empty value → after = nil (clear).
    static func diff(
        before: [String: String?],
        updates: [(key: String, value: String)]
    ) -> [MetadataFieldChange] {
        var changes: [MetadataFieldChange] = []
        // Preserve CLI argument order so the envelope diff matches what
        // the caller typed.
        for (key, value) in updates {
            let b = before[key] ?? nil
            let a: String? = value.isEmpty ? nil : value
            if b != a {
                changes.append(MetadataFieldChange(field: key, before: b, after: a))
            }
        }
        return changes
    }

    /// Build a change list from updates alone, with no `before` field.
    /// Used on the default (write) where we deliberately skip the pre-read; the
    /// `before` slot is `nil` (encoded as JSON `null`) to signal "not
    /// read — see dry-run if you need the previous value."
    static func projectedChanges(updates: [(key: String, value: String)]) -> [MetadataFieldChange] {
        updates.map { (key, value) in
            MetadataFieldChange(
                field: key,
                before: nil,
                after: value.isEmpty ? nil : value
            )
        }
    }

    /// Project the dry-run "after" state for each touched key.
    static func projected(updates: [(key: String, value: String)]) -> [String: String?] {
        var out: [String: String?] = [:]
        for (key, value) in updates {
            out[key] = value.isEmpty ? nil : value
        }
        return out
    }

    /// Flatten a `[String: String?]` (where nil means "key absent") to
    /// the `[String: String]` shape the envelope publishes. Absent
    /// keys are omitted from the map rather than included with an
    /// empty string — preserves the distinction.
    static func touchedMap(_ values: [String: String?]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in values {
            if let value { out[key] = value }
        }
        return out
    }

}

struct SetMetadataPayload: Encodable, Sendable {
    let ref: String
    let dtUuid: String
    let applied: Bool
    /// `"ok"` after a live write, `"dry-run"` otherwise.
    let kind: String
    let changes: [MetadataFieldChange]
    /// The post-write state of just the keys this call touched. For a
    /// live write this is what DT actually persisted (re-read per key);
    /// for a dry-run it's the proposed value. Keys cleared by the
    /// call are absent from the map (not present with an empty value),
    /// preserving the cleared/empty distinction.
    let touched: [String: String]
    /// Path to this run's directory under `runs/`.
    let runDir: String
}
