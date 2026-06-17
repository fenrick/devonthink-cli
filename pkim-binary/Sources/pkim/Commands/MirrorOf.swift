import ArgumentParser
import Foundation

/// `pkim mirror-of <ref>` — return the on-disk mirror path the
/// record exports to.
///
/// PKIM workflow records carry `mdmirror_path` in their custom
/// metadata (e.g. `knowledge/KN-20260429-0002-purpose-design.md`).
/// This verb reads that field and resolves it against the
/// `PKIM_MIRROR_ROOT` env var (or `~/PKIM-mirror/` by default) to
/// produce the absolute path where the mirror writer would land
/// the record.
///
/// Pure read; no DT round-trip needed when the record's metadata
/// is in the cache. Returns `exists: true|false` so callers can
/// tell whether the mirror file is actually present.
struct MirrorOf: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mirror-of",
        abstract: "Return the disk path the mirror writer would target for one record."
    )

    @Argument(help: "Record reference: pkim-id, dt-uuid, or x-devonthink-item://… link.")
    var ref: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "mirror-of") {
            let record = try resolveRecord(ref)
            let relative = record.customMetadata["mdmirror_path"] ?? ""
            let mirrorRoot = Self.mirrorRoot()
            let absolute: String
            if relative.isEmpty {
                absolute = ""
            } else {
                absolute = mirrorRoot.appendingPathComponent(relative).path
            }
            let exists = !absolute.isEmpty && FileManager.default.fileExists(atPath: absolute)
            return MirrorOfPayload(
                ref: ref,
                dtUuid: record.uuid,
                pkimId: record.customMetadata["mdpkim_id"] ?? "",
                mirrorPath: absolute,
                mirrorPathRelative: relative,
                mirrorRoot: mirrorRoot.path,
                exists: exists
            )
        }
    }

    static func mirrorRoot() -> URL {
        if let override = ProcessInfo.processInfo.environment["PKIM_MIRROR_ROOT"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appending(path: "PKIM-mirror", directoryHint: .isDirectory)
    }
}

struct MirrorOfPayload: Encodable, Sendable, Equatable {
    let ref: String
    let dtUuid: String
    let pkimId: String
    /// Absolute mirror path. Empty if the record has no
    /// `mdmirror_path` custom field set.
    let mirrorPath: String
    /// The raw `mdmirror_path` value as stored in DT.
    let mirrorPathRelative: String
    /// Resolved root: `PKIM_MIRROR_ROOT` env var or `~/PKIM-mirror/`.
    let mirrorRoot: String
    /// Whether the mirror file is on disk right now.
    let exists: Bool
}
