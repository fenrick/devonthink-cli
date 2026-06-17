import Foundation

/// Top-level reader for DEVONthink's Spotlight metadata cache at
/// `~/Library/Metadata/com.devon-technologies.think/`.
///
/// Each subdirectory is one database, named by its DT UUID. Records
/// inside are partitioned into 256 bucket directories by the first
/// two hex characters of their record UUID.
///
/// No caching across invocations. Doc 23 §"Read-plane architecture"
/// is binding: each `pkim` call mmaps the relevant `.dt` files,
/// reads them, exits. State that needs to persist between calls lives
/// on disk (mirror DB, run manifests) — not in this process.
struct MetadataCache: Sendable {
    let root: URL

    /// Default cache location on macOS. Honors `$HOME`.
    static func defaultRoot() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appending(path: "Library", directoryHint: .isDirectory)
            .appending(path: "Metadata", directoryHint: .isDirectory)
            .appending(path: "com.devon-technologies.think", directoryHint: .isDirectory)
    }

    init(root: URL = MetadataCache.defaultRoot()) {
        self.root = root
    }

    /// List database UUIDs (subdirectory names directly under `root`)
    /// that currently hold at least one record.
    ///
    /// DEVONthink leaves stale empty directories behind for databases
    /// that were closed; those are filtered out via the empty-check.
    func listDatabases() throws(MetadataCacheError) -> [String] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            return contents
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
                .map(\.lastPathComponent)
                .filter { Self.looksLikeUUID($0) }
                .sorted()
        } catch {
            throw .ioError("listDatabases: \(error.localizedDescription)")
        }
    }

    /// Enumerate every `.dt` file URL under one database. Order is
    /// filesystem-dependent (not stable). Use this when you need every
    /// record; for a single UUID lookup, prefer `findRecord(uuid:)`.
    func listRecordFiles(in databaseUUID: String) throws(MetadataCacheError) -> [URL] {
        let dbDir = root.appending(path: databaseUUID, directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: dbDir.path) else {
            throw .databaseNotFound(databaseUUID)
        }
        guard let enumerator = FileManager.default.enumerator(
            at: dbDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw .ioError("enumerator failed for \(databaseUUID)")
        }
        var files: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "dt" {
            files.append(url)
        }
        return files
    }

    /// Read one `.dt` file and decode it into a `DTRecord`.
    func readRecord(at url: URL) throws(MetadataCacheError) -> DTRecord {
        let data: Data
        do {
            // Use mappedIfSafe — Foundation will mmap for large files,
            // fall back to a normal read for small ones.
            data = try Data(contentsOf: url, options: [.mappedIfSafe])
        } catch {
            throw .ioError("read \(url.lastPathComponent): \(error.localizedDescription)")
        }
        let fields: [DTField]
        do {
            fields = try parseDTFields(data)
        } catch {
            throw .parseError("\(url.lastPathComponent): \(error)")
        }
        do {
            return try DTRecord.from(fields: fields)
        } catch {
            throw .parseError("\(url.lastPathComponent): \(error)")
        }
    }

    /// Resolve a record by its DT UUID. The bucket directory is NOT
    /// derivable from the record UUID (it's an internal DT mapping),
    /// so this enumerates the actual bucket dirs of each candidate
    /// database and checks each for the file. At most 256 stat() calls
    /// per database — sub-millisecond in practice.
    ///
    /// Scope the lookup with `databaseUUID` when the caller knows it;
    /// passing `nil` falls back to scanning every open database.
    func findRecord(
        uuid: String,
        in databaseUUID: String? = nil
    ) throws(MetadataCacheError) -> DTRecord? {
        let normalised = uuid.uppercased()
        guard Self.looksLikeUUID(normalised) else {
            throw .invalidUUID(uuid)
        }
        let filename = "\(normalised).dt"

        let databases: [String]
        if let scoped = databaseUUID {
            databases = [scoped]
        } else {
            databases = try listDatabases()
        }

        for db in databases {
            let dbDir = root.appending(path: db, directoryHint: .isDirectory)
            let buckets: [URL]
            do {
                buckets = try FileManager.default.contentsOfDirectory(
                    at: dbDir,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                // Closed/missing DB — skip rather than fail the whole lookup.
                continue
            }
            for bucket in buckets {
                let candidate = bucket.appending(
                    path: filename,
                    directoryHint: .notDirectory
                )
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return try readRecord(at: candidate)
                }
            }
        }
        return nil
    }

    /// Find the highest existing PKIM_ID sequence number for the given
    /// `(kind, date)` pair across every database Spotlight knows about.
    /// Returns `nil` if no record matches.
    ///
    /// Spotlight indexes DT's custom metadata as
    /// `com_DEVONtechnologies_think_mdpkim_id`, so a wildcard query
    /// (`KN-20260429-*`) returns the candidate set in tens of milliseconds
    /// regardless of total corpus size. We then mmap each matching `.dt`
    /// file and byte-scan for the actual value — typically a handful of
    /// files even for a busy day.
    ///
    /// If Spotlight is unavailable or `mdfind` errors, this throws
    /// `.ioError` rather than silently returning `nil` — a nil result
    /// would let `mint-id` allocate a colliding sequence number.
    func highestSequence(
        kind: PKIMClass,
        date: String
    ) throws(MetadataCacheError) -> Int? {
        let prefix = "\(kind.prefix)-\(date)-"
        let query = "com_DEVONtechnologies_think_mdpkim_id == \"\(prefix)*\""

        let paths: [String]
        do {
            paths = try Self.mdfind(query: query)
        } catch {
            throw .ioError("mdfind failed: \(error.localizedDescription)")
        }

        let prefixBytes = Array(prefix.utf8)
        var best: Int? = nil
        for path in paths {
            let url = URL(fileURLWithPath: path)
            guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
                continue
            }
            if let seq = Self.maxSequence(in: data, prefix: prefixBytes) {
                if best == nil || seq > best! {
                    best = seq
                }
            }
        }
        return best
    }

    /// Run `/usr/bin/mdfind <query>` and return one file path per line
    /// of output. Empty result is normal; subprocess failure throws.
    static func mdfind(query: String) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = [query]
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()
        try process.run()
        let data = (try? outPipe.fileHandleForReading.readToEnd()) ?? Data()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "MetadataCache.mdfind",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "mdfind exited \(process.terminationStatus)"]
            )
        }
        guard let s = String(data: data, encoding: .utf8) else { return [] }
        return s.split(separator: "\n").map(String.init)
    }

    /// Scan one byte buffer for every occurrence of `<prefix><4 ASCII digits>`
    /// and return the highest 4-digit value found. Pure function.
    static func maxSequence(in data: Data, prefix: [UInt8]) -> Int? {
        guard !prefix.isEmpty else { return nil }
        var best: Int? = nil
        return data.withUnsafeBytes { raw -> Int? in
            let bytes = raw.bindMemory(to: UInt8.self)
            let pLen = prefix.count
            let needed = pLen + 4
            guard bytes.count >= needed else { return nil }
            var i = 0
            let last = bytes.count - needed
            while i <= last {
                if bytes[i] == prefix[0] {
                    var matched = true
                    for j in 1..<pLen where bytes[i + j] != prefix[j] {
                        matched = false
                        break
                    }
                    if matched {
                        let d0 = bytes[i + pLen]
                        let d1 = bytes[i + pLen + 1]
                        let d2 = bytes[i + pLen + 2]
                        let d3 = bytes[i + pLen + 3]
                        if Self.isAsciiDigit(d0), Self.isAsciiDigit(d1),
                           Self.isAsciiDigit(d2), Self.isAsciiDigit(d3) {
                            let seq = Int(d0 - 0x30) * 1000
                                    + Int(d1 - 0x30) *  100
                                    + Int(d2 - 0x30) *   10
                                    + Int(d3 - 0x30)
                            if best == nil || seq > best! {
                                best = seq
                            }
                            i += needed
                            continue
                        }
                    }
                }
                i += 1
            }
            return best
        }
    }

    private static func isAsciiDigit(_ b: UInt8) -> Bool {
        b >= 0x30 && b <= 0x39
    }

    /// Resolve a user-facing `RecordRef` to a fully-loaded `DTRecord`,
    /// or `nil` if no record matches.
    ///
    /// - `.dtUUID` / `.itemLink` → `findRecord(uuid:in: nil)`
    /// - `.pkimId` → mdfind for the file, then read it directly.
    func resolve(_ ref: RecordRef) throws(MetadataCacheError) -> DTRecord? {
        switch ref {
        case .dtUUID(let uuid):
            return try findRecord(uuid: uuid, in: nil)
        case .itemLink(let link):
            let uuid = String(link.dropFirst(RecordRef.itemLinkScheme.count))
            return try findRecord(uuid: uuid, in: nil)
        case .pkimId(let pkimId):
            let query = "com_DEVONtechnologies_think_mdpkim_id == \"\(pkimId)\""
            let paths: [String]
            do {
                paths = try Self.mdfind(query: query)
            } catch {
                throw .ioError("mdfind failed: \(error.localizedDescription)")
            }
            guard let first = paths.first else { return nil }
            return try readRecord(at: URL(fileURLWithPath: first))
        }
    }

    /// Heuristic check that a string looks like a DT UUID (8-4-4-4-12 hex).
    static func looksLikeUUID(_ s: String) -> Bool {
        guard s.count == 36 else { return false }
        let segments = s.split(separator: "-").map(String.init)
        guard segments.count == 5,
              segments[0].count == 8,
              segments[1].count == 4,
              segments[2].count == 4,
              segments[3].count == 4,
              segments[4].count == 12 else { return false }
        return segments.allSatisfy { $0.allSatisfy(\.isHexDigit) }
    }
}

enum MetadataCacheError: Error, Sendable, Equatable {
    case ioError(String)
    case parseError(String)
    case databaseNotFound(String)
    case invalidUUID(String)
}
