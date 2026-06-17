import ArgumentParser
import Foundation

/// `pkim create-group <db> --path <group-path> [--dry-run]` — create a
/// group hierarchy in a database.
///
/// Backing verb: `app.createLocation(path, in: database)`. DT
/// creates any missing intermediate groups along the path, so
/// `/Inbox/Sources/Imported/` works whether none, some, or all of
/// those groups already exist. Idempotent — if the path is already
/// present, the existing group is returned and nothing changes.
///
/// `--dry-run` (default) reports what would be created without
/// touching DT. the default (write) executes. The leaf group's UUID is
/// returned in the envelope so callers can pipe into `pkim move
/// --to <returned-path>` or `--to-uuid <uuid>` (when that flag
/// lands).
struct CreateGroup: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-group",
        abstract: "Create a group hierarchy in a DEVONthink database."
    )

    @Argument(help: "Database name (e.g. PKIM-Knowledge).")
    var database: String

    @Option(name: .long, help: "Group path, e.g. /Inbox/Sources/Imported/")
    var path: String

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "create-group") { runId in
            try WriteGate.require(dryRun: dryRun)
            guard !path.isEmpty else {
                throw PkimError.invalidInput("--path is required")
            }

            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }

            // Pre-check whether the path exists already, so the envelope
            // reports `created: false` when this is a no-op.
            let existed = bridge.app.getRecordAt?(path, in: db) is DEVONthinkRecord

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<GroupCreation>(
                    runId: runId,
                    verb: "create-group",
                    ref: path,
                    dtUuid: nil,
                    applied: !dryRun,
                    changes: [GroupCreation(path: path, database: database, existed: existed)]
                ),
                applied: !dryRun
            )

            var resultUUID = ""
            var resultPath = path
            if !dryRun {
                guard let created = bridge.app.createLocation?(path, in: db),
                      let asRecord = created as? DEVONthinkRecord
                else {
                    throw PkimError.partialFailure(
                        "createLocation returned no record",
                        context: ["path": path, "database": database]
                    )
                }
                resultUUID = DTRecordAccess.uuid(asRecord)
                resultPath = DTRecordAccess.location(asRecord) + DTRecordAccess.name(asRecord) + "/"
            }

            return CreateGroupPayload(
                applied: !dryRun,
                kind: !dryRun ? (existed ? "exists" : "created") : "dry-run",
                database: database,
                path: resultPath,
                dtUuid: resultUUID,
                existed: existed,
                runDir: manifest.runDir.path
            )
        }
    }
}

struct GroupCreation: Encodable, Sendable, Equatable {
    let path: String
    let database: String
    let existed: Bool
}

struct CreateGroupPayload: Encodable, Sendable {
    let applied: Bool
    /// `"created"` when DT just made the group, `"exists"` when it
    /// was already there, `"dry-run"` when --dry-run was set.
    let kind: String
    let database: String
    let path: String
    let dtUuid: String
    let existed: Bool
    let runDir: String
}
