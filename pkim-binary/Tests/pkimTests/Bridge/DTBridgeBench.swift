import Foundation
import Testing
@testable import pkim

/// Microbenchmarks for the ScriptingBridge transport — the
/// "right-hand half" of the runtime model. Doc 22 / 23 justify the
/// pivot on the premise that compiled Swift + SB is fast enough that
/// we don't need a daemon to amortise startup. These numbers either
/// confirm that or force a redesign.
///
/// Gated by `PKIM_BRIDGE_LIVE=1` AND a running DEVONthink.
private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite("ScriptingBridge (live bench)", .enabled(if: liveEnabled))
struct DTBridgeBench {

    @Test("connect — bundle resolution, no Apple Event")
    func connectCost() throws {
        var samples: [Double] = []
        for _ in 0..<10 {
            let start = DispatchTime.now()
            _ = try DTBridge.connect()
            samples.append(Self.elapsed(since: start))
        }
        Self.report("DTBridge.connect", samples)
    }

    @Test("isRunning — built-in SBApplication property")
    func isRunningCost() throws {
        let bridge = try DTBridge.connect()
        _ = bridge.isRunning  // warmup

        var samples: [Double] = []
        for _ in 0..<50 {
            let start = DispatchTime.now()
            _ = bridge.isRunning
            samples.append(Self.elapsed(since: start))
        }
        Self.report("isRunning", samples)
    }

    @Test("databases() — Apple Event returning the database list")
    func databasesCost() throws {
        let bridge = try DTBridge.connect()
        _ = bridge.databases().count  // warmup

        var samples: [Double] = []
        var count = 0
        for _ in 0..<20 {
            let start = DispatchTime.now()
            count = bridge.databases().count
            samples.append(Self.elapsed(since: start))
        }
        Self.report("databases() [n=\(count)]", samples)
    }

    @Test("databases.map(name) — one property read per DB")
    func databasesNameCost() throws {
        let bridge = try DTBridge.connect()
        let dbs = bridge.databases()
        try #require(!dbs.isEmpty)
        _ = dbs.map(DTDatabaseAccess.name)  // warmup

        var samples: [Double] = []
        for _ in 0..<10 {
            let start = DispatchTime.now()
            _ = dbs.map(DTDatabaseAccess.name)
            samples.append(Self.elapsed(since: start))
        }
        Self.report("databases.map(name) [n=\(dbs.count)]", samples)
    }

    @Test("record(uuid:in:) — single record fetch by UUID")
    func getRecordCost() throws {
        let bridge = try DTBridge.connect()
        let dbs = bridge.databases()
        let target = dbs.first { DTDatabaseAccess.name($0) == "PKIM-Knowledge" } ?? dbs.first
        try #require(target != nil)
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        _ = bridge.record(uuid: knownUUID, in: target)  // warmup

        var samples: [Double] = []
        var foundCount = 0
        for _ in 0..<50 {
            let start = DispatchTime.now()
            let record = bridge.record(uuid: knownUUID, in: target)
            samples.append(Self.elapsed(since: start))
            if record != nil { foundCount += 1 }
        }
        Self.report("record(uuid:in:) [hits=\(foundCount)/50]", samples)
    }

    @Test("record property reads — name + uuid + referenceURL + location")
    func recordPropertiesCost() throws {
        let bridge = try DTBridge.connect()
        let dbs = bridge.databases()
        let target = dbs.first { DTDatabaseAccess.name($0) == "PKIM-Knowledge" } ?? dbs.first
        try #require(target != nil)
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        let record = bridge.record(uuid: knownUUID, in: target)
        try #require(record != nil)
        _ = DTRecordAccess.name(record!)  // warmup chain

        var samples: [Double] = []
        for _ in 0..<50 {
            let start = DispatchTime.now()
            _ = DTRecordAccess.name(record!)
            _ = DTRecordAccess.uuid(record!)
            _ = DTRecordAccess.referenceURL(record!)
            _ = DTRecordAccess.location(record!)
            samples.append(Self.elapsed(since: start))
        }
        Self.report("record.{name,uuid,referenceURL,location} (4 property reads)", samples)
    }

    @Test("end-to-end: connect + databases + getRecord + 4 props")
    func endToEndCost() throws {
        // Shape of cost a real verb like `pkim get` would pay if
        // it went through SB instead of the .dt cache.
        var samples: [Double] = []
        for _ in 0..<10 {
            let start = DispatchTime.now()
            let bridge = try DTBridge.connect()
            let dbs = bridge.databases()
            let target = dbs.first { DTDatabaseAccess.name($0) == "PKIM-Knowledge" } ?? dbs.first
            let record = bridge.record(uuid: "8E91F399-EC90-4E7E-9C4F-147A53EC728C", in: target)
            if let record {
                _ = DTRecordAccess.name(record)
                _ = DTRecordAccess.uuid(record)
                _ = DTRecordAccess.referenceURL(record)
                _ = DTRecordAccess.location(record)
            }
            samples.append(Self.elapsed(since: start))
        }
        Self.report("end-to-end (SB path equiv to one pkim get)", samples)
    }

    private static func elapsed(since start: DispatchTime) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }

    private static func report(_ label: String, _ samples: [Double]) {
        guard !samples.isEmpty else { return }
        let sorted = samples.sorted()
        let mean = samples.reduce(0, +) / Double(samples.count)
        let p50 = sorted[sorted.count / 2]
        let p95 = sorted[Int(Double(sorted.count) * 0.95)]
        let maxVal = sorted.last ?? 0
        print("""
            \(label): n=\(samples.count) \
            mean=\(String(format: "%.2f", mean))ms \
            p50=\(String(format: "%.2f", p50))ms \
            p95=\(String(format: "%.2f", p95))ms \
            max=\(String(format: "%.2f", maxVal))ms
            """)
    }
}
