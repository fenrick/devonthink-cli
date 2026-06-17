import ArgumentParser
import Foundation

/// `pkim verify-database <name>` — confirm the canonical PKIM group
/// tree is present in one database. Returns a per-group pass/fail
/// list and an overall `"ok"` / `"failed"` result.
///
/// Read-only. Replaces `scripts/verify-database-setup.applescript`.
struct VerifyDatabase: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify-database",
        abstract: "Confirm the canonical PKIM group tree is present in one database."
    )

    @Argument(help: "Database name.")
    var database: String

    @Option(name: .long, help: "Override group shape (knowledge | evidence).")
    var shape: PKIMSetup.Shape?

    func run() throws {
        try CommandSupport.runReadVerb(named: "verify-database") {
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

            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }

            var checks: [PathCheck] = []
            var failed: [String] = []
            for path in resolvedShape.groups {
                let present = bridge.app.getRecordAt?(path, in: db) is DEVONthinkRecord
                checks.append(PathCheck(path: path, present: present))
                if !present { failed.append(path) }
            }

            return VerifyDatabasePayload(
                result: failed.isEmpty ? "ok" : "failed",
                database: database,
                shape: resolvedShape.rawValue,
                checks: checks,
                failedPaths: failed
            )
        }
    }
}

struct PathCheck: Encodable, Sendable, Equatable {
    let path: String
    let present: Bool
}

struct VerifyDatabasePayload: Encodable, Sendable {
    let result: String
    let database: String
    let shape: String
    let checks: [PathCheck]
    let failedPaths: [String]
}
