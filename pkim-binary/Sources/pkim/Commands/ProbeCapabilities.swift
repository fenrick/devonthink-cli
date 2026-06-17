import ArgumentParser
import Foundation

/// `pkim probe-capabilities` — report what the local PKIM stack can
/// currently do. Used as the write-gate precondition: verbs that
/// mutate state run this first to confirm DT is reachable, the
/// expected databases are open, and the env var is set.
///
/// Read-only. Cheap (one SB connect + one round-trip per open
/// database for the name list).
struct ProbeCapabilities: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "probe-capabilities",
        abstract: "Report what the local PKIM stack can currently do."
    )

    func run() throws {
        try CommandSupport.runReadVerb(named: "probe-capabilities") {
            let bridge: DTBridge?
            do {
                bridge = try DTBridge.connect()
            } catch {
                bridge = nil
            }
            let dbs = bridge?.databases() ?? []
            let names = dbs.map(DTDatabaseAccess.name).sorted()
            let allowWrites = WriteGate.allowed
            let dtRunning = bridge?.isRunning ?? false

            // Cache reachability — do we have an indexed Spotlight
            // surface, and how many database directories are present?
            let cacheRoot = MetadataCache.defaultRoot()
            let cacheReachable = FileManager.default.fileExists(atPath: cacheRoot.path)
            let cacheDatabases: [String]
            if cacheReachable, let cached = try? MetadataCache().listDatabases() {
                cacheDatabases = cached.sorted()
            } else {
                cacheDatabases = []
            }

            return ProbeCapabilitiesPayload(
                pkimVersion: "0.1.0-dev",
                devonthinkBundle: DTBridge.bundleId,
                devonthinkInstalled: bridge != nil,
                devonthinkRunning: dtRunning,
                devonthinkVersion: bridge?.version ?? "",
                openDatabases: names,
                writeGateOpen: allowWrites,
                cacheRoot: cacheRoot.path,
                cacheReachable: cacheReachable,
                cacheDatabases: cacheDatabases
            )
        }
    }
}

struct ProbeCapabilitiesPayload: Encodable, Sendable {
    let pkimVersion: String
    let devonthinkBundle: String
    let devonthinkInstalled: Bool
    let devonthinkRunning: Bool
    let devonthinkVersion: String
    let openDatabases: [String]
    /// True iff PKIM_ALLOW_PRODUCTION_WRITES=true.
    let writeGateOpen: Bool
    let cacheRoot: String
    let cacheReachable: Bool
    let cacheDatabases: [String]
}
