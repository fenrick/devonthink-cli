import Foundation

/// Shared text helpers. Centralised so `body`, `extract-text`, and any
/// future verb that returns text counts the same way.
enum TextUtil {

    /// Whitespace-and-newline-separated word count.
    static func wordCount(of text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
