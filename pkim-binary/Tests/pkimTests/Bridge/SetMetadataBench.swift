import Foundation
import Testing
@testable import pkim

/// Round-trip benchmark for `set-metadata` against PKIM-Pilot (the
/// scratch DB). Sets a temporary key, re-reads, clears it. Each
/// iteration is fully reversible — the record's persistent state
/// returns to its pre-test shape.
///
/// Gated by both `PKIM_BRIDGE_LIVE=1` and a running DT with PKIM-Pilot
/// open. Skips silently otherwise.
private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite("set-metadata write (live bench)", .enabled(if: liveEnabled))
struct SetMetadataBench {

    @Test("write + clear round-trip x10")
    func writeCycle() throws {
        let bridge = try DTBridge.connect()
        // PKIM-Pilot record discovered on 2026-05-20. If this UUID
        // disappears from the user's pilot DB later, swap in any
        // other PKIM-Pilot resident — the bench is corpus-agnostic.
        let knownUUID = "E4638D5A-8E95-4AC4-8A53-FD1511FFB4FA"
        guard let record = bridge.record(uuid: knownUUID, in: nil) else {
            Issue.record("target record not found in DT — skipping bench")
            return
        }
        // Capture pre-test state so we can confirm we restored it.
        let pristine = DTCustomMetadata.readAll(record)

        let testKey = "mdpkim_writetest"
        let testValue = "bench-\(Int.random(in: 0..<999999))"

        var setSamples: [Double] = []
        var clearSamples: [Double] = []
        for _ in 0..<10 {
            // Write — atomic single-key via addCustomMetaData
            let start = DispatchTime.now()
            DTCustomMetadata.write(record, key: testKey, value: testValue, bridge: bridge)
            setSamples.append(Self.elapsed(since: start))

            // Verify persisted via atomic single-key read
            #expect(DTCustomMetadata.read(record, key: testKey, bridge: bridge) == testValue)

            // Clear — addCustomMetaData("") removes the key
            let clearStart = DispatchTime.now()
            DTCustomMetadata.clear(record, key: testKey, bridge: bridge)
            clearSamples.append(Self.elapsed(since: clearStart))

            #expect(DTCustomMetadata.read(record, key: testKey, bridge: bridge) == nil)
        }

        // Restore check: every untouched key still matches pristine.
        // Under the atomic API we never touched any key other than
        // `testKey`, so by construction all other keys should be
        // unchanged — including the NSDate-typed ones that drifted
        // under the old applyDeltas implementation.
        let finalState = DTCustomMetadata.readAll(record)
        #expect(finalState[testKey] == nil)
        for (key, value) in pristine {
            #expect(finalState[key] == value, "key \(key) drifted from pristine")
        }

        Self.report("set-metadata write (in-process SB)", setSamples)
        Self.report("set-metadata clear (in-process SB)", clearSamples)
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
