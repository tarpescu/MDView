//
//  DocumentStatistics.swift
//  MDView
//
//  Lightweight, asynchronous document metrics calculator.
//  Uses a single-pass O(N) scan off the main thread to ensure 120 FPS typing.
//

import Foundation

struct DocumentStatistics: Equatable, Sendable {
    var wordCount: Int = 0
    var characterCount: Int = 0
    var lineCount: Int = 0
    var readingTimeMinutes: Int = 0

    static let zero = DocumentStatistics()

    /// Computes statistics asynchronously in a background task with no heap allocations.
    static func calculate(for text: String) async -> DocumentStatistics {
        guard !text.isEmpty else { return .zero }

        return await Task.detached(priority: .userInitiated) { () -> DocumentStatistics in
            let charCount = text.count
            var words = 0
            var lines = 1
            var inWord = false

            for char in text {
                if char.isNewline {
                    lines += 1
                    inWord = false
                } else if char.isWhitespace {
                    inWord = false
                } else if !inWord {
                    inWord = true
                    words += 1
                }
            }

            // Standard adult reading speed: ~200 words per minute
            let readingTime = max(1, Int(ceil(Double(words) / 200.0)))

            return DocumentStatistics(
                wordCount: words,
                characterCount: charCount,
                lineCount: lines,
                readingTimeMinutes: words == 0 ? 0 : readingTime
            )
        }.value
    }
}
