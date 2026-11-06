//
//  StatusBarView.swift
//  MDView
//
//  A subtle bottom status bar inspired by TextEdit and iA Writer.
//  Displays debounced live statistics: Word, Character, and Line counts,
//  plus Estimated Reading Time without impacting typing responsiveness.
//

import SwiftUI

struct StatusBarView: View {
    let statistics: DocumentStatistics

    var body: some View {
        HStack(spacing: 16) {
            statItem(label: "words", count: statistics.wordCount, icon: "doc.text")
            statItem(label: "characters", count: statistics.characterCount, icon: "character.cursor.ibeam")
            statItem(label: "lines", count: statistics.lineCount, icon: "list.number")

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "clock")
                Text(readingTimeText)
            }
            .help("Estimated reading time based on 200 words per minute")
        }
        .font(.caption2)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func statItem(label: String, count: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.tertiary)
            Text("\(count.formatted()) \(label)")
        }
    }

    private var readingTimeText: String {
        if statistics.wordCount == 0 {
            return "0 min read"
        } else if statistics.readingTimeMinutes <= 1 {
            return "1 min read"
        } else {
            return "\(statistics.readingTimeMinutes) min read"
        }
    }
}
