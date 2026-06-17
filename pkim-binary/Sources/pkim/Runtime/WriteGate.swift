import Foundation

/// Write-gate enforcement.
///
/// Per doc 00 §"Write-gating policy" and doc 23 §"Write-gate
/// enforcement", a production write requires two things:
///
/// 1. `PKIM_ALLOW_PRODUCTION_WRITES=true` in the environment.
/// 2. A passing capability probe (DT installed AND running).
///
/// The probe is cached in-process for 60 seconds so a verb that
/// internally issues multiple writes (or a sub-step that re-checks)
/// pays the SB-connect cost once. The cache lives only for the
/// lifetime of the process and is not persisted to disk.
///
/// `--dry-run` paths bypass both checks entirely — they produce a
/// proposal artefact but never reach SB.
enum WriteGate {

    /// In-process probe cache. The unchecked-Sendable wrapper is
    /// safe here because each `pkim` invocation is single-threaded;
    /// the cache exists to amortise within one process, not across.
    private final class Cache: @unchecked Sendable {
        var checkedAt: Date?
        var lastResult: ProbeResult?
    }

    /// Outcome of one probe attempt. `notProbed` is impossible from
    /// `probe()`; the case exists so callers can distinguish a fresh
    /// cache miss from a cached result.
    enum ProbeResult: Sendable, Equatable {
        case ok
        case dtUnreachable(reason: String)
    }

    private static let cache = Cache()
    private static let cacheTTL: TimeInterval = 60

    /// Returns true iff `PKIM_ALLOW_PRODUCTION_WRITES` is exactly
    /// `"true"` (case-insensitive). Any other value, including unset,
    /// counts as denied.
    static var allowed: Bool {
        guard let raw = ProcessInfo.processInfo.environment["PKIM_ALLOW_PRODUCTION_WRITES"] else {
            return false
        }
        return raw.lowercased() == "true"
    }

    /// Throw if a write is about to happen but the gate is closed.
    /// Verbs call this immediately after argument parsing, before any
    /// DT round-trip. Order: env var → probe (cached 60 s).
    ///
    /// `dryRun: true` short-circuits — no write means no gate check.
    static func require(dryRun: Bool) throws {
        if dryRun { return }
        guard allowed else {
            throw PkimError.devonthinkUnreachable(
                "PKIM_ALLOW_PRODUCTION_WRITES must be \"true\" to execute writes. " +
                "Add --dry-run to preview without writing."
            )
        }
        switch probe() {
        case .ok:
            return
        case .dtUnreachable(let reason):
            throw PkimError.devonthinkUnreachable(reason)
        }
    }

    /// Run the capability probe or return the cached result if still
    /// within `cacheTTL`. Public so verbs that need the probe outcome
    /// for diagnostic envelopes can read it without re-probing.
    @discardableResult
    static func probe(now: Date = Date()) -> ProbeResult {
        if let checkedAt = cache.checkedAt,
           let last = cache.lastResult,
           now.timeIntervalSince(checkedAt) < cacheTTL {
            return last
        }
        let result = runProbe()
        cache.checkedAt = now
        cache.lastResult = result
        return result
    }

    /// Clear the cache. Test-only.
    static func resetProbeCache() {
        cache.checkedAt = nil
        cache.lastResult = nil
    }

    private static func runProbe() -> ProbeResult {
        let bridge: DTBridge
        do {
            bridge = try DTBridge.connect()
        } catch {
            return .dtUnreachable(reason: "DEVONthink not installed: \(DTBridge.bundleId)")
        }
        guard bridge.isRunning else {
            return .dtUnreachable(reason: "DEVONthink is not running")
        }
        return .ok
    }
}
