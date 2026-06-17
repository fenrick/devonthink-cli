import Foundation
import Testing
@testable import pkim

@Suite("PKIMId")
struct PKIMIdTests {

    @Test("canonical form roundtrips through parse/format")
    func parseFormatRoundtrip() throws {
        let id = try PKIMId.parse("KN-20260520-0007")
        #expect(id.kind == .kn)
        #expect(id.date == "20260520")
        #expect(id.sequence == 7)
        #expect(id.formatted == "KN-20260520-0007")
    }

    @Test(
        "parser accepts all four classes",
        arguments: [
            ("EV-20260101-0001", PKIMClass.ev),
            ("KN-20260101-0001", PKIMClass.kn),
            ("RL-20260101-0001", PKIMClass.rl),
            ("CL-20260101-0001", PKIMClass.cl),
        ]
    )
    func parsesAllClasses(input: String, expected: PKIMClass) throws {
        let id = try PKIMId.parse(input)
        #expect(id.kind == expected)
    }

    @Test("rejects malformed string")
    func rejectsMalformed() {
        #expect(throws: PKIMIdError.invalidFormat("not-a-pkim-id")) {
            try PKIMId.parse("not-a-pkim-id")
        }
    }

    @Test("rejects unknown class")
    func rejectsUnknownClass() {
        #expect(throws: PKIMIdError.unknownClass("XX")) {
            try PKIMId.parse("XX-20260520-0007")
        }
    }

    @Test("rejects bad date length")
    func rejectsBadDate() {
        #expect(throws: PKIMIdError.invalidDate("2026")) {
            try PKIMId.parse("KN-2026-0007")
        }
    }

    @Test("rejects non-numeric date")
    func rejectsNonNumericDate() {
        #expect(throws: PKIMIdError.invalidDate("2026MAY20")) {
            try PKIMId.parse("KN-2026MAY20-0007")
        }
    }

    @Test("rejects sequence out of range")
    func rejectsSequenceOutOfRange() {
        #expect(throws: PKIMIdError.invalidSequence(0)) {
            try PKIMId(kind: .kn, date: "20260520", sequence: 0)
        }
        #expect(throws: PKIMIdError.invalidSequence(10000)) {
            try PKIMId(kind: .kn, date: "20260520", sequence: 10000)
        }
    }

    @Test("zero-pads short sequence numbers")
    func zeroPadsSequence() throws {
        let id = try PKIMId(kind: .ev, date: "20260520", sequence: 3)
        #expect(id.formatted == "EV-20260520-0003")
    }

    @Test("Codable encodes as a single string")
    func codableSingleString() throws {
        let id = try PKIMId(kind: .kn, date: "20260520", sequence: 42)
        let encoder = pkimEncoder()
        let json = try encoder.encode(id)
        let string = String(data: json, encoding: .utf8)
        #expect(string == "\"KN-20260520-0042\"")
    }

    @Test("Codable decodes from a single string")
    func codableDecode() throws {
        let json = "\"RL-20260101-0123\"".data(using: .utf8)!
        let id = try JSONDecoder().decode(PKIMId.self, from: json)
        #expect(id.kind == .rl)
        #expect(id.date == "20260101")
        #expect(id.sequence == 123)
    }
}
