import Foundation

/// Run identifier for a single `pkim` invocation.
///
/// Format: `<rfc3339-timestamp>-<6-hex>`, with colons in the timestamp
/// replaced by dashes so the value is filesystem-safe (used as a
/// directory name under `runs/`). Sortable by string compare.
///
/// See doc 23 §"Run manifests".
struct RunId: Sendable, Equatable {
    let value: String

    /// Generate a fresh `RunId` using the current wall-clock time and
    /// 6 random hex characters of suffix.
    static func generate(now: Date = Date()) -> RunId {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter.string(from: now).replacingOccurrences(of: ":", with: "-")
        let hex = Self.randomHex(length: 6)
        return RunId(value: "\(stamp)-\(hex)")
    }

    private static func randomHex(length: Int) -> String {
        let alphabet: [Character] = Array("0123456789abcdef")
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }
}
