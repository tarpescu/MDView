//
//  MarkdownDocument.swift
//  MDView
//
//  A high-performance FileDocument implementation for reading and writing
//  UTF-8 Markdown (.md, .markdown) documents in SwiftUI.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Standard Uniform Type Identifier for Markdown files
    static let markdownDocument = UTType(importedAs: "net.daringfireball.markdown")
}

struct MarkdownDocument: FileDocument {
    var text: String

    // MARK: - Supported Content Types
    static var readableContentTypes: [UTType] {
        [
            .markdownDocument,
            .plainText
        ]
    }

    static var writableContentTypes: [UTType] {
        [
            .markdownDocument
        ]
    }

    // MARK: - Initializers

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        if let string = String(data: data, encoding: .utf8) {
            self.text = string
        } else if let string = String(data: data, encoding: .isoLatin1) {
            self.text = string
        } else {
            self.text = String(decoding: data, as: UTF8.self)
        }
    }

    // MARK: - Serialization

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
