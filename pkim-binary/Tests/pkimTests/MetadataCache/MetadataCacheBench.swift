import Foundation
import Testing
@testable import pkim

/// Microbenchmarks against the live `.dt` cache. Reports timings via
/// `Issue.record(...)` (which surfaces them in the test log without
/// failing the test). Gated by `PKIM_BRIDGE_LIVE=1` like the other
/// live tests.
///
/// These are not regression guards — they're "what does cycle time
/// look like" measurements you re-read when the runtime architecture
/// changes.
private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite(".dt cache (bench)", .enabled(if: liveEnabled))
struct MetadataCacheBench {

    let cache = MetadataCache()

    /// Repeatedly read one record from the live cache. Reports mean,
    /// p50, p95, max in milliseconds.
    @Test("findRecord cold-bucket-scan x100")
    func findRecordHot() throws {
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        let knownDB = "22734CAB-2CE4-4CB4-877C-C24F2D94F337"
        // Warmup once so file-system caches are primed; doc 23's
        // performance budget targets sustained, not first-ever.
        _ = try cache.findRecord(uuid: knownUUID, in: knownDB)

        var samples: [Double] = []
        for _ in 0..<100 {
            let start = DispatchTime.now()
            _ = try cache.findRecord(uuid: knownUUID, in: knownDB)
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            samples.append(elapsed)
        }
        Self.report("findRecord (scoped DB, hot fs)", samples)
    }

    /// Same as above but with `databaseUUID = nil` so the lookup
    /// fans out across all open DBs in cache-listing order. Worst-case
    /// for the cache parser; still expected to be sub-millisecond.
    @Test("findRecord cross-DB scan x100")
    func findRecordCrossDB() throws {
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        _ = try cache.findRecord(uuid: knownUUID, in: nil)

        var samples: [Double] = []
        for _ in 0..<100 {
            let start = DispatchTime.now()
            _ = try cache.findRecord(uuid: knownUUID, in: nil)
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            samples.append(elapsed)
        }
        Self.report("findRecord (cross-DB, hot fs)", samples)
    }

    /// Bulk enumeration: parse every `.dt` file in the PKIM-Knowledge
    /// database (a real, large-ish corpus on this machine). This is the
    /// load shape skills like `dt-audit-graph-corpus` will produce when
    /// composed of `pkim search` + `pkim get` calls.
    @Test("readRecord every file in PKIM-Knowledge")
    func bulkParse() throws {
        let knownDB = "22734CAB-2CE4-4CB4-877C-C24F2D94F337"
        let files = try cache.listRecordFiles(in: knownDB)
        let start = DispatchTime.now()
        var success = 0
        var failure = 0
        for url in files {
            do {
                _ = try cache.readRecord(at: url)
                success += 1
            } catch {
                failure += 1
            }
        }
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
        let perRecord = elapsed / Double(max(1, files.count))
        print("""
            bulkParse: \(files.count) records in \(String(format: "%.2f", elapsed)) ms \
            (\(String(format: "%.3f", perRecord)) ms/record) \
            success=\(success) failure=\(failure)
            """)
    }

    /// Time `highestSequence` against the live cache. This is the cost
    /// paid on the `pkim mint-id` hot path when `--sequence` is not
    /// supplied. Should stay well below process startup time (~30 ms);
    /// if it ever doesn't, switch to an `mdfind`-backed implementation.
    @Test("highestSequence scan across all open DBs")
    func sequenceScanCost() throws {
        // Pick a (kind, date) known to have entries so the scan does
        // real work end to end, including the "found something" branch.
        let kind = PKIMClass.kn
        let date = "20260430"
        _ = try cache.highestSequence(kind: kind, date: date)  // warmup

        var samples: [Double] = []
        for _ in 0..<5 {
            let start = DispatchTime.now()
            _ = try cache.highestSequence(kind: kind, date: date)
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            samples.append(elapsed)
        }
        Self.report("highestSequence (kn, 20260430, all DBs)", samples)
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
