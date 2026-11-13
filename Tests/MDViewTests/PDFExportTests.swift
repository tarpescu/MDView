import Foundation
import PDFKit
import Testing
@testable import MDView

@Suite("PDF export")
@MainActor
struct PDFExportTests {
    private let a4 = NSSize(width: 595, height: 842)

    @Test func includesCodeBlocksAndTables() throws {
        let tab = TabItem(text: """
        # Title

        ```bash
        # Clone the repository
        git clone example
        ```

        | Col A | Col B |
        | --- | --- |
        | cell-one | cell-two |
        """)
        let data = try #require(MarkdownPrinter.makePDF(for: tab, fontScale: 1, paperSize: a4))
        let pdf = try #require(PDFDocument(data: data))
        #expect(pdf.pageCount == 1)
        let text = try #require(pdf.string)
        #expect(text.contains("git clone example"))
        #expect(text.contains("cell-two"))
        #expect(pdf.page(at: 0)?.bounds(for: .mediaBox).size == CGSize(width: 595, height: 842))
    }

    @Test func paginatesLongDocumentsWithoutBlankPages() throws {
        let body = (1...120).map { "Paragraph number \($0) with some text to fill the line." }.joined(separator: "\n\n")
        let tab = TabItem(text: "# Long\n\n" + body)
        let data = try #require(MarkdownPrinter.makePDF(for: tab, fontScale: 1, paperSize: a4))
        let pdf = try #require(PDFDocument(data: data))
        #expect(pdf.pageCount > 1)
        for index in 0..<pdf.pageCount {
            let pageText = pdf.page(at: index)?.string ?? ""
            #expect(!pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "page \(index + 1) is blank")
        }
        #expect(pdf.string?.contains("Paragraph number 120") == true)
    }
}
