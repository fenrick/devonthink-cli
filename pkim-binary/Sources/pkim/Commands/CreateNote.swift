import ArgumentParser
import Foundation

/// `pkim create-note <db> --group <path> --title <name> --body @<file> [--type markdown]`
/// — create a new record in DEVONthink.
///
/// Backed by `app.createRecordWith(properties, in: parent)` — one
/// Apple Event that takes a properties dict (name / type / content)
/// and the parent group, returns the new record. Doc 23 §"Writes"
/// `create-note`.
///
/// Body is always read from a file (`--body @<path>` or
/// `--body @-` for stdin). Inline body on the CLI would invite
/// shell-quoting hazards for non-trivial markdown.
///
/// The destination group must already exist — run `pkim create-group`
/// first if not. (We deliberately don't auto-create groups here;
/// `move --to` has the same rule for consistency.)
///
/// If `--pkim-id` is omitted, the verb mints one via the same logic
/// as `pkim mint-id` and stamps it onto the new record's
/// customMetaData. The minted ID is returned in the envelope.
struct CreateNote: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-note",
        abstract: "Create a new record in DEVONthink."
    )

    @Argument(help: "Database name.")
    var database: String

    @Option(name: .long, help: "Destination group path (must already exist).")
    var group: String

    @Option(name: .long, help: "Record title / display name.")
    var title: String

    @Option(name: .long, help: "Body source: `@<path>` to read from a file, or `@-` for stdin.")
    var body: String

    @Option(name: .long, help: "Record type. Default markdown.")
    var type: NoteType = .markdown

    @Option(name: .long, help: "Explicit PKIM_ID. Omit to mint one via the cache scan.")
    var pkimId: String?

    @Option(name: .long, help: "Class for minting (kn|rl|ev|cl). Defaults to kn. Ignored when --pkim-id is supplied.")
    var pkimClass: PKIMClass = .kn

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "create-note") { runId in
            try WriteGate.require(dryRun: dryRun)
            guard !title.isEmpty else { throw PkimError.invalidInput("--title is required") }
            guard !group.isEmpty else { throw PkimError.invalidInput("--group is required") }

            let bodyText = try Self.readBody(spec: body)

            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }
            guard let groupRaw = bridge.app.getRecordAt?(group, in: db),
                  let parent = groupRaw as? DEVONthinkParent else {
                throw PkimError.invalidInput(
                    "destination group not found: \(group) in \(database) — run create-group first",
                    context: ["group": group, "database": database]
                )
            }

            // Resolve the PKIM_ID — supplied or minted.
            let resolvedId: PKIMId
            if let raw = pkimId {
                resolvedId = try PKIMId.parse(raw)
            } else {
                let date = Self.utcDate()
                let cache = MetadataCache()
                let next = (try cache.highestSequence(kind: pkimClass, date: date) ?? 0) + 1
                resolvedId = try PKIMId(kind: pkimClass, date: date, sequence: next)
            }

            // Manifest's dt_uuid is nil until createRecordWith returns —
            // see MutationArtefact.dtUuid.
            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<NoteCreation>(
                    runId: runId,
                    verb: "create-note",
                    ref: resolvedId.formatted,
                    dtUuid: nil,
                    applied: !dryRun,
                    changes: [
                        NoteCreation(
                            pkimId: resolvedId.formatted,
                            database: database,
                            group: group,
                            title: title,
                            type: type.rawValue,
                            bodyChars: bodyText.count
                        )
                    ]
                ),
                applied: !dryRun
            )

            var newUuid = ""
            var location = group
            if !dryRun {
                // createRecordWith properties dict: name, type, content
                // (or plain text for markdown), plus aliases so the
                // PKIM_ID is queryable via record.aliases.
                let props: [String: Any] = [
                    "name": title,
                    "type": type.rawValue,
                    "plain text": bodyText,
                    "aliases": resolvedId.formatted,
                ]
                guard let createdRaw = bridge.app.createRecordWith?(props, in: parent),
                      let created = createdRaw as? DEVONthinkRecord
                else {
                    throw PkimError.partialFailure(
                        "createRecordWith returned no record",
                        context: ["title": title, "group": group]
                    )
                }
                newUuid = DTRecordAccess.uuid(created)
                location = DTRecordAccess.location(created) + DTRecordAccess.name(created)

                // Stamp the PKIM_ID into customMetaData so the
                // mdfind-by-mdpkim_id lookup path works.
                DTCustomMetadata.write(created, key: "mdpkim_id", value: resolvedId.formatted, bridge: bridge)
            }

            return CreateNotePayload(
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                pkimId: resolvedId.formatted,
                dtUuid: newUuid,
                database: database,
                group: group,
                title: title,
                type: type.rawValue,
                location: location,
                bodyChars: bodyText.count,
                runDir: manifest.runDir.path
            )
        }
    }

    /// Body specs: `@<path>` reads from a file; `@-` reads from stdin.
    static func readBody(spec: String) throws -> String {
        guard spec.hasPrefix("@") else {
            throw PkimError.invalidInput(
                "--body must be `@<path>` or `@-` (got `\(spec)`)",
                context: ["body": spec]
            )
        }
        let path = String(spec.dropFirst())
        if path == "-" {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw PkimError.io("could not read body file: \(path) — \(error.localizedDescription)")
        }
    }

    static func utcDate() -> String {
        DateUtil.utcDate()
    }
}

/// Closed-set record kinds accepted by `pkim create-note`. The raw
/// value is what DT's `createRecordWith` properties dict expects.
enum NoteType: String, Codable, Sendable, CaseIterable, ExpressibleByArgument {
    case markdown
    case txt
    case rtf
    case html

    init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}

struct NoteCreation: Encodable, Sendable, Equatable {
    let pkimId: String
    let database: String
    let group: String
    let title: String
    let type: String
    let bodyChars: Int
}

struct CreateNotePayload: Encodable, Sendable {
    let applied: Bool
    let kind: String
    let pkimId: String
    let dtUuid: String
    let database: String
    let group: String
    let title: String
    let type: String
    let location: String
    let bodyChars: Int
    let runDir: String
}
