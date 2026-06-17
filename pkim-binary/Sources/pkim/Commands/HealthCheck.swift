import ArgumentParser
import Foundation

/// `pkim health-check [--database <name>]` — aggregate the
/// `probe-capabilities` result into a pass/fail check list. Useful
/// for skills' pre-flight: a green health-check means the rest of
/// the workflow can proceed.
///
/// Read-only. Each individual check is sub-millisecond — the cost
/// is dominated by the SB connect that `probe-capabilities` does
/// once and we reuse.
struct HealthCheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health-check",
        abstract: "Run a pre-flight check on the local PKIM stack."
    )

    @Option(name: .long, help: "Required database name. Defaults to PKIM-Knowledge.")
    var database: String = "PKIM-Knowledge"

    func run() throws {
        try CommandSupport.runReadVerb(named: "health-check") {
            let bridge: DTBridge?
            do {
                bridge = try DTBridge.connect()
            } catch {
                bridge = nil
            }
            let dbs = bridge?.databases() ?? []
            let openNames = Set(dbs.map(DTDatabaseAccess.name))

            var checks: [HealthCheckResult] = []

            checks.append(.init(
                name: "devonthink-installed",
                passed: bridge != nil,
                detail: bridge == nil ? "bundle not resolved: \(DTBridge.bundleId)" : DTBridge.bundleId
            ))
            checks.append(.init(
                name: "devonthink-running",
                passed: bridge?.isRunning ?? false,
                detail: (bridge?.isRunning ?? false) ? "running" : "not running"
            ))
            let openList = openNames.sorted().joined(separator: ", ")
            checks.append(.init(
                name: "required-database-open",
                passed: openNames.contains(database),
                detail: openNames.contains(database)
                    ? "\(database) is open"
                    : "\(database) not in open set: \(openList)"
            ))
            checks.append(.init(
                name: "write-gate-status",
                passed: true,    // informational — not a failure
                detail: WriteGate.allowed ? "PKIM_ALLOW_PRODUCTION_WRITES=true" : "writes disabled (set PKIM_ALLOW_PRODUCTION_WRITES=true to enable)"
            ))
            let cacheRoot = MetadataCache.defaultRoot()
            let cacheOk = FileManager.default.fileExists(atPath: cacheRoot.path)
            checks.append(.init(
                name: "metadata-cache-reachable",
                passed: cacheOk,
                detail: cacheOk ? cacheRoot.path : "missing: \(cacheRoot.path)"
            ))

            let blocking = checks.filter { $0.name != "write-gate-status" && !$0.passed }
            let overall = blocking.isEmpty ? "ok" : "failed"

            return HealthCheckPayload(
                result: overall,
                database: database,
                checks: checks,
                failedChecks: blocking.map(\.name)
            )
        }
    }
}

struct HealthCheckResult: Encodable, Sendable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

struct HealthCheckPayload: Encodable, Sendable {
    /// `"ok"` if every blocking check passed, `"failed"` otherwise.
    let result: String
    let database: String
    let checks: [HealthCheckResult]
    let failedChecks: [String]
}
