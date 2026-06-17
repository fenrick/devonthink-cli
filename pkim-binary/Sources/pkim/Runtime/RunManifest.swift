import Foundation

/// On-disk run manifest. Each `pkim` invocation that mutates state
/// writes a directory under `runs/<run-id>/` with the artefacts the
/// caller can inspect afterwards.
///
/// Shape per doc 23 §"Run manifests":
/// ```
/// runs/<run-id>/
///   invocation.json          verb + argv + start/end + exit code
///   mutation.json            writes only; before/after for each field
///   mutation-proposal.json   dry-runs only; same shape minus `applied`
///   stdout.json              exact bytes the binary printed
/// ```
///
/// The minimal implementation here writes `mutation.json` /
/// `mutation-proposal.json` only — that's the artefact verbs care
/// about. `invocation.json` and `stdout.json` are nice-to-haves and
/// land when a verb needs them.
struct RunManifest {
    let runId: String
    let runDir: URL

    /// Create the run directory under `<repoRoot>/runs/<run-id>/`.
    /// Repo root is derived from `pwd` when not overridden by the
    /// `PKIM_RUNS_ROOT` env var (useful in tests).
    static func create(runId: String) throws -> RunManifest {
        let root: URL
        if let override = ProcessInfo.processInfo.environment["PKIM_RUNS_ROOT"], !override.isEmpty {
            root = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                .appending(path: "runs", directoryHint: .isDirectory)
        }
        let runDir = root.appending(path: runId, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: runDir, withIntermediateDirectories: true)
        return RunManifest(runId: runId, runDir: runDir)
    }

    /// Write a mutation artefact. `applied=true` produces
    /// `mutation.json`; `false` produces `mutation-proposal.json`.
    func writeMutation<Body: Encodable>(_ body: Body, applied: Bool) throws {
        let filename = applied ? "mutation.json" : "mutation-proposal.json"
        let url = runDir.appending(path: filename, directoryHint: .notDirectory)
        let data = try pkimEncoder().encode(body)
        try data.write(to: url, options: [.atomic])
    }
}

/// Common payload shape for `mutation.json` / `mutation-proposal.json`.
/// Generic over the verb-specific `Change` so set-metadata, set-tags,
/// set-body, etc. can each carry their own diff shape while sharing
/// the wrapper.
struct MutationArtefact<Change: Encodable & Sendable>: Encodable, Sendable {
    let runId: String
    let verb: String
    let ref: String
    /// UUID of the affected record. `nil` for verbs that don't have a
    /// UUID yet (e.g. `create-note` before `createRecordWith` returns,
    /// `create-group` for the leaf-creation case). Verbs that mutate an
    /// existing record always populate this.
    let dtUuid: String?
    let applied: Bool
    let changes: [Change]
}

/// One key's before/after for a custom-metadata field.
struct MetadataFieldChange: Encodable, Sendable, Equatable {
    let field: String
    let before: String?    // nil = field absent
    let after: String?     // nil = field cleared
}
