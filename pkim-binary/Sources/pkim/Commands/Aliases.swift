import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim aliases <ref>` — return the aliases on one record.
///
/// Reads via ScriptingBridge for the same freshness reason as
/// `pkim tags`: PKIM skill workflows store the PKIM_ID as an
/// alias on the record (per the user-memory rule "All KN and RL
/// notes must have … PKIM_ID alias set"), and a writer →
/// immediate-reader round-trip needs the live value, not the
/// Spotlight-indexed cache view.
///
/// DT stores aliases as a single string, semicolon-separated.
/// We parse the wire string into a Swift array; the array order
/// matches the on-disk order.
struct Aliases: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aliases",
        abstract: "Return the alias list for one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "aliases") {
            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)
            return AliasesPayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                aliases: Self.readAliases(record)
            )
        }
    }

    /// Force-resolve the lazy SBObject the `aliases` accessor returns,
    /// then split on `;` or `,` (DT accepts either as separators in
    /// the underlying string).
    static func readAliases(_ record: DEVONthinkRecord) -> [String] {
        let raw: String
        if let s = record.aliases as? String {
            raw = s
        } else if let obj = record.aliases as? SBObject {
            raw = "\(obj.get() ?? "")"
        } else {
            return []
        }
        return raw
            .split(whereSeparator: { $0 == ";" || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

struct AliasesPayload: Encodable, Sendable, Equatable {
    let ref: String
    let dtUuid: String
    let aliases: [String]
}
