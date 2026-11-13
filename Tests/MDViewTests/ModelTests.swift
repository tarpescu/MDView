import Foundation
import Testing
@testable import MDView

/// Creates a unique temporary directory for one test and removes it afterwards.
private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("MDViewTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    try body(dir)
}

@Suite("File reading")
struct MarkdownFileTests {
    @Test func readsUTF8() throws {
        try withTemporaryDirectory { dir in
            let url = dir.appendingPathComponent("a.md")
            try "# Salut ăîșț 😀".write(to: url, atomically: true, encoding: .utf8)
            #expect(try MarkdownFile.read(url) == "# Salut ăîșț 😀")
        }
    }

    @Test func readsUTF16WithBOM() throws {
        try withTemporaryDirectory { dir in
            let url = dir.appendingPathComponent("b.md")
            try "# UTF-16 ✓".write(to: url, atomically: true, encoding: .utf16)
            #expect(try MarkdownFile.read(url) == "# UTF-16 ✓")
        }
    }

    @Test func fallsBackToLatin1InsteadOfReturningEmpty() throws {
        try withTemporaryDirectory { dir in
            let url = dir.appendingPathComponent("c.md")
            try Data([0x23, 0x20, 0x43, 0x61, 0x66, 0xE9]).write(to: url) // "# Café" in Latin-1
            #expect(try MarkdownFile.read(url) == "# Café")
        }
    }

    @Test func classifiesExtensions() {
        #expect(MarkdownFile.isMarkdown(URL(fileURLWithPath: "/x/README.MD")))
        #expect(MarkdownFile.isOpenable(URL(fileURLWithPath: "/x/notes.txt")))
        #expect(!MarkdownFile.isMarkdown(URL(fileURLWithPath: "/x/notes.txt")))
        #expect(MarkdownFile.isImage(URL(fileURLWithPath: "/x/diagram.PNG")))
        #expect(!MarkdownFile.isOpenable(URL(fileURLWithPath: "/x/spec.pdf")))
    }
}

@Suite("Tab model")
@MainActor
struct TabItemTests {
    @Test func loadingAFileIsNotAModification() throws {
        try withTemporaryDirectory { dir in
            let url = dir.appendingPathComponent("doc.md")
            try "hello".write(to: url, atomically: true, encoding: .utf8)
            let tab = TabItem(fileURL: url)
            #expect(tab.text == "hello")
            #expect(!tab.isModified)
            #expect(tab.title == "doc")
            #expect(tab.baseDirectory?.standardizedFileURL == dir.standardizedFileURL)
        }
    }

    @Test func editingMarksModifiedOnlyOnRealChanges() {
        let tab = TabItem(text: "same")
        tab.text = "same"
        #expect(!tab.isModified)
        tab.text = "changed"
        #expect(tab.isModified)
    }

    @Test func saveWritesUTF8AndClearsDirtyFlag() throws {
        try withTemporaryDirectory { dir in
            let url = dir.appendingPathComponent("doc.md")
            try "old".write(to: url, atomically: true, encoding: .utf8)
            let tab = TabItem(fileURL: url)
            tab.text = "new ✓"

            var result: Bool?
            tab.save { result = $0 }

            #expect(result == true)
            #expect(!tab.isModified)
            #expect(try String(contentsOf: url, encoding: .utf8) == "new ✓")
        }
    }

    @Test func untitledTabHasNoBaseDirectory() {
        let tab = TabItem()
        #expect(tab.title == "Untitled")
        #expect(tab.baseDirectory == nil)
    }
}

@Suite("Statistics & zoom")
struct MiscModelTests {
    @Test func statistics() async {
        let stats = await DocumentStatistics.calculate(for: "# Title\n\nHello  world 😀\nlast")
        #expect(stats.wordCount == 6)
        #expect(stats.lineCount == 4)
        #expect(stats.characterCount == 28)
        #expect(stats.readingTimeMinutes == 1)
    }

    @Test func emptyStatistics() async {
        #expect(await DocumentStatistics.calculate(for: "") == .zero)
    }

    @Test func zoomIsClampedAndDoesNotDrift() {
        var scale = 1.0
        for _ in 0..<5 { scale = FontScale.clamped(scale + FontScale.step) }
        #expect(scale == 1.5)
        #expect(FontScale.clamped(9) == FontScale.maximum)
        #expect(FontScale.clamped(0.1) == FontScale.minimum)
    }
}
