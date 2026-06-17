import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim verify-smart-groups [--database <name>]` — confirm the
/// canonical PKIM smart groups exist (at `/Smart group name` under
/// the database root).
///
/// Without `--database`, checks every database the canonical config
/// expects each smart group to live in. With `--database`, restricts
/// to just that one.
///
/// Read-only. Replaces `scripts/verify-smart-groups.applescript`.
struct VerifySmartGroups: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify-smart-groups",
        abstract: "Confirm the canonical PKIM smart groups exist."
    )

    @Option(name: .long, help: "Restrict to one database.")
    var database: String?

    func run() throws {
        try CommandSupport.runReadVerb(named: "verify-smart-groups") {
            let bridge = try DTBridge.connect()
            let openDbs = Dictionary(
                uniqueKeysWithValues: bridge.databases().map { (DTDatabaseAccess.name($0), $0) }
            )

            var results: [SmartGroupCheck] = []
            var failed: [String] = []
            for spec in PKIMSetup.smartGroups {
                let targetDbs = database.map { [$0] } ?? spec.databases
                for dbName in targetDbs where spec.databases.contains(dbName) {
                    guard let db = openDbs[dbName] else {
                        results.append(SmartGroupCheck(
                            name: spec.name,
                            database: dbName,
                            present: false,
                            predicate: nil,
                            error: "database not open"
                        ))
                        failed.append("\(dbName) / \(spec.name)")
                        continue
                    }
                    let path = "/" + spec.name
                    let recordRaw = bridge.app.getRecordAt?(path, in: db)
                    if let record = recordRaw as? DEVONthinkRecord {
                        let predicate = readPredicate(record: record)
                        results.append(SmartGroupCheck(
                            name: spec.name,
                            database: dbName,
                            present: true,
                            predicate: predicate,
                            error: nil
                        ))
                    } else {
                        results.append(SmartGroupCheck(
                            name: spec.name,
                            database: dbName,
                            present: false,
                            predicate: nil,
                            error: nil
                        ))
                        failed.append("\(dbName) / \(spec.name)")
                    }
                }
            }

            return VerifySmartGroupsPayload(
                result: failed.isEmpty ? "ok" : "failed",
                database: database,
                checks: results,
                failed: failed
            )
        }
    }

    /// Smart-group records cast to `DEVONthinkSmartParent` expose
    /// `searchPredicates`; resolve the lazy specifier to a String.
    private func readPredicate(record: DEVONthinkRecord) -> String? {
        guard let sp = record as? DEVONthinkSmartParent else { return nil }
        let value = resolvedString(sp.searchPredicates)
        return value.isEmpty ? nil : value
    }
}

struct SmartGroupCheck: Encodable, Sendable, Equatable {
    let name: String
    let database: String
    let present: Bool
    let predicate: String?
    let error: String?
}

struct VerifySmartGroupsPayload: Encodable, Sendable {
    let result: String
    let database: String?
    let checks: [SmartGroupCheck]
    let failed: [String]
}
