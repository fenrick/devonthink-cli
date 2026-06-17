import ArgumentParser
import Foundation

/// Closed set of PKIM record classes. See `docs/design/00-source-reconciliation.md`
/// §"`PKIM_ID` format".
enum PKIMClass: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case ev
    case kn
    case rl
    case cl

    /// Uppercase form used as the prefix in a formatted `PKIM_ID`.
    var prefix: String { rawValue.uppercased() }
}

extension PKIMClass: ExpressibleByArgument {
    init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}

/// Canonical PKIM identifier: `<CLASS>-<YYYYMMDD>-<NNNN>` with the
/// sequence counter scoped to that date and class.
///
/// Roundtrips through JSON as a single string (e.g. `"KN-20260520-0007"`)
/// rather than a structured object — that's the contract every other
/// system reading a PKIM_ID expects.
struct PKIMId: Sendable, Equatable, Hashable {
    let kind: PKIMClass
    let date: String     // YYYYMMDD
    let sequence: Int    // 1...9999

    init(kind: PKIMClass, date: String, sequence: Int) throws(PKIMIdError) {
        guard Self.isValidDate(date) else {
            throw .invalidDate(date)
        }
        guard (1...9999).contains(sequence) else {
            throw .invalidSequence(sequence)
        }
        self.kind = kind
        self.date = date
        self.sequence = sequence
    }

    /// Render in canonical `KN-20260520-0007` form.
    var formatted: String {
        let seq = String(format: "%04d", sequence)
        return "\(kind.prefix)-\(date)-\(seq)"
    }

    /// Parse a canonical-form string back into a `PKIMId`.
    static func parse(_ string: String) throws(PKIMIdError) -> PKIMId {
        let parts = string.split(separator: "-")
        guard parts.count == 3 else {
            throw .invalidFormat(string)
        }
        guard let kind = PKIMClass(rawValue: String(parts[0]).lowercased()) else {
            throw .unknownClass(String(parts[0]))
        }
        guard let sequence = Int(parts[2]) else {
            throw .invalidFormat(string)
        }
        return try PKIMId(kind: kind, date: String(parts[1]), sequence: sequence)
    }

    private static func isValidDate(_ s: String) -> Bool {
        guard s.count == 8 else { return false }
        return s.allSatisfy(\.isASCII) && s.allSatisfy(\.isNumber)
    }
}

extension PKIMId: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        do {
            self = try PKIMId.parse(raw)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid PKIM_ID: \(raw)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(formatted)
    }
}

enum PKIMIdError: Error, Equatable, Sendable {
    case invalidFormat(String)
    case unknownClass(String)
    case invalidDate(String)
    case invalidSequence(Int)
}
