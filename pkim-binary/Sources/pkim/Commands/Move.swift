import ArgumentParser
import Foundation

/// `pkim move <ref> --to <group-path> [--database <name>]` — move one
/// DEVONthink record to a different group.
///
/// Semantics:
///   - `--to` is the destination group path (e.g. `/Inbox/Sources/`).
///     Must already exist — use `pkim create-group` first if not.
///   - `--database` scopes the destination lookup. Default: the
///     record's current database (deduced from the record's `database`
///     property).
///   - **Move-all-instances**: we pass `from: nil` to `moveRecord:`,
///     which DT documents as "Move all instances of a record to a
///     different group." That keeps the record as a single relocation
///     rather than leaving stale instances behind in tag groups,
///     replicants, etc.
///   - `--dry-run` (default) emits a proposal; the default (write) writes.
///
/// Move-only — never replicate, never duplicate. The legacy memory
/// entry "Safe-file Action for EV Records" still applies: `dt.replicate`
/// has a duplicate-creating bug in DT4, so this verb deliberately
/// closes the door on replication.
struct Move: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move one DEVONthink record to a different group."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    @Option(name: .long, help: "Destination group path (must already exist).")
    var to: String

    @Option(name: .long, help: "Database name. Defaults to the record's current database.")
    var database: String?

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "move") { runId in
            try WriteGate.require(dryRun: dryRun)
            guard !to.isEmpty else {
                throw PkimError.invalidInput("--to is required")
            }

            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)

            // Pre-read the current location only on dry-run (for the
            // diff display). On live we just move; the manifest's
            // "before" is null and the verify-read at the end gives
            // the post-state.
            let beforeLocation: String? = !dryRun ? nil : DTRecordAccess.location(record)

            // Resolve the destination database.
            let resolvedDb: DEVONthinkDatabase
            if let dbName = database {
                guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == dbName }) else {
                    throw PkimError.invalidInput(
                        "database not open: \(dbName)",
                        context: ["database": dbName]
                    )
                }
                resolvedDb = db
            } else {
                // The record's database property is typed Any; force-resolve.
                guard let inferred = Self.recordDatabase(record, bridge: bridge) else {
                    throw PkimError.invalidInput(
                        "cannot infer database for record; pass --database",
                        context: ["ref": ref]
                    )
                }
                resolvedDb = inferred
            }

            // Resolve the destination group (lookup only — no auto-create).
            guard let targetRaw = bridge.app.getRecordAt?(to, in: resolvedDb),
                  let target = targetRaw as? DEVONthinkParent else {
                throw PkimError.invalidInput(
                    "destination group not found: \(to) in \(DTDatabaseAccess.name(resolvedDb))",
                    context: ["destination": to, "database": DTDatabaseAccess.name(resolvedDb)]
                )
            }

            // Manifest
            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<LocationChange>(
                    runId: runId,
                    verb: "move",
                    ref: ref,
                    dtUuid: DTRecordAccess.uuid(record),
                    applied: !dryRun,
                    changes: [LocationChange(before: beforeLocation, after: to)]
                ),
                applied: !dryRun
            )

            var afterLocation = to  // optimistic projection for dry-run
            if !dryRun {
                // from: nil → "move all instances". Swift's Any! takes
                // nil cleanly when the underlying ObjC method tolerates
                // missing-value (which moveRecord:from:to: does).
                _ = bridge.app.moveRecord?(record, from: nil, to: target)
                afterLocation = DTRecordAccess.location(record)
            }

            return MovePayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                before: beforeLocation,
                after: afterLocation,
                database: DTDatabaseAccess.name(resolvedDb),
                runDir: manifest.runDir.path
            )
        }
    }

    /// Resolve the record's owning database via the live bridge.
    static func recordDatabase(_ record: DEVONthinkRecord, bridge: DTBridge) -> DEVONthinkDatabase? {
        DTRecordAccess.database(record)
    }
}

struct LocationChange: Encodable, Sendable, Equatable {
    let before: String?
    let after: String
}

struct MovePayload: Encodable, Sendable {
    let ref: String
    let dtUuid: String
    let applied: Bool
    let kind: String
    let before: String?
    let after: String
    let database: String
    let runDir: String
}
