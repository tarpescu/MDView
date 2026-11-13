//
//  MarkdownPreviewView.swift
//  MDView
//
//  Renders GitHub Flavored Markdown using swift-markdown-ui with native
//  macOS Human Interface Guidelines aesthetics.
//  Intercepts link clicks to resolve relative Markdown files as tabs,
//  loads local relative images via baseURL, and handles intra-document anchors.
//

import SwiftUI
import AppKit
import MarkdownUI

struct MarkdownPreviewView: View {
    let markdown: String
    var headings: [MarkdownHeading] = []
    @Binding var targetHeadingId: String?
    var fileURL: URL? = nil
    var fontScale: Double = 1.0
    var appearance: AppAppearance = .system
    var onOpenRelativeTab: ((URL) -> Void)? = nil

    private var baseDirectory: URL? {
        fileURL?.deletingLastPathComponent()
    }

    private var sections: [MarkdownRenderSection] {
        MarkdownRenderSection.createSections(from: markdown, headings: headings)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(sections) { section in
                                Markdown(section.content, baseURL: baseDirectory, imageBaseURL: baseDirectory)
                                    .markdownTheme(.nativeMac(scale: fontScale, appearance: appearance))
                                    .localMarkdownImages()
                                    .textSelection(.enabled)
                                    // Each section is its own Markdown view, so the heading's
                                    // top margin would collapse; restore it between sections.
                                    .padding(.top, sectionSpacing(for: section, in: sections))
                                    .id(section.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 860 * CGFloat(fontScale), alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(appearance.backgroundColor)
            .environment(\.openURL, OpenURLAction { url in
                handleLinkClick(url)
            })
            .onChange(of: targetHeadingId) { _, newId in
                if let target = newId {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    DispatchQueue.main.async {
                        self.targetHeadingId = nil
                    }
                }
            }
        }
    }

    /// Space above a section, matching the heading margins of `Theme.nativeMac`.
    private func sectionSpacing(for section: MarkdownRenderSection, in sections: [MarkdownRenderSection]) -> CGFloat {
        guard section.id != sections.first?.id,
              let level = headings.first(where: { $0.id == section.id })?.level else { return 0 }
        let margins: [CGFloat] = [28, 22, 18, 14]
        return margins[min(level, margins.count) - 1] * CGFloat(fontScale)
    }

    // MARK: - Link Interception & Relative File Resolution
    @MainActor
    private func handleLinkClick(_ url: URL) -> OpenURLAction.Result {
        let scheme = url.scheme?.lowercased()

        // 1. Non-file links (http, https, mailto, tel, custom app schemes)
        if let scheme, scheme != "file" {
            return .systemAction
        }

        // 2. Intra-document anchors. MarkdownUI resolves "#section" against the
        //    base URL, so it arrives either bare or as "file:///docs/#section".
        if let fragment = url.fragment, isLinkToCurrentDocument(url) {
            if let match = heading(matchingFragment: fragment) {
                targetHeadingId = match.id
            }
            return .handled
        }

        // 3. Relative or local file links
        let resolvedURL: URL
        if url.isFileURL {
            resolvedURL = URL(fileURLWithPath: url.path).standardizedFileURL
        } else if let baseDir = baseDirectory {
            resolvedURL = baseDir.appendingPathComponent(url.path).standardizedFileURL
        } else {
            showAlert(
                title: "Cannot Open Relative Link",
                message: "The link \u{201C}\(url.relativeString)\u{201D} cannot be resolved because this document has not been saved to disk yet."
            )
            return .handled
        }

        let fileManager = FileManager.default

        // Extension-less links ("[Guide](GUIDE)") try "GUIDE.md" first.
        if resolvedURL.pathExtension.isEmpty {
            let withMd = resolvedURL.appendingPathExtension("md")
            if fileManager.fileExists(atPath: withMd.path) {
                openMarkdown(withMd)
                return .handled
            }
        }

        guard fileManager.fileExists(atPath: resolvedURL.path) else {
            showAlert(
                title: "Linked File Not Found",
                message: "The linked file does not exist at path:\n\n\(resolvedURL.path)"
            )
            return .handled
        }

        if MarkdownFile.isMarkdown(resolvedURL) {
            // Markdown files open as tabs in this window
            openMarkdown(resolvedURL)
        } else {
            // Other local files (.pdf, images, folders…) open in their default app
            NSWorkspace.shared.open(resolvedURL)
        }
        return .handled
    }

    /// True for "#x", "file:///dir/#x" and "file:///dir/this-file.md#x".
    private func isLinkToCurrentDocument(_ url: URL) -> Bool {
        guard url.isFileURL else { return url.path.isEmpty }
        let target = url.standardizedFileURL.path
        if let baseDir = baseDirectory, target == baseDir.standardizedFileURL.path { return true }
        if let fileURL, target == fileURL.standardizedFileURL.path { return true }
        return false
    }

    private func heading(matchingFragment rawFragment: String) -> MarkdownHeading? {
        let fragment = (rawFragment.removingPercentEncoding ?? rawFragment).lowercased()
        return headings.first { $0.slug == fragment }
            ?? headings.first { $0.title.lowercased() == fragment }
            ?? headings.first { $0.id == fragment }
    }

    private func openMarkdown(_ url: URL) {
        if let onOpenRelativeTab {
            onOpenRelativeTab(url)
        } else {
            WindowManager.shared.openURLsInActiveWindow([url])
        }
    }

    @MainActor
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40 * fontScale))
                .foregroundStyle(.tertiary)
            Text("No Content")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Switch to Editor or Split mode to start writing.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }
}

