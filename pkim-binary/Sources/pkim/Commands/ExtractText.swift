import ArgumentParser
import Foundation
import PDFKit

/// `pkim extract-text <file-path>` — read text out of a file by
/// dispatching on the file's UTI / extension.
///
/// v1 surface: PDF (via PDFKit), plain text, markdown, HTML
/// (via NSAttributedString with HTML decoding). Everything else
/// returns `UnsupportedType`.
///
/// Skills that need extraction for niche formats (DOCX, PPTX,
/// RTFD, EPUB) compose this with external tools — `textutil` for
/// Apple-native formats, a Python helper for the legacy long
/// tail. The verb stays scoped to "what macOS gives us for free".
///
/// Read-only; never writes. No write gate. Accepts either a path
/// to a file on disk OR a `<ref>` to a DEVONthink record —
/// passing a ref resolves to the record's file path first.
struct ExtractText: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "extract-text",
        abstract: "Extract plain text from a file or DEVONthink record."
    )

    @Argument(help: "File path OR record reference (pkim-id, dt-uuid, item-link).")
    var target: String

    func run() throws {
        try CommandSupport.runReadVerb(named: "extract-text") {
            let resolvedPath = try Self.resolveToFilePath(target)
            let (text, extractor) = try Self.extract(filePath: resolvedPath)
            return ExtractTextPayload(
                target: target,
                filePath: resolvedPath,
                extractor: extractor,
                wordCount: TextUtil.wordCount(of: text),
                text: text
            )
        }
    }

    /// Accept either a filesystem path or a record reference. If the
    /// input looks like a path that exists, use it; otherwise treat
    /// as a record ref and look up the file path via the cache.
    static func resolveToFilePath(_ raw: String) throws -> String {
        if FileManager.default.fileExists(atPath: raw) {
            return raw
        }
        // Try resolving as a record ref.
        let record = try resolveRecord(raw)
        guard !record.filePath.isEmpty else {
            throw PkimError.invalidInput(
                "record has no file path: \(raw)",
                context: ["ref": raw]
            )
        }
        return record.filePath
    }

    static func extract(filePath: String) throws -> (text: String, extractor: String) {
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return try extractPDF(at: url)
        case "txt", "md", "markdown":
            return try (extractPlainText(at: url), "utf8")
        case "html", "htm":
            return try (extractHTML(at: url), "nsattributedstring-html")
        case "rtf":
            return try (extractRTF(at: url), "nsattributedstring-rtf")
        default:
            throw PkimError.invalidInput(
                "no extractor for extension `.\(ext)`. Supported: pdf, txt, md, markdown, html, htm, rtf.",
                context: ["extension": ext, "path": filePath]
            )
        }
    }

    private static func extractPDF(at url: URL) throws -> (text: String, extractor: String) {
        guard let document = PDFDocument(url: url) else {
            throw PkimError.io("PDFKit could not open \(url.lastPathComponent)")
        }
        var pieces: [String] = []
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let text = page.string {
                pieces.append(text)
            }
        }
        return (pieces.joined(separator: "\n\n"), "pdfkit")
    }

    private static func extractPlainText(at url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw PkimError.io("read \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func extractHTML(at url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]
            let attributed = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributed.string
        } catch {
            throw PkimError.io("HTML decode \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func extractRTF(at url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.rtf,
            ]
            let attributed = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributed.string
        } catch {
            throw PkimError.io("RTF decode \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}

struct ExtractTextPayload: Encodable, Sendable, Equatable {
    let target: String
    let filePath: String
    /// Which extractor produced the text: `pdfkit`, `utf8`,
    /// `nsattributedstring-html`, or `nsattributedstring-rtf`.
    let extractor: String
    let wordCount: Int
    let text: String
}
