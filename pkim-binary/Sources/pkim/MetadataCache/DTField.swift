import Foundation

/// Variant of a TLV field in a DEVONthink Spotlight metadata file.
enum DTFieldKind: Sendable, Equatable {
    /// `DTst` — variable-length, length-prefixed text or binary payload.
    /// Used for most fields including all named record properties and
    /// `_key`/`_val` custom metadata pairs.
    case stringLike
    /// `DTda` — fixed 8-byte payload (CFAbsoluteTime big-endian double).
    /// Used for record `CREA`/`MODI` timestamps and date-typed custom
    /// metadata values.
    case date
}

/// One TLV field inside a DEVONthink Spotlight metadata file (`*.dt`).
///
/// Two on-wire layouts coexist; see `DTFieldKind`. `DTst`:
/// ```
/// 0..4    "DTst" magic
/// 4..8    4-byte ASCII tag (e.g. "NAME", "UUID", "_key", "UTI ")
/// 8..12   big-endian uint32 length
/// 12..16  4 reserved bytes (observed always zero)
/// 16..    payload of `length` bytes
/// ```
/// `DTda`:
/// ```
/// 0..4    "DTda" magic
/// 4..8    4-byte ASCII tag (e.g. "CREA", "MODI", "_val")
/// 8..16   8-byte big-endian CFAbsoluteTime payload
/// ```
struct DTField: Sendable, Equatable {
    /// 4-character tag, trimmed of trailing spaces (`"UTI "` becomes `"UTI"`).
    let tag: String
    /// Raw payload bytes. For `.stringLike` this is the variable-length
    /// payload; for `.date` it's the 8-byte CFAbsoluteTime in big-endian.
    let payload: Data
    /// On-wire field variant.
    let kind: DTFieldKind

    init(tag: String, payload: Data, kind: DTFieldKind = .stringLike) {
        self.tag = tag
        self.payload = payload
        self.kind = kind
    }

    /// Convenience: payload decoded as UTF-8. Returns `nil` if the
    /// payload is not valid UTF-8 — which is always the case for `.date`
    /// fields.
    var text: String? {
        guard kind == .stringLike else { return nil }
        return String(data: payload, encoding: .utf8)
    }
}

enum DTFieldError: Error, Equatable, Sendable {
    case truncated(at: Int)
    case missingMagic(at: Int)
    case lengthOverflow(at: Int, length: UInt32, remaining: Int)
}

/// Decode a sequence of `DTField`s from raw `.dt` file bytes.
///
/// Stops cleanly at end-of-data. Throws if a field header is partially
/// present or its declared length runs past the end of the buffer.
func parseDTFields(_ data: Data) throws(DTFieldError) -> [DTField] {
    var fields: [DTField] = []
    var offset = 0
    let count = data.count

    while offset < count {
        // Need at least the 8-byte magic+tag prefix to identify the variant.
        guard offset + 8 <= count else {
            throw .truncated(at: offset)
        }

        // Identify magic.
        let magic = data.subdata(in: offset..<(offset + 4))
        let tagBytes = data.subdata(in: (offset + 4)..<(offset + 8))
        let tag = String(decoding: tagBytes, as: UTF8.self)
            .trimmingCharacters(in: .whitespaces)

        if magic == Data([0x44, 0x54, 0x73, 0x74]) { // "DTst"
            guard offset + 16 <= count else {
                throw .truncated(at: offset)
            }
            let length = data.readBigEndianUInt32(at: offset + 8)
            let payloadStart = offset + 16
            let payloadEnd = payloadStart + Int(length)
            guard payloadEnd <= count else {
                throw .lengthOverflow(at: offset, length: length, remaining: count - payloadStart)
            }
            let payload = data.subdata(in: payloadStart..<payloadEnd)
            fields.append(DTField(tag: tag, payload: payload, kind: .stringLike))
            offset = payloadEnd
        } else if magic == Data([0x44, 0x54, 0x64, 0x61]) { // "DTda"
            // Fixed 8-byte payload: CFAbsoluteTime big-endian Double.
            guard offset + 16 <= count else {
                throw .truncated(at: offset)
            }
            let payload = data.subdata(in: (offset + 8)..<(offset + 16))
            fields.append(DTField(tag: tag, payload: payload, kind: .date))
            offset += 16
        } else {
            throw .missingMagic(at: offset)
        }
    }
    return fields
}

extension Data {
    fileprivate func readBigEndianUInt32(at index: Int) -> UInt32 {
        let b0 = UInt32(self[index])
        let b1 = UInt32(self[index + 1])
        let b2 = UInt32(self[index + 2])
        let b3 = UInt32(self[index + 3])
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }
}
