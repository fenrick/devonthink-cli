import Foundation
import Testing
@testable import pkim

@Suite("RecordRef parsing")
struct RecordRefTests {

    @Test("recognises a DT UUID")
    func parsesUUID() {
        let ref = RecordRef.parse("8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        #expect(ref == .dtUUID("8E91F399-EC90-4E7E-9C4F-147A53EC728C"))
    }

    @Test("uppercases a lowercase UUID for cache consistency")
    func uppercasesUUID() {
        let ref = RecordRef.parse("8e91f399-ec90-4e7e-9c4f-147a53ec728c")
        #expect(ref == .dtUUID("8E91F399-EC90-4E7E-9C4F-147A53EC728C"))
    }

    @Test("recognises an item link")
    func parsesItemLink() {
        let raw = "x-devonthink-item://8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        let ref = RecordRef.parse(raw)
        #expect(ref == .itemLink(raw))
    }

    @Test("falls back to PKIM_ID for anything else")
    func parsesPkimId() {
        let ref = RecordRef.parse("KN-20260520-0007")
        #expect(ref == .pkimId("KN-20260520-0007"))
    }

    @Test("trims surrounding whitespace")
    func trims() {
        let ref = RecordRef.parse("  KN-20260520-0007\n")
        #expect(ref == .pkimId("KN-20260520-0007"))
    }
}
