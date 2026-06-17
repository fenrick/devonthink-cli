import ArgumentParser
import Foundation

/// `pkim resolve <ref>` — return the canonical identifiers for one
/// record. Accepts PKIM_ID, DT UUID, or item-link forms. Used by every
/// other verb that takes a `<ref>` argument; exposed standalone for
/// agents that just need the cross-form translation.
struct Resolve: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resolve",
        abstract: "Resolve a record reference (pkim-id, dt-uuid, or item-link) to its canonical identifiers."
    )

    @Argument(help: "Record reference: pkim-id (e.g. KN-20260520-0007), dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "resolve") {
            let record = try resolveRecord(ref)
            return ResolvePayload(
                ref: ref,
                pkimId: record.customMetadata["mdpkim_id"] ?? "",
                dtUuid: record.uuid,
                itemLink: "\(RecordRef.itemLinkScheme)\(record.uuid)",
                databaseName: record.databaseName
            )
        }
    }
}

struct ResolvePayload: Encodable, Sendable, Equatable {
    let ref: String
    let pkimId: String
    let dtUuid: String
    let itemLink: String
    let databaseName: String
}
