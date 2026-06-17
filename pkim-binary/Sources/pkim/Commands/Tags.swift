import ArgumentParser
import Foundation
import ScriptingBridge

/// `pkim tags <ref>` — return the macOS user tags on one record.
///
/// Reads via ScriptingBridge (`record.tags`), not via `mdls`. The
/// Spotlight surface lags writes by tens of seconds, which broke
/// round-trip honesty for `pkim set-tags` → `pkim tags`
/// (writes persisted to DT but `pkim tags` still showed old data).
/// SB always reflects DT's current state.
///
/// Cost: one Apple Event (~1 ms) plus the ref-resolution work
/// (cache hit for UUID / item-link, ~50 ms mdfind for PKIM_ID).
/// Still well under the old mdls subprocess fork.
struct Tags: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tags",
        abstract: "Return the user tags on one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "tags") {
            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)
            return TagsPayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                tags: SetTags.readTags(record)
            )
        }
    }
}

struct TagsPayload: Encodable, Sendable, Equatable {
    let ref: String
    let dtUuid: String
    let tags: [String]
}
