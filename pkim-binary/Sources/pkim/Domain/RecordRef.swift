import Foundation

/// User-facing reference to a record. Accepts three forms:
///
/// - **PKIM_ID** — `"KN-20260520-0007"` (matched via Spotlight on
///   `com_DEVONtechnologies_think_mdpkim_id`).
/// - **DT UUID** — `"8E91F399-EC90-4E7E-9C4F-147A53EC728C"` (used
///   directly).
/// - **Item link** — `"x-devonthink-item://8E91F399-..."` (UUID is
///   extracted from the suffix).
///
/// Resolution to a concrete `.dt` file is `MetadataCache.resolve(_:)`.
enum RecordRef: Sendable, Equatable {
    case pkimId(String)
    case dtUUID(String)
    case itemLink(String)

    /// Parse a raw string into the most specific shape it matches.
    /// Anything that isn't a DT UUID or an item link is treated as a
    /// PKIM_ID candidate — actual validation happens at resolve time.
    static func parse(_ raw: String) -> RecordRef {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix(Self.itemLinkScheme) {
            return .itemLink(trimmed)
        }
        if MetadataCache.looksLikeUUID(trimmed) {
            return .dtUUID(trimmed.uppercased())
        }
        return .pkimId(trimmed)
    }

    static let itemLinkScheme = "x-devonthink-item://"

    /// Source string, useful for error messages.
    var raw: String {
        switch self {
        case .pkimId(let s), .dtUUID(let s), .itemLink(let s): return s
        }
    }
}
