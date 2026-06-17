import ArgumentParser
import Foundation

/// `pkim set-name <ref> <name>` — set the display name of one
/// DEVONthink record.
///
/// One Apple Event (`record.setName:`). No read-modify-write; the
/// new name is the only thing the caller cares about. On dry-run we
/// pre-read for the diff; on live we skip the pre-read and let the
/// verify-read after the write give the authoritative after-state.
struct SetName: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-name",
        abstract: "Set the display name of one DEVONthink record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    @Argument(help: "The new name.")
    var newName: String

    @Flag(name: .long, help: "Preview the change without writing to DEVONthink.")
    var dryRun: Bool = false

    func run() throws {
        try CommandSupport.runWriteVerb(named: "set-name") { runId in
            try WriteGate.require(dryRun: dryRun)
            guard !newName.isEmpty else {
                throw PkimError.invalidInput("new name must not be empty")
            }

            let bridge = try DTBridge.connect()
            let record = try resolveLiveRecord(ref, bridge: bridge)

            let before: String? = !dryRun ? nil : DTRecordAccess.name(record)

            let manifest = try RunManifest.create(runId: runId)
            try manifest.writeMutation(
                MutationArtefact<NameChange>(
                    runId: runId,
                    verb: "set-name",
                    ref: ref,
                    dtUuid: DTRecordAccess.uuid(record),
                    applied: !dryRun,
                    changes: [NameChange(before: before, after: newName)]
                ),
                applied: !dryRun
            )

            var actuallyApplied = newName
            if !dryRun {
                record.setName?(newName)
                // Verify what DT stored — setName accepts most strings
                // but DT may sanitise (e.g. filename-illegal chars).
                actuallyApplied = DTRecordAccess.name(record)
            }

            return SetNamePayload(
                ref: ref,
                dtUuid: DTRecordAccess.uuid(record),
                applied: !dryRun,
                kind: !dryRun ? "ok" : "dry-run",
                before: before,
                after: actuallyApplied,
                runDir: manifest.runDir.path
            )
        }
    }
}

struct NameChange: Encodable, Sendable, Equatable {
    /// `nil` on the default (write) (we deliberately skip the pre-read);
    /// populated on `--dry-run`.
    let before: String?
    let after: String
}

struct SetNamePayload: Encodable, Sendable {
    let ref: String
    let dtUuid: String
    let applied: Bool
    let kind: String
    let before: String?
    let after: String
    let runDir: String
}
