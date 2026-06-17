import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim body <ref>` — return the text body of one record.
///
/// Body source policy (file-as-truth, fresh-by-default):
///
/// - For **indexed** records, the canonical content is the `.md` (or
///   other) file on disk. Read directly from the file path — disk
///   is the truth, always fresh by construction.
/// - For **imported** records, the file lives only inside the
///   `.dtBase2` package and isn't addressable from outside DT. We
///   read via ScriptingBridge (`record.plainText`), NOT via the
///   `.dt` cache's TEXT field. The cache lags writes by tens of
///   seconds; SB always reflects DT's current state. Same fix as
///   `pkim tags` and `pkim aliases` in commit e65ff92.
///
/// The `source` field on the payload tells the caller which path was
/// used.
struct Body: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "body",
        abstract: "Return the text body of one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "body") {
            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)
            let (text, source) = Self.readBody(for: record, bridge: bridge)
            return BodyPayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                source: source,
                wordCount: Self.wordCount(of: text),
                text: text
            )
        }
    }

    static func readBody(for record: DEVONthinkRecord, bridge: DTBridge) -> (text: String, source: String) {
        let filePath = DTRecordAccess.path(record)
        let databasePath = DTRecordAccess.database(record).map(DTDatabaseAccess.path) ?? ""
        let indexed = FilePath.isIndexed(filePath: filePath, databasePath: databasePath)
        if indexed, FileManager.default.fileExists(atPath: filePath) {
            if let contents = try? String(contentsOfFile: filePath, encoding: .utf8) {
                return (contents, "indexed-file")
            }
        }
        return (DTRecordAccess.plainText(record), "sb-plain-text")
    }

    static func wordCount(of text: String) -> Int {
        TextUtil.wordCount(of: text)
    }
}

struct BodyPayload: Encodable, Sendable, Equatable {
    let ref: String
    let dtUuid: String
    /// `"indexed-file"` when the body was read from the canonical
    /// on-disk file; `"sb-plain-text"` when read via ScriptingBridge.
    let source: String
    let wordCount: Int
    let text: String
}
