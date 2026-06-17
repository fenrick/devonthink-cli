import Foundation

/// Shared date helpers. Centralised so `mint-id` and `create-note`
/// produce identical YYYYMMDD strings.
enum DateUtil {

    /// Render `now` as a UTC `YYYYMMDD` string (8 chars, zero-padded).
    /// Defaults to the current wall-clock time.
    static func utcDate(now: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        return String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
