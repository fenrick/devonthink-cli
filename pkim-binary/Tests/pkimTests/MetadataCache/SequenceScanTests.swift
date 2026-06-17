import Foundation
import Testing
@testable import pkim

@Suite("PKIM_ID byte-level sequence scan")
struct SequenceScanTests {

    @Test("returns nil for empty buffer")
    func emptyBuffer() {
        let result = MetadataCache.maxSequence(in: Data(), prefix: Array("KN-20260520-".utf8))
        #expect(result == nil)
    }

    @Test("finds a single match")
    func singleMatch() {
        let haystack = Data("noise KN-20260520-0042 trailing".utf8)
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == 42)
    }

    @Test("returns the highest of multiple matches")
    func multipleMatches() {
        let haystack = Data(
            "KN-20260520-0001 KN-20260520-0007 KN-20260520-0003".utf8
        )
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == 7)
    }

    @Test("ignores non-digit trailers")
    func nonDigitTrailer() {
        // The 4 chars after the prefix must all be ASCII digits.
        let haystack = Data("KN-20260520-abcd".utf8)
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == nil)
    }

    @Test("doesn't cross prefix-class boundaries")
    func differentClass() {
        // Looking for KN-... must not match RL-...
        let haystack = Data("RL-20260520-0099".utf8)
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == nil)
    }

    @Test("handles matches at buffer boundaries")
    func boundaryMatch() {
        // Prefix at byte 0; digits run to last byte.
        let haystack = Data("KN-20260520-0042".utf8)
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == 42)
    }

    @Test("ignores partial-prefix near end of buffer")
    func truncatedPrefix() {
        // "KN-20260520-" with no digits following.
        let haystack = Data("KN-20260520-".utf8)
        let result = MetadataCache.maxSequence(in: haystack, prefix: Array("KN-20260520-".utf8))
        #expect(result == nil)
    }
}

// MARK: - Live integration

private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite("highestSequence (live)", .enabled(if: liveEnabled))
struct HighestSequenceLiveTests {

    let cache = MetadataCache()

    /// Ground-truth values discovered by sweeping the live cache on
    /// 2026-05-20. Sequence numbers only ever increase, so these
    /// assertions become `>=` rather than `==` — they remain valid
    /// after future record creation.
    @Test(
        "returns a value >= the known floor for several (kind, date) pairs",
        arguments: [
            (PKIMClass.kn, "20260429", 9),
            (PKIMClass.ev, "20260430", 33),
            (PKIMClass.cl, "20260518", 32),
            (PKIMClass.rl, "20260429", 26),
        ]
    )
    func knownDates(kind: PKIMClass, date: String, floor: Int) throws {
        let max = try cache.highestSequence(kind: kind, date: date)
        try #require(max != nil)
        #expect(max! >= floor)
    }

    @Test("returns nil for a date with no records")
    func unusedDate() throws {
        // A date far enough in the past that no PKIM_IDs should exist.
        let max = try cache.highestSequence(kind: .kn, date: "19000101")
        #expect(max == nil)
    }
}
