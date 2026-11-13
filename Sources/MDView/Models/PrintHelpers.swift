//
//  PrintHelpers.swift
//  MDView
//
//  Print (Cmd+P) and Export as PDF (Shift+Cmd+E).
//
//  The document is rendered once into a paginated vector PDF with SwiftUI's
//  ImageRenderer; printing hands that PDF to PDFKit. (Printing an
//  NSHostingView directly drops layer-backed content such as code blocks,
//  images and table borders, and adds stray blank pages.)
//

import SwiftUI
import AppKit
import PDFKit
import MarkdownUI

extension Notification.Name {
    static let printActiveDocument = Notification.Name("MDView.printActiveDocument")
    static let exportPDFActiveDocument = Notification.Name("MDView.exportPDFActiveDocument")
}

/// The document as laid out on paper: always light, no scroll views.
struct PrintableMarkdownContainer: View {
    let markdown: String
    var fileURL: URL? = nil
    var fontScale: Double = 1.0

    private var baseDirectory: URL? {
        fileURL?.deletingLastPathComponent()
    }

    var body: some View {
        Markdown(markdown, baseURL: baseDirectory, imageBaseURL: baseDirectory)
            .markdownTheme(.nativeMac(scale: fontScale, appearance: .light, forPrinting: true))
            .localMarkdownImages()
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.colorScheme, .light)
    }
}

@MainActor
enum MarkdownPrinter {
    /// Page margin in points (on every side).
    static let margin: CGFloat = 48

    /// Renders `tab` into a multi-page PDF sized to the user's default paper.
    static func makePDF(for tab: TabItem, fontScale: Double, paperSize: NSSize = NSPrintInfo.shared.paperSize) -> Data? {
        let contentWidth = paperSize.width - margin * 2
        let contentHeight = paperSize.height - margin * 2
        guard contentWidth > 0, contentHeight > 0 else { return nil }

        let renderer = ImageRenderer(content:
            PrintableMarkdownContainer(markdown: tab.text, fileURL: tab.fileURL, fontScale: fontScale)
                .frame(width: contentWidth)
        )
        renderer.proposedSize = ProposedViewSize(width: contentWidth, height: nil)

        let data = NSMutableData()
        var succeeded = false

        // Resolve any dynamic NSColors with the light (Aqua) appearance.
        NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
            renderer.render { size, draw in
                var mediaBox = CGRect(origin: .zero, size: paperSize)
                guard let consumer = CGDataConsumer(data: data as CFMutableData),
                      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }

                let pageCount = max(1, Int((size.height / contentHeight).rounded(.up)))
                for page in 0..<pageCount {
                    context.beginPDFPage(nil)
                    context.saveGState()
                    context.clip(to: CGRect(x: margin, y: margin, width: contentWidth, height: contentHeight))
                    // CG's origin is bottom-left: shift the tall rendering so the
                    // slice for this page lands inside the page's content box.
                    let sliceTop = size.height - CGFloat(page) * contentHeight
                    context.translateBy(x: margin, y: margin + contentHeight - sliceTop)
                    draw(context)
                    context.restoreGState()
                    context.endPDFPage()
                }
                context.closePDF()
                succeeded = true
            }
        }
        return succeeded ? data as Data : nil
    }

    /// Shows the standard Print panel for the tab.
    static func print(_ tab: TabItem, fontScale: Double) {
        let printInfo = (NSPrintInfo.shared.copy() as? NSPrintInfo) ?? NSPrintInfo()
        guard let data = makePDF(for: tab, fontScale: fontScale, paperSize: printInfo.paperSize),
              let document = PDFDocument(data: data) else {
            NSSound.beep()
            return
        }
        // Margins are already part of the rendered pages.
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0

        guard let operation = document.printOperation(for: printInfo, scalingMode: .pageScaleNone, autoRotate: false) else {
            NSSound.beep()
            return
        }
        operation.jobTitle = tab.title
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true

        if let window = NSApp.keyWindow {
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            operation.run()
        }
    }

    /// Asks for a destination and writes the tab as a PDF at 100% scale.
    static func exportPDF(_ tab: TabItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(tab.title).pdf"
        savePanel.canCreateDirectories = true

        let export: @MainActor (URL) -> Void = { targetURL in
            guard let data = makePDF(for: tab, fontScale: 1.0) else {
                NSSound.beep()
                return
            }
            do {
                try data.write(to: targetURL, options: .atomic)
            } catch {
                NSAlert(error: error).runModal()
            }
        }

        guard let window = NSApp.keyWindow else {
            if savePanel.runModal() == .OK, let url = savePanel.url { export(url) }
            return
        }
        savePanel.beginSheetModal(for: window) { response in
            MainActor.assumeIsolated {
                if response == .OK, let url = savePanel.url { export(url) }
            }
        }
    }
}
