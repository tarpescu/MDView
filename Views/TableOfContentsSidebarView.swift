//
//  TableOfContentsSidebarView.swift
//  MDView
//
//  A native macOS outline sidebar that displays a hierarchical Table of Contents
//  for #, ##, and ### Markdown headings with instant jump-to-section navigation.
//

import SwiftUI

struct TableOfContentsSidebarView: View {
    let headings: [MarkdownHeading]
    @Binding var selectedHeadingId: String?
    var onSelect: (MarkdownHeading) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader

            if headings.isEmpty {
                emptyState
            } else {
                outlineList
            }
        }
        .frame(minWidth: 190, idealWidth: 230, maxWidth: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header
    private var sidebarHeader: some View {
        HStack {
            Label("Outline", systemImage: "list.bullet.indent")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            if !headings.isEmpty {
                Text("\(headings.count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .quaternaryLabelColor))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Outline List
    private var outlineList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(headings) { heading in
                    Button {
                        selectedHeadingId = heading.id
                        onSelect(heading)
                    } label: {
                        HStack(spacing: 8) {
                            headingIndicator(for: heading.level)

                            Text(heading.title)
                                .font(font(for: heading.level))
                                .foregroundStyle(selectedHeadingId == heading.id ? .primary : .secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()

                            Text("L\(heading.lineIndex + 1)")
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.quaternary)
                        }
                        .padding(.leading, CGFloat((heading.level - 1) * 12 + 8))
                        .padding(.trailing, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedHeadingId == heading.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "text.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(.quaternary)
            Text("No Headings Found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Add #, ##, or ### to your document to generate an outline.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Level Styling
    private func headingIndicator(for level: Int) -> some View {
        Text("H\(level)")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(level == 1 ? Color.accentColor : Color.secondary.opacity(0.8))
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.5))
            )
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1: return .system(size: 13, weight: .semibold)
        case 2: return .system(size: 12.5, weight: .medium)
        default: return .system(size: 12, weight: .regular)
        }
    }
}
