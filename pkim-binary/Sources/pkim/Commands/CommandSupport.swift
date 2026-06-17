import ArgumentParser
import Foundation

/// Shared utilities for verb commands. Each verb produces a single
/// `SuccessEnvelope` / `FailureEnvelope` on stdout and exits with the
/// matching `PkimExit` code.
///
/// `run_id` is generated once per invocation and threaded through both
/// the stdout envelope and the on-disk `runs/<run-id>/` directory.
/// Callers must reuse the run id returned from `runReadVerb` /
/// `runWriteVerb` rather than calling `RunId.generate()` themselves,
/// or stdout and disk artefacts will diverge.
enum CommandSupport {

    /// Emit a success envelope. `runId` must match the run-manifest
    /// directory the verb wrote (or generated, for read-only verbs).
    static func emitSuccess<Payload: Encodable & Sendable>(
        verb: String,
        runId: String,
        payload: Payload,
        warnings: [PkimWarning] = []
    ) throws {
        let envelope = SuccessEnvelope(
            verb: verb,
            runId: runId,
            data: payload,
            warnings: warnings
        )
        writeStdout(try pkimJsonString(envelope))
    }

    /// Emit a failure envelope, then throw an `ExitCode` matching the
    /// PkimError's exit code so the process exits non-zero.
    static func emitFailure(
        verb: String,
        runId: String,
        error: PkimError
    ) throws -> Never {
        let envelope = FailureEnvelope(
            verb: verb,
            runId: runId,
            errorType: error.errorType,
            errorMessage: error.message,
            context: error.context
        )
        writeStdout((try? pkimJsonString(envelope)) ?? "{}")
        throw ExitCode(error.exitCode.rawValue)
    }

    /// Run a read-only verb. The body returns the success payload;
    /// errors are translated to the standard envelope taxonomy.
    /// Reads don't write run manifests, so the body has no need for
    /// the run id.
    static func runReadVerb<Payload: Encodable & Sendable>(
        named verb: String,
        body: () throws -> Payload
    ) throws {
        let runId = RunId.generate().value
        do {
            let payload = try body()
            try emitSuccess(verb: verb, runId: runId, payload: payload)
        } catch let error as PkimError {
            try emitFailure(verb: verb, runId: runId, error: error)
        } catch let error as MetadataCacheError {
            try emitFailure(verb: verb, runId: runId, error: translate(error))
        } catch {
            try emitFailure(
                verb: verb,
                runId: runId,
                error: .internal("\(type(of: error)): \(error)")
            )
        }
    }

    /// Run a write verb. Same shape as `runReadVerb` but also translates
    /// `DTBridge.ConnectError` into `DEVONthinkUnreachable` — that's the
    /// gate-style error every write verb wants to surface uniformly.
    static func runWriteVerb<Payload: Encodable & Sendable>(
        named verb: String,
        body: (String) throws -> Payload
    ) throws {
        let runId = RunId.generate().value
        do {
            let payload = try body(runId)
            try emitSuccess(verb: verb, runId: runId, payload: payload)
        } catch let error as PkimError {
            try emitFailure(verb: verb, runId: runId, error: error)
        } catch let error as DTBridge.ConnectError {
            try emitFailure(
                verb: verb,
                runId: runId,
                error: .devonthinkUnreachable("\(error)")
            )
        } catch let error as MetadataCacheError {
            try emitFailure(verb: verb, runId: runId, error: translate(error))
        } catch {
            try emitFailure(
                verb: verb,
                runId: runId,
                error: .internal("\(type(of: error)): \(error)")
            )
        }
    }

    /// Map a `MetadataCacheError` onto the contract-level `PkimError`
    /// taxonomy so each verb returns a consistent error envelope.
    static func translate(_ error: MetadataCacheError) -> PkimError {
        switch error {
        case .ioError(let m): return .io(m)
        case .parseError(let m): return .io("cache parse: \(m)")
        case .databaseNotFound(let db): return .invalidInput("database not found: \(db)", context: ["database": db])
        case .invalidUUID(let s): return .invalidInput("invalid UUID: \(s)", context: ["uuid": s])
        }
    }
}

/// Resolve a `<ref>` argument to a `DTRecord` from the `.dt` cache.
///
/// Fast (cache reads are sub-millisecond) but **may lag DT's live
/// state by tens of seconds** — the cache is refreshed by DT's
/// Spotlight importer, which has indexing latency. Use this for
/// reads where freshness is not critical (`get`, `file-path`,
/// `mirror-of`, audit walks). For reads that must reflect a
/// just-committed write, use `resolveLiveRecord(_:bridge:)` instead.
func resolveRecord(
    _ raw: String,
    cache: MetadataCache = MetadataCache()
) throws -> DTRecord {
    let ref = RecordRef.parse(raw)
    let record = try cache.resolve(ref)
    guard let record else {
        throw PkimError.invalidInput(
            "record not found: \(raw)",
            context: ["ref": raw]
        )
    }
    return record
}

/// Resolve a `<ref>` argument to a live `DEVONthinkRecord` via
/// ScriptingBridge. Always reflects DT's current state (no
/// Spotlight indexing lag) — use this for verbs whose answer
/// must round-trip with same-session writes (`tags`, `aliases`,
/// the read-back path of every write verb).
///
/// Costs one extra Apple Event over the cache path; for PKIM_ID
/// refs adds an `mdfind` subprocess to resolve the UUID first.
/// In wall-clock terms typically 1–50 ms depending on ref shape.
func resolveLiveRecord(
    _ raw: String,
    bridge: DTBridge
) throws -> DEVONthinkRecord {
    let parsed = RecordRef.parse(raw)
    let uuid: String
    switch parsed {
    case .dtUUID(let u):
        uuid = u
    case .itemLink(let link):
        uuid = String(link.dropFirst(RecordRef.itemLinkScheme.count))
    case .pkimId(let pkimId):
        // mdfind to locate the cache file, then read its UUID
        // from the filename. The cache file may itself be slightly
        // stale, but the UUID it points at is permanent — the
        // subsequent SB lookup gives the fresh record.
        let cache = MetadataCache()
        guard let resolved = try cache.resolve(.pkimId(pkimId)) else {
            throw PkimError.invalidInput(
                "record not found: \(raw)",
                context: ["ref": raw]
            )
        }
        uuid = resolved.uuid
    }
    guard let record = bridge.record(uuid: uuid, in: nil) else {
        throw PkimError.invalidInput(
            "record not found in DEVONthink: \(uuid)",
            context: ["uuid": uuid]
        )
    }
    return record
}
