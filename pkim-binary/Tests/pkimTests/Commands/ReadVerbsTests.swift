import Foundation
import Testing
@testable import pkim

@Suite("file-path isIndexed heuristic")
struct FilePathTests {

    @Test("imported records (inside .dtBase2/Files.noindex) report is_indexed=false")
    func importedIsFalse() {
        // Use the real home directory so the tilde expansion in
        // FilePath.isIndexed actually matches the file-path prefix.
        let home = NSString(string: "~").expandingTildeInPath
        let result = FilePath.isIndexed(
            filePath: "\(home)/Databases/PKIM/PKIM-Knowledge.dtBase2/Files.noindex/md/1/Note.md",
            databasePath: "~/Databases/PKIM/PKIM-Knowledge.dtBase2"
        )
        #expect(result == false)
    }

    @Test("indexed records (outside the package) report is_indexed=true")
    func indexedIsTrue() {
        let home = NSString(string: "~").expandingTildeInPath
        let result = FilePath.isIndexed(
            filePath: "\(home)/Notes/some-file.md",
            databasePath: "~/Databases/PKIM/PKIM-Knowledge.dtBase2"
        )
        #expect(result == true)
    }

    @Test("expands tilde in databasePath before comparing")
    func expandsTilde() {
        // The database path commonly arrives in `~/Databases/…` form.
        // If we forget to expand it, the prefix check fails for every
        // record and we wrongly call imported records "indexed".
        let home = NSString(string: "~").expandingTildeInPath
        let result = FilePath.isIndexed(
            filePath: "\(home)/Databases/PKIM/PKIM-Knowledge.dtBase2/Files.noindex/md/1/N.md",
            databasePath: "~/Databases/PKIM/PKIM-Knowledge.dtBase2"
        )
        #expect(result == false)
    }
}

// MARK: - Live integration

private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite("read verbs (live)", .enabled(if: liveEnabled))
struct ReadVerbsLiveTests {

    let cache = MetadataCache()

    @Test("resolve via PKIM_ID returns a record from the right database")
    func resolvePkimId() throws {
        let ref = RecordRef.parse("KN-20260429-0002")
        let record = try cache.resolve(ref)
        try #require(record != nil)
        #expect(record!.databaseName == "PKIM-Knowledge")
        #expect(record!.customMetadata["mdpkim_id"] == "KN-20260429-0002")
    }

    @Test("resolve via DT UUID returns the same record")
    func resolveByUUID() throws {
        let ref = RecordRef.parse("8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        let record = try cache.resolve(ref)
        try #require(record != nil)
        #expect(record!.uuid == "8E91F399-EC90-4E7E-9C4F-147A53EC728C")
    }

    @Test("resolve via item link strips the scheme")
    func resolveByItemLink() throws {
        let ref = RecordRef.parse("x-devonthink-item://8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        let record = try cache.resolve(ref)
        try #require(record != nil)
        #expect(record!.uuid == "8E91F399-EC90-4E7E-9C4F-147A53EC728C")
    }

    @Test("resolve returns nil for a non-existent PKIM_ID")
    func resolveMissing() throws {
        let ref = RecordRef.parse("KN-99999999-0001")
        let record = try cache.resolve(ref)
        #expect(record == nil)
    }

    @Test("GetPayload exposes derived fields correctly")
    func getPayloadShape() throws {
        let ref = RecordRef.parse("KN-20260429-0002")
        let record = try cache.resolve(ref)
        try #require(record != nil)
        let payload = GetPayload(from: record!)
        #expect(payload.pkimId == "KN-20260429-0002")
        #expect(payload.dtUuid == "8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        #expect(payload.name == "Purpose Design")
        #expect(payload.docRole == "knowledge")
        #expect(payload.reviewState == "approved")
        #expect(payload.itemLink == "x-devonthink-item://8E91F399-EC90-4E7E-9C4F-147A53EC728C")
        #expect(payload.isIndexed == false)
        #expect(payload.filename == "Purpose Design.md")
        #expect(payload.aliases.contains("KN-20260429-0002"))
    }
}
