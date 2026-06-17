import ArgumentParser
import Foundation

/// `pkim fix-smart-groups [--database <name>]` — delete and recreate
/// the text-predicate smart groups so they match metadata written via
/// JXA / SB. Replaces `scripts/fix-smart-group-predicates.applescript`.
///
/// Background: DT's GUI smart-group picker emits binary `NSPredicate`s
/// that query the internal field index. JXA writes go straight to the
/// raw customMetaData dictionary; only text predicates match those.
/// This verb rebuilds the rewritable smart groups in
/// `PKIMSetup.rewritableSmartGroups` (5 of the 10 canonical) with text
/// predicates.
///
/// "Is empty / is not empty" smart groups (Needs Profile / Needs OCR
/// / Needs Knowledge Note / Needs Relation Note / Indexed Risk) work
/// correctly out of the box and are deliberately not touched.
///
/// Write-gated; supports `--dry-run`.
struct FixSmartGroups: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fix-smart-groups",
        abstract: "Rebuild PKIM's text-predicate smart groups."
    )

    @Option(name: .long, help: "Restrict to one database.")
    var database: String?

    @Flag(name: .long, help: "Preview without writing.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "fix-smart-groups") { runId in
            try WriteGate.require(dryRun: dryRun)

            let bridge = try DTBridge.connect()
            let openDbs = Dictionary(
                uniqueKeysWithValues: bridge.databases().map { (DTDatabaseAccess.name($0), $0) }
            )

            var changes: [SmartGroupRebuild] = []
            for spec in PKIMSetup.rewritableSmartGroups {
                guard let predicate = spec.predicate else { continue }
                let targetDbs = database.map { [$0] } ?? spec.databases
                for dbName in targetDbs where spec.databases.contains(dbName) {
                    guard let db = openDbs[dbName] else {
                        changes.append(SmartGroupRebuild(
                            name: spec.name, database: dbName,
                            deleted: 0, created: false,
                            predicate: predicate,
                            error: "database not open"
                        ))
                        continue
                    }

                    if dryRun {
                        let existing = countSmartGroups(named: spec.name, in: db)
                        changes.append(SmartGroupRebuild(
                            name: spec.name, database: dbName,
                            deleted: existing, created: true,
                            predicate: predicate, error: nil
                        ))
                        continue
                    }

                    let deleted = deleteSmartGroups(named: spec.name, in: db, bridge: bridge)
                    let createdOK = createSmartGroup(
                        name: spec.name,
                        predicate: predicate,
                        in: db,
                        bridge: bridge
                    )
                    changes.append(SmartGroupRebuild(
                        name: spec.name, database: dbName,
                        deleted: deleted, created: createdOK,
                        predicate: predicate,
                        error: createdOK ? nil : "createRecordWith returned no record"
                    ))
                }
            }

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<SmartGroupRebuild>(
                    runId: runId,
                    verb: "fix-smart-groups",
                    ref: database ?? "*",
                    dtUuid: nil,
                    applied: !dryRun,
                    changes: changes
                ),
                applied: !dryRun
            )

            return FixSmartGroupsPayload(
                applied: !dryRun,
                kind: dryRun ? "dry-run" : "ok",
                database: database,
                changes: changes,
                runDir: manifest.runDir.path
            )
        }
    }

    private func smartGroups(in db: DEVONthinkDatabase) -> [DEVONthinkRecord] {
        guard let arr = db.contents?() else { return [] }
        return arr.compactMap { ($0 as? DEVONthinkRecord) }
            .filter { $0.recordType == .smartGroup }
    }

    private func countSmartGroups(named name: String, in db: DEVONthinkDatabase) -> Int {
        smartGroups(in: db).filter { DTRecordAccess.name($0) == name }.count
    }

    private func deleteSmartGroups(
        named name: String,
        in db: DEVONthinkDatabase,
        bridge: DTBridge
    ) -> Int {
        var deleted = 0
        for record in smartGroups(in: db) where DTRecordAccess.name(record) == name {
            _ = bridge.app.deleteRecord?(record, in: nil)
            deleted += 1
        }
        return deleted
    }

    private func createSmartGroup(
        name: String,
        predicate: String,
        in db: DEVONthinkDatabase,
        bridge: DTBridge
    ) -> Bool {
        let props: [String: Any] = [
            "name": name,
            "type": "smart group",
            "search predicate": predicate,
        ]
        guard let raw = bridge.app.createRecordWith?(props, in: db),
              raw as? DEVONthinkRecord != nil
        else {
            return false
        }
        return true
    }
}

struct SmartGroupRebuild: Encodable, Sendable, Equatable {
    let name: String
    let database: String
    let deleted: Int
    let created: Bool
    let predicate: String
    let error: String?
}

struct FixSmartGroupsPayload: Encodable, Sendable {
    let applied: Bool
    let kind: String
    let database: String?
    let changes: [SmartGroupRebuild]
    let runDir: String
}
