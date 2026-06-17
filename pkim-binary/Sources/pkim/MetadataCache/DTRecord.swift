import Foundation

/// A parsed DEVONthink Spotlight cache record.
///
/// One `.dt` file maps to one `DTRecord`. The standard tag set
/// (`DBID`, `NAME`, `PATH`, `TITL`, `ALIA`, `UUID`, `KIND`, `TEXT`,
/// `FILE`, `UTI`, `MTDT`) is surfaced as typed fields. Custom
/// metadata (`_key`/`_val` pairs) is exposed as the dictionary
/// `customMetadata`, keyed by DT's internal field name (e.g.
/// `mdpkim_id`, `mddocrole`).
///
/// `customMetadata` keys are not normalised to human-facing labels
/// here — that mapping is a Domain concern (see doc 00 §"DEVONthink
/// custom-metadata readback keys").
struct DTRecord: Sendable, Equatable {
    let databaseUUID: String
    let databaseName: String
    let databasePath: String
    let title: String
    let aliases: [String]
    let uuid: String
    let kind: String
    let text: String
    let filePath: String
    let uti: String
    let mtdt: String?
    let customMetadata: [String: String]
}

enum DTRecordError: Error, Sendable, Equatable {
    case missingRequiredField(String)
    case payloadNotUTF8(tag: String)
}

extension DTRecord {
    /// Build a `DTRecord` from the ordered field list of one `.dt` file.
    ///
    /// `_key`/`_val` pairing rule: each `_key` consumes the immediately
    /// following `_val`. If the next field is another `_key` (or the
    /// list ends), the prior key gets an empty string value — that
    /// matches DEVONthink's actual on-disk shape, where unset custom
    /// fields appear as orphan `_key` entries.
    static func from(fields: [DTField]) throws(DTRecordError) -> DTRecord {
        var single: [String: String] = [:]
        var aliases: [String] = []
        var custom: [String: String] = [:]

        var i = 0
        while i < fields.count {
            let field = fields[i]
            switch field.tag {
            case "_key":
                guard let key = field.text else {
                    throw .payloadNotUTF8(tag: "_key")
                }
                // Peek ahead for a paired _val. If absent, record empty value.
                if i + 1 < fields.count, fields[i + 1].tag == "_val" {
                    let value = fields[i + 1].text ?? ""
                    custom[key] = value
                    i += 2
                } else {
                    custom[key] = ""
                    i += 1
                }
            case "_val":
                // Orphan _val (no preceding _key) — skip with no value to assign.
                i += 1
            case "ALIA":
                if let raw = field.text {
                    aliases = raw
                        .split(separator: ";")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
                i += 1
            default:
                if let text = field.text {
                    single[field.tag] = text
                }
                i += 1
            }
        }

        guard let dbid = single["DBID"] else { throw .missingRequiredField("DBID") }
        guard let name = single["NAME"] else { throw .missingRequiredField("NAME") }
        guard let path = single["PATH"] else { throw .missingRequiredField("PATH") }
        guard let title = single["TITL"] else { throw .missingRequiredField("TITL") }
        guard let uuid = single["UUID"] else { throw .missingRequiredField("UUID") }
        guard let kind = single["KIND"] else { throw .missingRequiredField("KIND") }
        guard let filePath = single["FILE"] else { throw .missingRequiredField("FILE") }

        return DTRecord(
            databaseUUID: dbid,
            databaseName: name,
            databasePath: path,
            title: title,
            aliases: aliases,
            uuid: uuid,
            kind: kind,
            text: single["TEXT"] ?? "",
            filePath: filePath,
            uti: single["UTI"] ?? "",
            mtdt: single["MTDT"],
            customMetadata: custom
        )
    }
}
