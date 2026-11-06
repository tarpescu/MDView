//
//  PrintHelpers.swift
//  MDView
//
//  Helpers for macOS Print (Cmd+P) and Export to PDF with margin handling
//  and relative image resolution.
//

import SwiftUI
import MarkdownUI

extension Notification.Name {
    static let printActiveDocument = Notification.Name("MDView.printActiveDocument")
    static let exportPDFActiveDocument = Notification.Name("MDView.exportPDFActiveDocument")
}

/// A clean, paginated container used exclusively for Quartz vector printing and PDF rendering.
struct PrintableMarkdownContainer: View {
    let markdown: String
    var fileURL: URL? = nil
    var fontScale: Double = 1.0

    private var baseDirectory: URL? {
        fileURL?.deletingLastPathComponent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Markdown(markdown, baseURL: baseDirectory, imageBaseURL: baseDirectory)
                .markdownTheme(.nativeMac(scale: fontScale, appearance: .light))
        }
        .padding(36)
        .background(Color.white)
        .foregroundColor(.black)
    }
}
