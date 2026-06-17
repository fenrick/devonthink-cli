import ArgumentParser
import Foundation

/// `pkim search <db> [--field K=V]… [--text Q] [--limit N]` — find
/// records matching one or more criteria.
///
/// Backed by `mdfind` (CoreServices) rather than DT's scripting
/// `search` verb. Two reasons:
///   - Spotlight indexes DT's custom metadata as
///     `com_DEVONtechnologies_think_md<key>` attributes; field
///     predicates compile to fast attribute queries.
///   - The sdp-generated `searchComparison` binding drops the
///     query-string direct parameter (sbhc.py corner case), so
///     the typed SB path is incomplete for free-text search.
///
/// Each `--field K=V` becomes an mdfind predicate
/// `com_DEVONtechnologies_think_md<K> == "V"`. `--text Q` becomes a
/// `kMDItemTextContent == "Q*"` clause. All clauses are AND-ed plus
/// a database scope (`com_DEVONtechnologies_think_DatabaseName == "<db>"`).
///
/// Returns each hit's PKIM_ID, DT UUID, and name. For richer
/// details, callers pipe each UUID into `pkim get`.
struct Search: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search records by custom-metadata field and/or text content."
    )

    @Argument(help: "Database name to scope the search.")
    var database: String

    @Option(name: .long, help: "Field predicate as KEY=VALUE (repeatable). KEY is matched as `mdKEY` against DT's Spotlight-indexed custom-metadata attribute.")
    var field: [String] = []

    @Option(name: .long, help: "Free-text content prefix to match (uses kMDItemTextContent).")
    var text: String?

    @Option(name: .long, help: "Cap the result set. 0 = no cap.")
    var limit: Int = 0

    func run() throws {
        try CommandSupport.runReadVerb(named: "search") {
            guard !database.isEmpty else { throw PkimError.invalidInput("database is required") }

            // Build the mdfind query.
            var clauses: [String] = [
                "com_DEVONtechnologies_think_DatabaseName == \"\(database)\""
            ]
            for predicate in field {
                let (key, value) = try Self.parseFieldPredicate(predicate)
                clauses.append("com_DEVONtechnologies_think_md\(key) == \"\(value)\"")
            }
            if let text, !text.isEmpty {
                clauses.append("kMDItemTextContent == \"\(text)*\"")
            }
            let query = clauses.joined(separator: " && ")

            let paths: [String]
            do {
                paths = try MetadataCache.mdfind(query: query)
            } catch {
                throw PkimError.io("mdfind failed: \(error.localizedDescription)")
            }

            // For each matched .dt file, read just enough to populate
            // a SearchEntry. We use the cache parser (sub-millisecond
            // per record) since search results don't need live-fresh
            // data — they're a discovery surface, not a write-path.
            let cache = MetadataCache()
            var rows: [SearchEntry] = []
            for path in paths {
                if limit > 0, rows.count >= limit { break }
                let url = URL(fileURLWithPath: path)
                guard let record = try? cache.readRecord(at: url) else { continue }
                rows.append(SearchEntry(
                    pkimId: record.customMetadata["mdpkim_id"] ?? "",
                    dtUuid: record.uuid,
                    name: record.title,
                    recordType: record.kind,
                    docRole: record.customMetadata["mddocrole"] ?? "",
                    reviewState: record.customMetadata["mdreview_state"] ?? "",
                    itemLink: "\(RecordRef.itemLinkScheme)\(record.uuid)"
                ))
            }

            return SearchPayload(
                database: database,
                query: query,
                matched: paths.count,
                returned: rows.count,
                records: rows
            )
        }
    }

    static func parseFieldPredicate(_ raw: String) throws -> (key: String, value: String) {
        guard let eq = raw.firstIndex(of: "=") else {
            throw PkimError.invalidInput(
                "expected --field KEY=VALUE, got: \(raw)",
                context: ["field": raw]
            )
        }
        let key = String(raw[..<eq])
        let value = String(raw[raw.index(after: eq)...])
        guard !key.isEmpty else {
            throw PkimError.invalidInput("empty key in --field \(raw)")
        }
        return (key, value)
    }
}

struct SearchEntry: Encodable, Sendable, Equatable {
    let pkimId: String
    let dtUuid: String
    let name: String
    let recordType: String
    let docRole: String
    let reviewState: String
    let itemLink: String
}

struct SearchPayload: Encodable, Sendable {
    let database: String
    let query: String
    let matched: Int
    let returned: Int
    let records: [SearchEntry]
}
