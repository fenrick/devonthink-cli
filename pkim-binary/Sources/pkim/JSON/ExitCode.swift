import Foundation

/// Exit codes for the `pkim` binary. See doc 23 §"Exit codes".
///
/// Named `PkimExit` rather than `ExitCode` to avoid clashing with
/// `ArgumentParser.ExitCode`. Each verb that fails maps its
/// `error_type` envelope field to one of these codes.
enum PkimExit: Int32, Sendable, Equatable {
    case success = 0
    case usageError = 1
    case invalidInput = 2
    case devonthinkUnreachable = 3
    case partialFailure = 4
    case ioError = 5
    case internalError = 99
}

/// PKIM error type whose `errorType` string and exit code are
/// always paired with one of the `PkimExit` cases. Verbs throw this
/// when they cannot fulfil their contract; the root command catches it
/// at the boundary, emits a `FailureEnvelope`, and exits with `code`.
enum PkimError: Error, Sendable {
    case usage(String)
    case invalidInput(String, context: [String: String]? = nil)
    case devonthinkUnreachable(String)
    case partialFailure(String, context: [String: String]? = nil)
    case io(String)
    case `internal`(String)

    var exitCode: PkimExit {
        switch self {
        case .usage: return .usageError
        case .invalidInput: return .invalidInput
        case .devonthinkUnreachable: return .devonthinkUnreachable
        case .partialFailure: return .partialFailure
        case .io: return .ioError
        case .internal: return .internalError
        }
    }

    var errorType: String {
        switch self {
        case .usage: return "UsageError"
        case .invalidInput: return "InvalidInput"
        case .devonthinkUnreachable: return "DEVONthinkUnreachable"
        case .partialFailure: return "PartialFailure"
        case .io: return "IOError"
        case .internal: return "InternalError"
        }
    }

    var message: String {
        switch self {
        case .usage(let m),
             .invalidInput(let m, _),
             .devonthinkUnreachable(let m),
             .partialFailure(let m, _),
             .io(let m),
             .internal(let m):
            return m
        }
    }

    var context: [String: String]? {
        switch self {
        case .invalidInput(_, let c), .partialFailure(_, let c):
            return c
        default:
            return nil
        }
    }
}
