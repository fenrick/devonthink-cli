import ArgumentParser
import Foundation

/// `pkim set-body <ref> --from @<path>` — replace the text body of
/// one DEVONthink record.
///
/// Source policy mirrors `pkim body`:
///   - **indexed** records — write directly to the on-disk file
///     (file-as-truth). DT's indexer picks up the change.
///   - **imported** records — call `record.setPlainText(body)` via
///     ScriptingBridge. DT's `plainText` setter accepts markdown
///     and plain text; for rich text records the verb refuses.
///
/// Body always comes from a file (`--from @<path>` or `--from @-`
/// for stdin). Inline body on the CLI invites shell-quoting hazards
/// for non-trivial markdown.
///
/// `--dry-run` previews; default writes. Live writes require
/// `PKIM_ALLOW_PRODUCTION_WRITES=true`.
struct SetBody: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-body",
        abstract: "Replace the text body of one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    @Option(name: .long, help: "Body source: `@<path>` to read from a file, or `@-` for stdin.")
    var from: String

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "set-body") { runId in
            try WriteGate.require(dryRun: dryRun)
            let newBody = try CreateNote.readBody(spec: from)

            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)

            // We need the file path + indexed flag to decide which
            // write path to use. Both are cheap on the live record.
            let filePath = DTRecordAccess.path(record)
            guard let db = DTRecordAccess.database(record) else {
                throw PkimError.partialFailure(
                    "record has no resolvable database",
                    context: ["uuid": DTRecordAccess.uuid(record)]
                )
            }
            let dbPath = DTDatabaseAccess.path(db)
            let isIndexed = FilePath.isIndexed(filePath: filePath, databasePath: dbPath)

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<BodyChange>(
                    runId: runId,
                    verb: "set-body",
                    ref: ref,
                    dtUuid: DTRecordAccess.uuid(record),
                    applied: !dryRun,
                    changes: [
                        BodyChange(
                            target: isIndexed ? "indexed-file" : "imported-plain-text",
                            filePath: filePath,
                            bodyChars: newBody.count
                        )
                    ]
                ),
                applied: !dryRun
            )

            var actuallyChars = newBody.count
            if !dryRun {
                if isIndexed {
                    // File-as-truth: write the disk file directly.
                    guard !filePath.isEmpty else {
                        throw PkimError.partialFailure(
                            "record has no file path; cannot write indexed body",
                            context: ["uuid": DTRecordAccess.uuid(record)]
                        )
                    }
                    do {
                        try newBody.write(toFile: filePath, atomically: true, encoding: .utf8)
                    } catch {
                        throw PkimError.io("write \(filePath): \(error.localizedDescription)")
                    }
                } else {
                    // Imported record: DT's plainText setter.
                    record.setPlainText?(newBody)
                    // Verify — DT silently no-ops on non-text record
                    // kinds; the read-back tells us if it took.
                    actuallyChars = DTRecordAccess.plainText(record).count
                }
            }

            return SetBodyPayload(
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                target: isIndexed ? "indexed-file" : "imported-plain-text",
                filePath: filePath,
                bodyChars: actuallyChars,
                runDir: manifest.runDir.path
            )
        }
    }
}

struct BodyChange: Encodable, Sendable, Equatable {
    let target: String       // "indexed-file" | "imported-plain-text"
    let filePath: String
    let bodyChars: Int
}

struct SetBodyPayload: Encodable, Sendable {
    let applied: Bool
    let kind: String
    let ref: String
    let dtUuid: String
    let target: String
    let filePath: String
    let bodyChars: Int
    let runDir: String
}
