import Foundation
import Testing
@testable import pkim

@Suite("mint-id")
struct MintIdTests {

    @Test("envelope builder honors an explicit sequence and skips the cache scan")
    func explicitDateAndSequence() throws {
        let env = try MintId.envelope(
            type: .kn,
            date: "20260520",
            sequence: 7,
            runId: "fixed"
        )
        #expect(env.verb == "mint-id")
        #expect(env.runId == "fixed")
        #expect(env.data.pkimId.formatted == "KN-20260520-0007")
        #expect(env.data.type == .kn)
        #expect(env.data.date == "20260520")
        #expect(env.data.sequence == 7)
        #expect(env.warnings.isEmpty)
    }

    @Test("envelope builder defaults to today's UTC date when --date is omitted")
    func defaultsToToday() throws {
        // Use a fixed `now` so the test is deterministic. Pass an
        // explicit sequence so the cache scan path is skipped (we
        // don't want this test depending on the user's live corpus).
        let now = Date(timeIntervalSince1970: 1_747_756_324) // 2025-05-20T16:32:04Z
        let env = try MintId.envelope(
            type: .ev,
            date: nil,
            sequence: 1,
            runId: "r",
            now: now
        )
        #expect(env.data.date == "20250520")
        #expect(env.data.pkimId.formatted == "EV-20250520-0001")
    }

    @Test("envelope builder rejects an out-of-range sequence")
    func rejectsBadSequence() {
        #expect(throws: PKIMIdError.invalidSequence(0)) {
            try MintId.envelope(type: .kn, date: "20260520", sequence: 0, runId: "r")
        }
    }

    @Test("envelope encodes to JSON with the expected top-level keys")
    func envelopeEncodes() throws {
        let env = try MintId.envelope(type: .kn, date: "20260520", sequence: 7, runId: "fixed")
        let json = try pkimJsonString(env)
        #expect(json.contains("\"verb\":\"mint-id\""))
        #expect(json.contains("\"run_id\":\"fixed\""))
        #expect(json.contains("\"pkim_id\":\"KN-20260520-0007\""))
        #expect(json.contains("\"sequence\":7"))
        #expect(json.contains("\"type\":\"kn\""))
    }
}
