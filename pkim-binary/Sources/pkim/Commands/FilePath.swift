import ArgumentParser
import Foundation

/// `pkim file-path <ref>` — return the disk path of one record.
///
/// For indexed records this is the canonical on-disk location (the
/// `.md` file under the user's indexed root); for imported records it
/// is the path inside the `.dtBase2` package's `Files.noindex/` tree.
///
/// `is_indexed` distinguishes the two cases by checking whether the
/// file path lies inside the database package — that's the same
/// heuristic the indexed-vs-imported reads in the legacy Python tree
/// used.
struct FilePath: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "file-path",
        abstract: "Return the on-disk path of one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "file-path") {
            let record = try resolveRecord(ref)
            return FilePathPayload(
                ref: ref,
                dtUuid: record.uuid,
                filePath: record.filePath,
                isIndexed: Self.isIndexed(filePath: record.filePath, databasePath: record.databasePath)
            )
        }
    }

    /// A record is "imported" when its file path is inside its
    /// database's `.dtBase2/Files.noindex/` tree; otherwise it's
    /// indexed (file lives elsewhere on disk and DT references it).
    static func isIndexed(filePath: String, databasePath: String) -> Bool {
        let dbExpanded = (databasePath as NSString).expandingTildeInPath
        return !filePath.hasPrefix(dbExpanded)
    }
}

struct FilePathPayload: Encodable, Sendable, Equatable {
    let ref: String
    let dtUuid: String
    let filePath: String
    let isIndexed: Bool
}
