import Foundation
import Testing
@testable import pkim

@Suite(".dt TLV parser")
struct DTFieldTests {

    /// Build a single TLV field on the wire format.
    static func encode(tag: String, payload: Data) -> Data {
        var out = Data()
        out.append(contentsOf: [0x44, 0x54, 0x73, 0x74]) // DTst
        // Pad tag to 4 ASCII bytes (right-pad with spaces).
        let padded = (tag + "    ").prefix(4)
        out.append(contentsOf: padded.utf8)
        // big-endian uint32 length
        let length = UInt32(payload.count)
        out.append(UInt8((length >> 24) & 0xff))
        out.append(UInt8((length >> 16) & 0xff))
        out.append(UInt8((length >>  8) & 0xff))
        out.append(UInt8( length        & 0xff))
        // 4 reserved bytes
        out.append(contentsOf: [0, 0, 0, 0])
        // payload
        out.append(payload)
        return out
    }

    static func encode(tag: String, text: String) -> Data {
        return encode(tag: tag, payload: Data(text.utf8))
    }

    @Test("parses a single field")
    func singleField() throws {
        let buffer = Self.encode(tag: "NAME", text: "hello")
        let fields = try parseDTFields(buffer)
        #expect(fields.count == 1)
        #expect(fields[0].tag == "NAME")
        #expect(fields[0].text == "hello")
    }

    @Test("parses two adjacent fields")
    func twoFields() throws {
        var buffer = Self.encode(tag: "NAME", text: "first")
        buffer.append(Self.encode(tag: "UUID", text: "0000-1111"))
        let fields = try parseDTFields(buffer)
        #expect(fields.map(\.tag) == ["NAME", "UUID"])
        #expect(fields.map(\.text) == ["first", "0000-1111"])
    }

    @Test("trims trailing-space tag (UTI )")
    func trimsTrailingSpace() throws {
        let buffer = Self.encode(tag: "UTI ", text: "public.plain-text")
        let fields = try parseDTFields(buffer)
        #expect(fields[0].tag == "UTI") // trimmed
    }

    @Test("empty buffer yields zero fields")
    func emptyBuffer() throws {
        let fields = try parseDTFields(Data())
        #expect(fields.isEmpty)
    }

    @Test("rejects truncated header")
    func truncatedHeader() {
        let bytes: [UInt8] = [0x44, 0x54, 0x73, 0x74, 0x4e, 0x41, 0x4d] // missing 9 bytes
        #expect(throws: DTFieldError.truncated(at: 0)) {
            try parseDTFields(Data(bytes))
        }
    }

    @Test("rejects missing magic")
    func missingMagic() {
        // 16 bytes long but wrong magic
        let bytes = [UInt8](repeating: 0x00, count: 16)
        #expect(throws: DTFieldError.missingMagic(at: 0)) {
            try parseDTFields(Data(bytes))
        }
    }

    @Test("rejects length overflow")
    func lengthOverflow() {
        // Magic + tag + length=100 + 4 reserved + 0-byte payload
        var bytes: [UInt8] = [0x44, 0x54, 0x73, 0x74,
                              0x4e, 0x41, 0x4d, 0x45] // "DTstNAME"
        bytes.append(contentsOf: [0x00, 0x00, 0x00, 0x64]) // length = 100
        bytes.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // reserved
        // ... but no payload bytes follow
        #expect(throws: (any Error).self) {
            try parseDTFields(Data(bytes))
        }
    }
}

@Suite("DTRecord builder")
struct DTRecordTests {

    static func field(_ tag: String, _ text: String) -> DTField {
        DTField(tag: tag, payload: Data(text.utf8))
    }

    @Test("assembles all standard fields")
    func standardFields() throws {
        let fields: [DTField] = [
            Self.field("DBID", "11111111-2222-3333-4444-555555555555"),
            Self.field("NAME", "PKIM-Knowledge"),
            Self.field("PATH", "~/Databases/PKIM-Knowledge.dtBase2"),
            Self.field("TITL", "Purpose Design"),
            Self.field("ALIA", "Purpose Design; KN-20260429-0002"),
            Self.field("UUID", "8E91F399-EC90-4E7E-9C4F-147A53EC728C"),
            Self.field("KIND", "Markdown"),
            Self.field("TEXT", "## Summary\n…"),
            Self.field("FILE", "/Users/x/file.md"),
            Self.field("UTI", "public.plain-text"),
            Self.field("MTDT", "kMDItemTitle:$Purpose Design"),
        ]
        let record = try DTRecord.from(fields: fields)
        #expect(record.databaseUUID == "11111111-2222-3333-4444-555555555555")
        #expect(record.databaseName == "PKIM-Knowledge")
        #expect(record.title == "Purpose Design")
        #expect(record.aliases == ["Purpose Design", "KN-20260429-0002"])
        #expect(record.uuid == "8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        #expect(record.kind == "Markdown")
        #expect(record.uti == "public.plain-text")
        #expect(record.mtdt == "kMDItemTitle:$Purpose Design")
        #expect(record.customMetadata.isEmpty)
    }

    @Test("pairs _key with following _val")
    func pairsKeyVal() throws {
        let fields: [DTField] = [
            Self.field("DBID", "db"), Self.field("NAME", "n"), Self.field("PATH", "p"),
            Self.field("TITL", "t"), Self.field("UUID", "u"), Self.field("KIND", "k"),
            Self.field("FILE", "f"),
            Self.field("_key", "mdpkim_id"),
            Self.field("_val", "KN-20260520-0001"),
            Self.field("_key", "mddocrole"),
            Self.field("_val", "knowledge"),
        ]
        let record = try DTRecord.from(fields: fields)
        #expect(record.customMetadata["mdpkim_id"] == "KN-20260520-0001")
        #expect(record.customMetadata["mddocrole"] == "knowledge")
    }

    @Test("orphan _key (followed by another _key) gets empty value")
    func orphanKey() throws {
        let fields: [DTField] = [
            Self.field("DBID", "db"), Self.field("NAME", "n"), Self.field("PATH", "p"),
            Self.field("TITL", "t"), Self.field("UUID", "u"), Self.field("KIND", "k"),
            Self.field("FILE", "f"),
            Self.field("_key", "mdlastmirroredat"),
            Self.field("_key", "mdpkim_id"),
            Self.field("_val", "KN-20260429-0002"),
        ]
        let record = try DTRecord.from(fields: fields)
        #expect(record.customMetadata["mdlastmirroredat"] == "")
        #expect(record.customMetadata["mdpkim_id"] == "KN-20260429-0002")
    }

    @Test("trailing orphan _key still records an empty value")
    func trailingOrphanKey() throws {
        let fields: [DTField] = [
            Self.field("DBID", "db"), Self.field("NAME", "n"), Self.field("PATH", "p"),
            Self.field("TITL", "t"), Self.field("UUID", "u"), Self.field("KIND", "k"),
            Self.field("FILE", "f"),
            Self.field("_key", "mddangling"),
        ]
        let record = try DTRecord.from(fields: fields)
        #expect(record.customMetadata["mddangling"] == "")
    }

    @Test("missing required field throws")
    func missingRequired() {
        let fields: [DTField] = [
            Self.field("DBID", "db"), Self.field("NAME", "n"), // missing PATH, TITL, etc.
        ]
        #expect(throws: DTRecordError.missingRequiredField("PATH")) {
            try DTRecord.from(fields: fields)
        }
    }
}
