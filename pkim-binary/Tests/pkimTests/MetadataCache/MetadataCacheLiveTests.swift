import Foundation
import Testing
@testable import pkim

/// Live integration tests against the user's actual DEVONthink Spotlight
/// metadata cache. Gated by `PKIM_BRIDGE_LIVE=1` so CI / fresh hosts
/// skip them cleanly. See doc 23 §"Test approach".
private var liveEnabled: Bool {
    ProcessInfo.processInfo.environment["PKIM_BRIDGE_LIVE"] == "1"
}

@Suite(".dt cache (live)", .enabled(if: liveEnabled))
struct MetadataCacheLiveTests {

    let cache = MetadataCache()

    @Test("listDatabases returns at least one UUID-named directory")
    func listsDatabases() throws {
        let dbs = try cache.listDatabases()
        #expect(!dbs.isEmpty)
        for db in dbs {
            #expect(MetadataCache.looksLikeUUID(db))
        }
    }

    @Test("findRecord round-trips a known PKIM-Knowledge note")
    func findsKnownRecord() throws {
        // From the offline TLV dump on this branch (record number 1 from
        // db 22734CAB...). If this fails on a future cache rebuild,
        // update the UUID/db to any current pair.
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        let knownDB = "22734CAB-2CE4-4CB4-877C-C24F2D94F337"

        let record = try cache.findRecord(uuid: knownUUID, in: knownDB)
        try #require(record != nil)
        let r = record!
        #expect(r.uuid == knownUUID)
        #expect(r.databaseUUID == knownDB)
        #expect(r.databaseName == "PKIM-Knowledge")
        #expect(r.title == "Purpose Design")
        #expect(r.kind == "Markdown")
        #expect(r.customMetadata["mdpkim_id"] == "KN-20260429-0002")
        #expect(r.customMetadata["mddocrole"] == "knowledge")
        #expect(r.customMetadata["mdreview_state"] == "approved")
        #expect(r.aliases.contains("KN-20260429-0002"))
    }

    @Test("findRecord falls back to scanning all DBs when scope is nil")
    func findsAcrossDBs() throws {
        let knownUUID = "8E91F399-EC90-4E7E-9C4F-147A53EC728C"
        let record = try cache.findRecord(uuid: knownUUID, in: nil)
        #expect(record?.uuid == knownUUID)
    }

    @Test("invalid UUID throws cleanly")
    func invalidUUIDThrows() {
        #expect(throws: MetadataCacheError.invalidUUID("not-a-uuid")) {
            try cache.findRecord(uuid: "not-a-uuid", in: nil)
        }
    }
}
