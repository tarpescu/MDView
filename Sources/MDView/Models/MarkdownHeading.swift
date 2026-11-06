//
//  MarkdownHeading.swift
//  MDView
//
//  Parses and models document headings (#, ##, ###) for the Table of Contents
//  outline and enables synchronized scrolling across Viewer and Editor.
//

import Foundation

struct MarkdownHeading: Identifiable, Hashable, Sendable {
    let id: String
    let level: Int // 1, 2, or 3
    let title: String
    let lineIndex: Int
    let characterOffset: Int

    /// Parses Markdown headings (#, ##, ###) in a single linear pass.
    static func parse(from text: String) -> [MarkdownHeading] {
        guard !text.isEmpty else { return [] }
        
        var headings: [MarkdownHeading] = []
        let lines = text.components(separatedBy: .newlines)
        var charOffset = 0

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                var hashCount = 0
                for char in trimmed {
                    if char == "#" { hashCount += 1 } else { break }
                }

                if hashCount >= 1 && hashCount <= 3 {
                    let afterHashes = trimmed.dropFirst(hashCount)
                    if afterHashes.hasPrefix(" ") || afterHashes.hasPrefix("\t") {
                        let title = afterHashes.trimmingCharacters(in: .whitespaces)
                        if !title.isEmpty {
                            let id = "heading-\(index)-\(hashCount)"
                            headings.append(MarkdownHeading(
                                id: id,
                                level: hashCount,
                                title: title,
                                lineIndex: index,
                                characterOffset: charOffset
                            ))
                        }
                    }
                }
            }
            // +1 accounts for the newline character
            charOffset += (line as NSString).length + 1
        }

        return headings
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

        for i in 0..<headings.count {
            let current = headings[i]
            let start = current.characterOffset
            let end: Int
            if i + 1 < headings.count {
                end = headings[i + 1].characterOffset
            } else {
                end = totalLength
            }

            // Include any introduction before the first heading
            if i == 0 && start > 0 {
                let prelude = nsString.substring(with: NSRange(location: 0, length: start))
                if !prelude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sections.append(MarkdownRenderSection(id: "prelude", content: prelude))
                }
            }

            if start < totalLength {
                let length = max(0, min(end - start, totalLength - start))
                let content = nsString.substring(with: NSRange(location: start, length: length))
                sections.append(MarkdownRenderSection(id: current.id, content: content))
            }
        }

        return sections
    }
}
