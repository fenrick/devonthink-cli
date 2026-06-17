import Foundation

/// Standard success envelope. See `docs/design/23-swift-pkim-binary.md`
/// §"Standard JSON envelope (success)".
///
/// Encoded with snake_case key strategy, so `runId` becomes `run_id`.
struct SuccessEnvelope<Payload: Encodable & Sendable>: Encodable, Sendable {
    let ok: Bool
    let verb: String
    let runId: String
    let data: Payload
    let warnings: [PkimWarning]

    init(verb: String, runId: String, data: Payload, warnings: [PkimWarning] = []) {
        self.ok = true
        self.verb = verb
        self.runId = runId
        self.data = data
        self.warnings = warnings
    }
}

/// Standard failure envelope. See doc 23 §"Standard JSON envelope (failure)".
struct FailureEnvelope: Encodable, Sendable {
    let ok: Bool
    let verb: String
    let runId: String
    let errorType: String
    let errorMessage: String
    let context: [String: String]?

    init(
        verb: String,
        runId: String,
        errorType: String,
        errorMessage: String,
        context: [String: String]? = nil
    ) {
        self.ok = false
        self.verb = verb
        self.runId = runId
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.context = context
    }
}

/// Non-fatal warning attached to a success envelope. Doc 23 uses these
/// for things like stale-read fallbacks on the cache plane.
struct PkimWarning: Codable, Sendable, Equatable {
    let code: String
    let message: String
}

/// Encoder configured for the PKIM JSON envelope. Snake-case keys,
/// pretty output disabled (one line per envelope so streaming consumers
/// can split by newline).
func pkimEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return encoder
}

/// Encode any value to a UTF-8 JSON string using `pkimEncoder()`.
func pkimJsonString<T: Encodable>(_ value: T) throws -> String {
    let bytes = try pkimEncoder().encode(value)
    guard let string = String(data: bytes, encoding: .utf8) else {
        throw PkimError.internal("UTF-8 encode failed")
    }
    return string
}

/// Write a string to stdout followed by a newline. Used for the single
/// JSON envelope every verb prints. Diagnostic output should not use
/// this channel — see `os.Logger` for that.
func writeStdout(_ string: String) {
    let line = string + "\n"
    if let data = line.data(using: .utf8) {
        FileHandle.standardOutput.write(data)
    }
}
