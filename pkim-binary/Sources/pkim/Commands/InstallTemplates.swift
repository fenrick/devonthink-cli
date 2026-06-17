import ArgumentParser
import Foundation

/// `pkim install-templates [--database <name>]` — install the four
/// canonical PKIM note templates under `<database>/Templates/`.
///
/// Idempotent: existing templates with the same name are skipped.
/// Defaults to PKIM-Knowledge. Replaces
/// `scripts/install-note-templates.applescript`. Write-gated.
struct InstallTemplates: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install-templates",
        abstract: "Install the canonical PKIM note templates."
    )

    @Option(name: .long, help: "Database to install into (default PKIM-Knowledge).")
    var database: String = PKIMSetup.knowledgeDB

    @Flag(name: .long, help: "Preview without writing.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "install-templates") { runId in
            try WriteGate.require(dryRun: dryRun)

            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }
            guard let templatesRaw = bridge.app.getRecordAt?(PKIMSetup.templatesGroup, in: db),
                  let templatesGroup = templatesRaw as? DEVONthinkParent
            else {
                throw PkimError.invalidInput(
                    "\(PKIMSetup.templatesGroup) group not found in \(database) — run setup-database first",
                    context: ["database": database, "group": PKIMSetup.templatesGroup]
                )
            }

            var results: [TemplateInstallResult] = []
            for spec in PKIMSetup.templates {
                let path = "\(PKIMSetup.templatesGroup)/\(spec.name)"
                let existed = bridge.app.getRecordAt?(path, in: db) is DEVONthinkRecord
                if existed {
                    results.append(TemplateInstallResult(
                        name: spec.name, existed: true, created: false, error: nil
                    ))
                    continue
                }
                if dryRun {
                    results.append(TemplateInstallResult(
                        name: spec.name, existed: false, created: true, error: nil
                    ))
                    continue
                }
                let props: [String: Any] = [
                    "name": spec.name,
                    "type": "markdown",
                    "plain text": spec.body,
                ]
                if let raw = bridge.app.createRecordWith?(props, in: templatesGroup),
                   raw as? DEVONthinkRecord != nil {
                    results.append(TemplateInstallResult(
                        name: spec.name, existed: false, created: true, error: nil
                    ))
                } else {
                    results.append(TemplateInstallResult(
                        name: spec.name, existed: false, created: false,
                        error: "createRecordWith returned no record"
                    ))
                }
            }

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<TemplateInstallResult>(
                    runId: runId,
                    verb: "install-templates",
                    ref: database,
                    dtUuid: DTDatabaseAccess.uuid(db),
                    applied: !dryRun,
                    changes: results
                ),
                applied: !dryRun
            )

            return InstallTemplatesPayload(
                applied: !dryRun,
                kind: dryRun ? "dry-run" : "ok",
                database: database,
                templates: results,
                runDir: manifest.runDir.path
            )
        }
    }
}

struct TemplateInstallResult: Encodable, Sendable, Equatable {
    let name: String
    let existed: Bool
    let created: Bool
    let error: String?
}

struct InstallTemplatesPayload: Encodable, Sendable {
    let applied: Bool
    let kind: String
    let database: String
    let templates: [TemplateInstallResult]
    let runDir: String
}
