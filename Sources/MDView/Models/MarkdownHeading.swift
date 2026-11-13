//
//  MarkdownHeading.swift
//  MDView
//
//  Parses and models ATX document headings (# … ######) for the Table of Contents
//  outline, anchor-link resolution, and synchronized scrolling across Viewer and Editor.
//

import Foundation

struct MarkdownHeading: Identifiable, Hashable, Sendable {
    let id: String
    let level: Int // 1…6
    let title: String
    /// GitHub-compatible anchor slug, e.g. "Tab & Window" → "tab--window".
    let slug: String
    let lineIndex: Int
    /// UTF-16 offset of the heading line, usable as an NSRange location.
    let characterOffset: Int

    /// Parses ATX headings in a single linear pass, ignoring lines inside
    /// fenced code blocks (``` or ~~~) so that shell comments such as
    /// `# install` are not mistaken for headings.
    static func parse(from text: String) -> [MarkdownHeading] {
        guard !text.isEmpty else { return [] }

        var headings: [MarkdownHeading] = []
        var slugCounts: [String: Int] = [:]
        var openFence: (marker: Character, length: Int)?
        var charOffset = 0

        // Split on the "\n" scalar (a Character split would treat "\r\n" as one
        // grapheme and never match) so offsets stay in sync with NSString ranges.
        let lines = text.unicodeScalars.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, scalars) in lines.enumerated() {
            let rawLine = String(scalars)
            defer { charOffset += rawLine.utf16.count + 1 }

            let line = rawLine.hasSuffix("\r") ? rawLine.dropLast() : rawLine[...]
            let leadingSpaces = line.prefix(while: { $0 == " " }).count
            // More than three spaces of indentation is an indented code block.
            guard leadingSpaces <= 3 else { continue }
            let content = line.dropFirst(leadingSpaces)

            // Fenced code blocks
            if let fence = fenceMarker(in: content) {
                if let current = openFence {
                    let rest = content.dropFirst(fence.length)
                    if fence.marker == current.marker, fence.length >= current.length,
                       rest.allSatisfy(\.isWhitespace) {
                        openFence = nil
                    }
                } else {
                    openFence = fence
                }
                continue
            }
            guard openFence == nil else { continue }

            // ATX heading: 1–6 '#' followed by whitespace or end of line
            let hashCount = content.prefix(while: { $0 == "#" }).count
            guard (1...6).contains(hashCount) else { continue }
            let afterHashes = content.dropFirst(hashCount)
            guard afterHashes.isEmpty || afterHashes.first == " " || afterHashes.first == "\t" else { continue }

            let title = stripClosingSequence(afterHashes.trimmingCharacters(in: .whitespaces))
            guard !title.isEmpty else { continue }

            var slug = makeSlug(title)
            if let seen = slugCounts[slug] {
                slugCounts[slug] = seen + 1
                slug += "-\(seen)"
            } else {
                slugCounts[slug] = 1
            }

            headings.append(MarkdownHeading(
                id: "heading-\(index)-\(hashCount)",
                level: hashCount,
                title: title,
                slug: slug,
                lineIndex: index,
                characterOffset: charOffset
            ))
        }

        return headings
    }

    private static func fenceMarker(in line: Substring) -> (marker: Character, length: Int)? {
        guard let first = line.first, first == "`" || first == "~" else { return nil }
        let length = line.prefix(while: { $0 == first }).count
        return length >= 3 ? (first, length) : nil
    }

    /// Removes an optional closing sequence: "Title ##" → "Title".
    private static func stripClosingSequence(_ title: String) -> String {
        guard title.hasSuffix("#") else { return title }
        let withoutHashes = title.replacingOccurrences(of: "#+$", with: "", options: .regularExpression)
        guard withoutHashes.isEmpty || withoutHashes.hasSuffix(" ") || withoutHashes.hasSuffix("\t") else {
            return title // "C#" is part of the title
        }
        return withoutHashes.trimmingCharacters(in: .whitespaces)
    }

    /// GitHub-style anchor: lowercase, drop punctuation and symbols (keeping
    /// letters, digits, '-' and '_'), and turn spaces into '-'.
    static func makeSlug(_ title: String) -> String {
        var slug = ""
        for scalar in title.lowercased().unicodeScalars {
            if scalar == " " {
                slug.append("-")
            } else if scalar == "-" || scalar == "_" || CharacterSet.alphanumerics.contains(scalar) {
                slug.unicodeScalars.append(scalar)
            }
        }
        return slug
    }
}

/// Represents a slice of markdown belonging to a heading section for lazy rendering.
struct MarkdownRenderSection: Identifiable, Hashable, Sendable {
    let id: String
    let content: String

    static func createSections(from markdown: String, headings: [MarkdownHeading]) -> [MarkdownRenderSection] {
        guard !headings.isEmpty else {
            return [MarkdownRenderSection(id: "root", content: markdown)]
        }

        var sections: [MarkdownRenderSection] = []
        let nsString = markdown as NSString
        let totalLength = nsString.length

        // Include any introduction before the first heading
        let firstStart = headings[0].characterOffset
        if firstStart > 0 {
            let prelude = nsString.substring(with: NSRange(location: 0, length: min(firstStart, totalLength)))
            if !prelude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sections.append(MarkdownRenderSection(id: "prelude", content: prelude))
            }
        }

        for (i, current) in headings.enumerated() {
            let start = current.characterOffset
            guard start < totalLength else { break }
            let end = i + 1 < headings.count ? headings[i + 1].characterOffset : totalLength
            let length = max(0, min(end, totalLength) - start)
            let content = nsString.substring(with: NSRange(location: start, length: length))
            sections.append(MarkdownRenderSection(id: current.id, content: content))
        }

        return sections
    }
}
