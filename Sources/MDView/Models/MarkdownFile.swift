//
//  MarkdownFile.swift
//  MDView
//
//  Shared file-type knowledge and tolerant text loading for Markdown documents.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    /// Standard Uniform Type Identifier for Markdown files.
    static let markdownDocument = UTType(importedAs: "net.daringfireball.markdown")
}

enum MarkdownFile {
    /// File extensions treated as Markdown (opened as tabs, not handed to Finder).
    static let extensions: Set<String> = ["md", "markdown", "mdown", "mkdn", "mkd"]

    /// Extensions that can be opened in a tab (Markdown plus plain text).
    static let openableExtensions: Set<String> = extensions.union(["txt", "text"])

    /// Image extensions inserted as `![](…)` references when dropped into the editor.
    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "tif", "tiff", "bmp"]

    /// Content types offered by the Open and Save panels.
    static let contentTypes: [UTType] = [.markdownDocument, .plainText]

    static func isMarkdown(_ url: URL) -> Bool {
        extensions.contains(url.pathExtension.lowercased())
    }

    static func isOpenable(_ url: URL) -> Bool {
        openableExtensions.contains(url.pathExtension.lowercased())
    }

    static func isImage(_ url: URL) -> Bool {
        imageExtensions.contains(url.pathExtension.lowercased())
    }

    /// Reads a text file, falling back through common encodings so that a
    /// non-UTF-8 file is never shown (and later saved) as an empty document.
    static func read(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        var detected: String.Encoding = .utf8
        if let sniffed = try? String(contentsOf: url, usedEncoding: &detected) {
            return sniffed
        }
        // ISO Latin-1 maps every byte, so this always succeeds.
        return String(data: data, encoding: .isoLatin1) ?? String(decoding: data, as: UTF8.self)
    }
}