// MARK: - Native macOS Markdown Theme with Scaling & Appearance Support
@MainActor
extension Theme {
    /// - Parameter forPrinting: uses fixed light colours and wraps code blocks
    ///   instead of putting them in a horizontal ScrollView (which renders
    ///   as empty space in PDFs).
    static func nativeMac(scale: Double = 1.0, appearance: AppAppearance = .system, forPrinting: Bool = false) -> Theme {
        let baseFontSize = 14.0 * scale
        let textColor: Color
        let codeBg: Color
        let codeBlockBg: Color
        let borderColor: Color
        if forPrinting {
            textColor = Color(white: 0.1)
            codeBg = Color(white: 0.94)
            codeBlockBg = Color(white: 0.965)
            borderColor = Color(white: 0.82)
        } else if appearance == .sepia {
            textColor = Color(red: 0.27, green: 0.22, blue: 0.16)
            codeBg = Color(red: 0.92, green: 0.88, blue: 0.79)
            codeBlockBg = Color(red: 0.94, green: 0.90, blue: 0.82)
            borderColor = Color(red: 0.85, green: 0.80, blue: 0.70)
        } else {
            textColor = Color.primary
            codeBg = Color(nsColor: .quaternaryLabelColor).opacity(0.5)
            codeBlockBg = Color(nsColor: .controlBackgroundColor)
            borderColor = Color(nsColor: .separatorColor)
        }

        return Theme()
            .text {
                ForegroundColor(textColor)
                FontSize(baseFontSize)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.88))
                BackgroundColor(codeBg)
            }
            .link {
                ForegroundColor(appearance == .sepia ? Color(red: 0.72, green: 0.35, blue: 0.12) : Color.accentColor)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: 28 * scale, bottom: 12 * scale)
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.75))
                    }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: 22 * scale, bottom: 10 * scale)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.35))
                    }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: 18 * scale, bottom: 8 * scale)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.15))
                    }
            }
            .heading4 { configuration in
                configuration.label
                    .markdownMargin(top: 14 * scale, bottom: 6 * scale)
                    .markdownTextStyle {
                        FontWeight(.medium)
                        FontSize(.em(1.05))
                    }
            }
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 12 * scale)
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(appearance == .sepia ? Color(red: 0.75, green: 0.55, blue: 0.35) : Color.accentColor.opacity(0.7))
                        .frame(width: 3.5)
                    configuration.label
                        .padding(.leading, 12)
                        .foregroundStyle(appearance == .sepia ? Color(red: 0.40, green: 0.32, blue: 0.24) : Color.secondary)
                }
                .markdownMargin(top: 8 * scale, bottom: 14 * scale)
            }
            .codeBlock { configuration in
                let code = configuration.label
                    .relativeLineSpacing(.em(0.25))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.88))
                    }
                    .padding(14 * scale)
                Group {
                    if forPrinting {
                        code
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) { code }
                    }
                }
                .background(codeBlockBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
                .markdownMargin(top: 8 * scale, bottom: 16 * scale)
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: borderColor))
                    .markdownTableBackgroundStyle(.alternatingRows(Color.clear, codeBg.opacity(0.5)))
                    .markdownMargin(top: 4 * scale, bottom: 16 * scale)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontWeight(.semibold)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6 * scale)
                    .padding(.horizontal, 12 * scale)
            }
            .thematicBreak {
                Divider()
                    .overlay(borderColor)
                    .markdownMargin(top: 20 * scale, bottom: 20 * scale)
            }
    }
}
