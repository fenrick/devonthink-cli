import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim list <db> --group <path> [--limit N]` — list immediate
/// children of a group.
///
/// Backed by `parent.children()`. Returns one entry per direct
/// child (no recursion — agents/skills doing deep enumeration call
/// `list` per level so the cost is paid in steps, not in one
/// surprise mega-walk).
///
/// Records are emitted with pkim_id, dt_uuid, name, record_type,
/// is_group, and item_link. Fields beyond that come from `pkim get`
/// per record — list stays lean.
struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List immediate children of a group in a DEVONthink database."
    )

    @Argument(help: "Database name.")
    var database: String

    @Option(name: .long, help: "Group path. Default `/` (database root).")
    var group: String = "/"

    @Option(name: .long, help: "Cap the result set. 0 = no cap.")
    var limit: Int = 0

    func run() throws {
        try CommandSupport.runReadVerb(named: "list") {
            let bridge = try DTBridge.connect()
            guard let db = bridge.databases().first(where: { DTDatabaseAccess.name($0) == database }) else {
                throw PkimError.invalidInput(
                    "database not open: \(database)",
                    context: ["database": database]
                )
            }
            let parent: DEVONthinkParent
            if group == "/" {
                guard let root = db.root as? DEVONthinkParent
                        ?? ((db.root as? SBObject)?.get() as? DEVONthinkParent) else {
                    throw PkimError.partialFailure("could not resolve database root")
                }
                parent = root
            } else {
                guard let raw = bridge.app.getRecordAt?(group, in: db),
                      let p = raw as? DEVONthinkParent else {
                    throw PkimError.invalidInput(
                        "group not found: \(group) in \(database)",
                        context: ["group": group, "database": database]
                    )
                }
                parent = p
            }

            let childrenArray = parent.children?() ?? SBElementArray()
            var rows: [ListEntry] = []
            for case let child as DEVONthinkRecord in childrenArray {
                if limit > 0, rows.count >= limit { break }
                // sdp renamed `type` → `recordType` to avoid the
                // Swift keyword clash; returns the DEVONthinkDataType
                // enum. DT's special root groups (Trash, Inbox, Tags,
                // Duplicates, smart group views) return values
                // outside our enum vocabulary — for those we fall
                // back to a children-presence check, which is one
                // extra Apple Event per record but reliable.
                let recordType = child.recordType
                let primaryIsGroup = recordType == .group || recordType == .smartGroup
                let isGroup: Bool
                if primaryIsGroup {
                    isGroup = true
                } else {
                    // Cheap-ish fallback: the count on the children
                    // SBElementArray triggers DT to enumerate. Non-zero
                    // count = group-like.
                    isGroup = (child.children?().count ?? 0) > 0
                }
                rows.append(ListEntry(
                    pkimId: DTCustomMetadata.read(child, key: "mdpkim_id", bridge: bridge) ?? "",
                    dtUuid: DTRecordAccess.uuid(child),
                    name: DTRecordAccess.name(child),
                    recordType: DTRecordAccess.kind(child),
                    isGroup: isGroup,
                    itemLink: "\(RecordRef.itemLinkScheme)\(DTRecordAccess.uuid(child))"
                ))
            }

            return ListPayload(
                database: database,
                group: group,
                returned: rows.count,
                records: rows
            )
        }
    }
}

struct ListEntry: Encodable, Sendable, Equatable {
    let pkimId: String
    let dtUuid: String
    let name: String
    let recordType: String
    let isGroup: Bool
    let itemLink: String
}

struct ListPayload: Encodable, Sendable {
    let database: String
    let group: String
    let returned: Int
    let records: [ListEntry]
}
