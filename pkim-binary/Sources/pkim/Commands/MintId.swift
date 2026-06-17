import ArgumentParser
import Foundation

/// `pkim mint-id` — generate the next PKIM_ID for a given class and date.
///
/// Scans the `.dt` Spotlight cache for the highest existing sequence on
/// `<type>` for `<date>` and returns `max + 1`. The scan is a byte-level
/// search (no TLV parse) — see `MetadataCache.highestSequence`.
///
/// `--sequence` is an explicit override: when supplied, the cache scan
/// is skipped and the supplied value is used as-is. That path exists for
/// recovery scenarios (replaying a known sequence) and for tests.
struct MintId: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mint-id",
        abstract: "Generate the next PKIM_ID for a given class and date."
    )

    @Option(name: .long, help: "Record class: kn, rl, ev, or cl.")
    var type: PKIMClass

    @Option(name: .long, help: "Date in YYYYMMDD form. Defaults to today (UTC).")
    var date: String?

    @Option(
        name: .long,
        help: "Explicit sequence number (1-9999). Skips the cache scan; intended for recovery or test."
    )
    var sequence: Int?

    func run() throws {
        let runId = RunId.generate().value
        do {
            let envelope = try Self.envelope(
                type: type,
                date: date,
                sequence: sequence,
                runId: runId
            )
            writeStdout(try pkimJsonString(envelope))
        } catch let error as PKIMIdError {
            let failure = FailureEnvelope(
                verb: "mint-id",
                runId: runId,
                errorType: "InvalidInput",
                errorMessage: Self.describe(error),
                context: nil
            )
            writeStdout((try? pkimJsonString(failure)) ?? "{}")
            throw ExitCode(PkimExit.invalidInput.rawValue)
        } catch let error as MetadataCacheError {
            let failure = FailureEnvelope(
                verb: "mint-id",
                runId: runId,
                errorType: "IOError",
                errorMessage: "cache scan failed: \(error)",
                context: nil
            )
            writeStdout((try? pkimJsonString(failure)) ?? "{}")
            throw ExitCode(PkimExit.ioError.rawValue)
        }
    }

    /// Pure builder for the success envelope. Factored so unit tests can
    /// inject a `cache` (or skip the scan via an explicit `sequence`).
    static func envelope(
        type: PKIMClass,
        date: String?,
        sequence: Int?,
        runId: String,
        now: Date = Date(),
        cache: MetadataCache = MetadataCache()
    ) throws -> SuccessEnvelope<MintIdPayload> {
        let dateStr = date ?? Self.utcDate(now: now)
        let resolvedSequence: Int
        let warnings: [PkimWarning]
        if let explicit = sequence {
            resolvedSequence = explicit
            warnings = []
        } else {
            let previousMax = try cache.highestSequence(kind: type, date: dateStr)
            resolvedSequence = (previousMax ?? 0) + 1
            warnings = []
        }
        let id = try PKIMId(kind: type, date: dateStr, sequence: resolvedSequence)
        let payload = MintIdPayload(
            pkimId: id,
            type: type,
            date: dateStr,
            sequence: resolvedSequence
        )
        return SuccessEnvelope(verb: "mint-id", runId: runId, data: payload, warnings: warnings)
    }

    private static func utcDate(now: Date) -> String {
        DateUtil.utcDate(now: now)
    }

    private static func describe(_ error: PKIMIdError) -> String {
        switch error {
        case .invalidFormat(let s): return "Invalid PKIM_ID format: \(s)"
        case .unknownClass(let s):  return "Unknown PKIM class: \(s)"
        case .invalidDate(let s):   return "Invalid date (expect YYYYMMDD): \(s)"
        case .invalidSequence(let n): return "Invalid sequence (expect 1-9999): \(n)"
        }
    }
}

/// Payload portion of the `mint-id` envelope. Encodes to:
///
/// ```json
/// { "pkim_id": "KN-20260520-0007", "type": "kn", "date": "20260520", "sequence": 7 }
/// ```
struct MintIdPayload: Encodable, Sendable, Equatable {
    let pkimId: PKIMId
    let type: PKIMClass
    let date: String
    let sequence: Int
}
