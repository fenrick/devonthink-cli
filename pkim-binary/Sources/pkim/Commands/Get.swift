import ArgumentParser
import Foundation

/// `pkim get <ref>` — return the full metadata snapshot for one record.
/// Read-only; hits only the `.dt` Spotlight cache, so DEVONthink does
/// not need to be running.
///
/// Shape of `data` payload matches doc 23 §"Reads" exactly.
struct Get: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Return the full metadata snapshot for one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "get") {
            let record = try resolveRecord(ref)
            return GetPayload(from: record)
        }
    }
}

/// `get`'s payload exposes the fields the `.dt` cache parse already
/// produces, plus a few derivations (item link, indexed flag,
/// filename basename, top-level `doc_role`/`review_state`). Fields in
/// doc 23 §Reads that the cache plane does NOT cheaply serve are
/// deliberately omitted here:
///
/// - `location` — DT's group path requires walking the group hierarchy
///   via ScriptingBridge; doesn't exist as a cache field.
/// - `tags` — Spotlight-only (`kMDItemUserTags`); served by the future
///   `pkim tags` verb.
/// - `word_count` — not in the cache; computable from the file body
///   via the future `pkim body` verb if needed.
struct GetPayload: Encodable, Sendable, Equatable {
    let pkimId: String
    let dtUuid: String
    let name: String              // record's display name (TITL)
    let recordType: String        // DT kind string ("Markdown", "PDF+Text", …)
    let itemLink: String
    let databaseName: String
    let databasePath: String
    let docRole: String           // from customMetadata.mddocrole, "" if unset
    let reviewState: String       // from customMetadata.mdreview_state, "" if unset
    let aliases: [String]
    let customMetadata: [String: String]
    let isIndexed: Bool
    let filename: String          // basename of filePath
    let filePath: String
    let uti: String

    init(from record: DTRecord) {
        self.pkimId = record.customMetadata["mdpkim_id"] ?? ""
        self.dtUuid = record.uuid
        self.name = record.title
        self.recordType = record.kind
        self.itemLink = "\(RecordRef.itemLinkScheme)\(record.uuid)"
        self.databaseName = record.databaseName
        self.databasePath = record.databasePath
        self.docRole = record.customMetadata["mddocrole"] ?? ""
        self.reviewState = record.customMetadata["mdreview_state"] ?? ""
        self.aliases = record.aliases
        self.customMetadata = record.customMetadata
        self.isIndexed = FilePath.isIndexed(filePath: record.filePath, databasePath: record.databasePath)
        self.filename = (record.filePath as NSString).lastPathComponent
        self.filePath = record.filePath
        self.uti = record.uti
    }
}
