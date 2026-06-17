import Foundation
import ScriptingBridge

/// Typed handle to DEVONthink via ScriptingBridge.
///
/// Uses the protocols generated from DT's `.sdef` by SwiftScripting
/// (see `Sources/pkim/Bridge/Generated/`). Compared to the earlier
/// KVC-based shim, this gives us:
///
/// - Compile-time checking on method names and signatures.
/// - No `valueForUndefinedKey:` crashes on properties that aren't
///   KVC-compliant (e.g. `record.type`, `record.uuid`).
/// - No runtime sdef parse on first SB call — the protocols ARE the
///   glue, so `SBApplication.init` skips `dynamicMojo`. ~30–50 ms
///   wall-clock saved per cold invocation.
///
/// Construction is cheap — `SBApplication(bundleIdentifier:)` does
/// not launch DT and does not dispatch any Apple Event. Apple Events
/// fire on first property access.
///
/// Not `Sendable`: holds a class reference. Each verb is one-shot
/// and stays on one thread.
struct DTBridge {
    /// DEVONthink bundle identifier. Stable across DT 3 and 4.
    static let bundleId = "com.devon-technologies.think"

    let app: DEVONthinkApplication

    enum ConnectError: Error, Sendable {
        case scriptingBridgeUnavailable
        case appNotInstalled(bundleId: String)
    }

    static func connect(bundleId: String = DTBridge.bundleId) throws -> DTBridge {
        guard let sbApp = SBApplication(bundleIdentifier: bundleId) else {
            throw ConnectError.appNotInstalled(bundleId: bundleId)
        }
        // SBApplication conforms to DEVONthinkApplication via an extension
        // generated alongside the protocol; the as! is safe here.
        return DTBridge(app: sbApp as DEVONthinkApplication)
    }

    /// Whether DT is currently running. Non-launching.
    var isRunning: Bool {
        app.isRunning
    }

    var name: String {
        app.name ?? ""
    }

    var version: String {
        app.version ?? ""
    }

    /// All open databases as typed `DEVONthinkDatabase` proxies.
    func databases() -> [DEVONthinkDatabase] {
        guard let arr = app.databases?() else { return [] }
        return arr.compactMap { $0 as? DEVONthinkDatabase }
    }

    /// Resolve a record by its DT UUID. Pass a `database` for a scoped
    /// lookup, or `nil` to scan across all open databases.
    func record(uuid: String, in database: DEVONthinkDatabase? = nil) -> DEVONthinkRecord? {
        guard let result = app.getRecordWithUuid?(uuid, in: database) else { return nil }
        return result as? DEVONthinkRecord
    }
}

// MARK: - SB value resolution

/// Force-resolve a `Any?` property that may come back as a lazy
/// `SBObject` specifier rather than a concrete value. DT's sdef
/// declares several text-typed properties (`uuid`, `location`,
/// `referenceURL`, `path`, `plainText`, `kind`) as `text`, which
/// Swift binds as `Any` — some runtime call paths return resolved
/// strings, others return `SBObject` specifiers that need `.get()`.
///
/// Cast to the concrete `SBObject` class rather than `SBObjectProtocol`:
/// a concrete-class cast is a simple isa check (~ns), while a protocol
/// cast walks the witness table and measured ~2 ms slower per 4-property
/// read in the bridge bench.
@inline(__always)
func resolvedString(_ raw: Any?) -> String {
    if let s = raw as? String { return s }
    if let obj = raw as? SBObject {
        return "\(obj.get() ?? "")"
    }
    return ""
}

/// Force-resolve an `Any?` that may be a `[String]` or an `SBObject`
/// wrapping one. Used by `record.tags` and similar array-typed
/// accessors.
@inline(__always)
func resolvedStringArray(_ raw: Any?) -> [String] {
    if let arr = raw as? [String] { return arr }
    if let obj = raw as? SBObject, let arr = obj.get() as? [String] { return arr }
    return []
}

// MARK: - Custom metadata read / write

/// Atomic per-key read/write for a record's customMetaData.
///
/// Backed by DT's application-level scripting verbs:
///
/// - `getCustomMetaDataDefaultValue(default:for:from:)` — read a single
///   key. The default value is a sentinel we use to distinguish "absent"
///   from a real empty value.
/// - `addCustomMetaData(value:for:to:as:)` — set/update a single key.
///   Auto-registers keys not yet in DT's custom-metadata schema (the
///   docstring promises this; the live probe confirmed it works without
///   the NSUnknownKeyException that bit the KVC path).
/// - Clearing a key is `addCustomMetaData("", for: …)` — DT removes the
///   key when given an empty string. Confirmed by the live probe.
///
/// Why this shape over a read-modify-write whole-dict path:
/// we never read or write the other keys, so date-typed fields like
/// `mdlastprofiledat` can't be silently corrupted by string coercion.
/// The type-preservation hazard from the earlier `applyDeltas` shape
/// is structurally eliminated.
///
/// Caveat: `addCustomMetaData` coerces the supplied value to a string
/// (we saw `NSNumber(42)` arrive as `"42"` in the live probe). PKIM
/// fields are all strings on the write side, so this matches what the
/// caller wants; if a future use case needed to preserve a non-string
/// type, switch that one field to the whole-dict path.
enum DTCustomMetadata {

