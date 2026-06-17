import ArgumentParser
import Foundation

/// `pkim setup-database <name>` — create the canonical PKIM group
/// tree in one database.
///
/// Idempotent — `createLocation` returns the existing group if a path
/// already exists. Replaces `scripts/setup-database-groups.applescript`.
/// Write-gated.
struct SetupDatabase: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "setup-database",
        abstract: "Create the canonical PKIM group tree in one database."
    )

    @Argument(help: "Database name. PKIM-Knowledge / PKIM-Evidence-* / PKIM-Pilot are auto-detected.")
    var database: String

    @Option(name: .long, help: "Override group shape (knowledge | evidence) if the name isn't canonical.")
    var shape: PKIMSetup.Shape?

    @Flag(name: .long, help: "Preview without writing.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "setup-database") { runId in
            try WriteGate.require(dryRun: dryRun)

            let resolvedShape: PKIMSetup.Shape
            if let shape {
                resolvedShape = shape
            } else if let inferred = PKIMSetup.Shape.of(database: database) {
                resolvedShape = inferred
            } else {
                throw PkimError.invalidInput(
                    "unknown database \(database) — pass --shape knowledge|evidence",
                    context: ["database": database]
                )
            }
            let groups = resolvedShape.groups

            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }

            var results: [GroupResult] = []
            for path in groups {
                let existed = bridge.app.getRecordAt?(path, in: db) is DEVONthinkRecord
                if dryRun {
                    results.append(GroupResult(path: path, existed: existed, created: !existed, error: nil))
                    continue
                }
                if let raw = bridge.app.createLocation?(path, in: db),
                   raw as? DEVONthinkRecord != nil {
                    results.append(GroupResult(path: path, existed: existed, created: !existed, error: nil))
                } else {
                    results.append(GroupResult(path: path, existed: existed, created: false, error: "createLocation returned nil"))
                }
            }

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<GroupResult>(
                    runId: runId,
                    verb: "setup-database",
                    ref: database,
                    dtUuid: DTDatabaseAccess.uuid(db),
                    applied: !dryRun,
                    changes: results
                ),
                applied: !dryRun
            )

            return SetupDatabasePayload(
                applied: !dryRun,
                kind: dryRun ? "dry-run" : "ok",
                database: database,
                shape: resolvedShape.rawValue,
                groups: results,
                runDir: manifest.runDir.path
            )
        }
    }
}

extension PKIMSetup.Shape: ExpressibleByArgument {}

struct GroupResult: Encodable, Sendable, Equatable {
    let path: String
    let existed: Bool
    let created: Bool
    let error: String?
}

struct SetupDatabasePayload: Encodable, Sendable {
    let applied: Bool
    let kind: String
    let database: String
    let shape: String
    let groups: [GroupResult]
    let runDir: String
}
