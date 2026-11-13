import Foundation
import Testing
@testable import MDView

@Suite("Heading parsing")
struct MarkdownHeadingTests {
    @Test func parsesAllSixLevels() {
        let text = (1...6).map { String(repeating: "#", count: $0) + " Level \($0)" }.joined(separator: "\n")
        let headings = MarkdownHeading.parse(from: text)
        #expect(headings.map(\.level) == [1, 2, 3, 4, 5, 6])
        #expect(headings.first?.title == "Level 1")
    }

    @Test func rejectsInvalidHeadings() {
        let text = """
        ####### seven hashes
        #nospace
            # indented code
        #
        """
        #expect(MarkdownHeading.parse(from: text).isEmpty)
    }

    @Test func ignoresFencedCodeBlocks() {
        let text = """
        # Real
        ```bash
        # Clone the repository
        ```
        ~~~
        ## also code
        ~~~
        ````
        ```
        # still code: an inner shorter fence does not close
        ````
        ## After
        """
        #expect(MarkdownHeading.parse(from: text).map(\.title) == ["Real", "After"])
    }

    @Test func stripsClosingHashesButKeepsCSharp() {
        let headings = MarkdownHeading.parse(from: "## Title ##\n### C#")
        #expect(headings.map(\.title) == ["Title", "C#"])
    }

    @Test func offsetsAreUTF16AndHandleCRLF() {
        let text = "Intro 😀\r\n# ⚡ First\r\nbody\r\n## Second"
        let ns = text as NSString
        for heading in MarkdownHeading.parse(from: text) {
            let line = ns.substring(from: heading.characterOffset)
            #expect(line.hasPrefix(String(repeating: "#", count: heading.level) + " "))
        }
    }

    @Test(arguments: [
        ("⚡ Key Features Matrix", "-key-features-matrix"),
        ("3. Tab & Window Management", "3-tab--window-management"),
        ("Hello, World!", "hello-world"),
        ("snake_case and-dash", "snake_case-and-dash"),
        ("Întrebări frecvente", "întrebări-frecvente"),
    ])
    func githubSlugs(title: String, slug: String) {
        #expect(MarkdownHeading.makeSlug(title) == slug)
    }

    @Test func duplicateSlugsGetSuffixes() {
        let slugs = MarkdownHeading.parse(from: "# Setup\n## Setup\n### Setup").map(\.slug)
        #expect(slugs == ["setup", "setup-1", "setup-2"])
    }

    @Test func sectionsReassembleTheDocument() {
        let text = "Prelude text\n\n# One\nbody\n```\n# not a heading\n```\n## Two\nmore"
        let headings = MarkdownHeading.parse(from: text)
        let sections = MarkdownRenderSection.createSections(from: text, headings: headings)
        #expect(sections.map(\.id) == ["prelude"] + headings.map(\.id))
        #expect(sections.map(\.content).joined() == text)
        // The code block stays inside section "One".
        #expect(sections[1].content.contains("# not a heading"))
    }

    @Test func documentWithoutHeadingsIsOneSection() {
        let sections = MarkdownRenderSection.createSections(from: "plain", headings: [])
        #expect(sections.count == 1)
        #expect(sections.first?.content == "plain")
    }
}