    /// Sentinel value used as the `default` arg to
    /// `getCustomMetaDataDefaultValue`. Chosen to be something no real
    /// field would ever hold; if DT returns the sentinel, we know the
    /// key is absent from the record's metadata.
    private static let absentSentinel = "\u{0}pkim_absent\u{0}"

    /// Read a single key. Returns nil if the field is absent on the
    /// record; returns the (possibly empty) string value otherwise.
    static func read(_ record: DEVONthinkRecord, key: String, bridge: DTBridge) -> String? {
        let raw = bridge.app.getCustomMetaDataDefaultValue?(absentSentinel, for: key, from: record)
        guard let value = raw as? String else { return nil }
        return value == absentSentinel ? nil : value
    }

    /// Read the entire customMetaData dictionary. Kept for cases where
    /// the caller really wants the whole picture (audits, dossiers).
    /// Lossy: NSDate-typed values come back as their default string
    /// description. Force-resolves the lazy SBObject specifier.
    static func readAll(_ record: DEVONthinkRecord) -> [String: String] {
        let resolved = resolveDictionary(record.customMetaData)
        var out: [String: String] = [:]
        for (key, value) in resolved {
            out[key] = "\(value)"
        }
        return out
    }

    /// Set or update one key atomically. Pass an empty string to clear.
    @discardableResult
    static func write(_ record: DEVONthinkRecord, key: String, value: String, bridge: DTBridge) -> Bool {
        bridge.app.addCustomMetaData?(value, for: key, to: record, as: nil)
        return true
    }

    /// Clear one key. Equivalent to `write(record, key, value: "")`.
    @discardableResult
    static func clear(_ record: DEVONthinkRecord, key: String, bridge: DTBridge) -> Bool {
        bridge.app.addCustomMetaData?("", for: key, to: record, as: nil)
        return true
    }

    /// Force-resolve the lazy SB specifier into a Swift dict.
    private static func resolveDictionary(_ raw: Any?) -> [String: Any] {
        if let dict = raw as? [String: Any] { return dict }
        if let obj = raw as? SBObject,
           let resolved = obj.get() as? [String: Any] {
            return resolved
        }
        return [:]
    }
}

// MARK: - Database / Record property accessors

enum DTDatabaseAccess {
    static func name(_ db: DEVONthinkDatabase) -> String { db.name ?? "" }
    static func uuid(_ db: DEVONthinkDatabase) -> String { resolvedString(db.uuid) }
    static func path(_ db: DEVONthinkDatabase) -> String { resolvedString(db.path) }
    static func records(_ db: DEVONthinkDatabase) -> [DEVONthinkRecord] {
        // DEVONthinkDatabase doesn't expose `records()` directly — DT
        // organises a database as a tree of children/contents. The
        // bench uses this only to find a sample record; reach for the
        // database root via the typed `contents()` element array.
        guard let arr = db.contents?() else { return [] }
        return arr.compactMap { $0 as? DEVONthinkRecord }
    }
}

enum DTRecordAccess {
    static func name(_ rec: DEVONthinkRecord) -> String { rec.name ?? "" }
    static func uuid(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.uuid) }
    static func location(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.location) }
    static func referenceURL(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.referenceURL) }
    static func kind(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.kind) }
    static func path(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.path) }
    static func plainText(_ rec: DEVONthinkRecord) -> String { resolvedString(rec.plainText) }
    static func tags(_ rec: DEVONthinkRecord) -> [String] { resolvedStringArray(rec.tags) }

    /// Force-resolve `record.database`, handling the typed value /
    /// SBObject specifier dual return. Records always have a database
    /// in DT, so this returns `nil` only when SB itself fails to
    /// resolve the specifier — practically unreachable.
    static func database(_ rec: DEVONthinkRecord) -> DEVONthinkDatabase? {
        if let db = rec.database as? DEVONthinkDatabase { return db }
        if let obj = rec.database as? SBObject,
           let resolved = obj.get() as? DEVONthinkDatabase {
            return resolved
        }
        return nil
    }
}
