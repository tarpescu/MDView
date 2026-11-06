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
                                    .textSelection(.enabled)
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

    // MARK: - Link Interception & Relative File Resolution
    @MainActor
    private func handleLinkClick(_ url: URL) -> OpenURLAction.Result {
        let scheme = url.scheme?.lowercased()

        // 1. External Web & Protocol Links
        if scheme == "http" || scheme == "https" || scheme == "mailto" || scheme == "tel" {
            return .systemAction
        }

        // 2. Intra-Document Anchor Links (#heading)
        let relativeString = url.relativeString
        if relativeString.hasPrefix("#") || (scheme == nil && (url.path.isEmpty || url.path == "/") && url.fragment != nil) {
            let fragment = (url.fragment ?? String(relativeString.dropFirst())).lowercased()
            if let match = headings.first(where: {
                $0.id.lowercased() == fragment ||
                $0.title.lowercased() == fragment ||
                $0.title.lowercased().replacingOccurrences(of: " ", with: "-") == fragment
            }) {
                targetHeadingId = match.id
                return .handled
            }
        }

        // 3. Relative or Local File Links
        guard let baseDir = baseDirectory else {
            showFileNotFoundAlert(
                title: "Cannot Open Relative Link",
                message: "The linked path '\(relativeString)' cannot be resolved because this document has not been saved to disk yet."
            )
            return .handled
        }

        // Strip any #anchor fragment from path
        let rawPath = url.path.isEmpty ? relativeString : url.path
        let cleanPath = rawPath.components(separatedBy: "#").first ?? rawPath

        let resolvedURL: URL
        if url.isFileURL || scheme == "file" {
            resolvedURL = URL(fileURLWithPath: url.path).standardizedFileURL
        } else {
            resolvedURL = baseDir.appendingPathComponent(cleanPath).standardizedFileURL
        }

        let ext = resolvedURL.pathExtension.lowercased()

        // If it's a Markdown file, open it directly in this window as a Tab!
        if ext == "md" || ext == "markdown" || ext == "mdown" || ext == "mkdn" {
            if FileManager.default.fileExists(atPath: resolvedURL.path) {
                if let onOpenRelativeTab = onOpenRelativeTab {
                    onOpenRelativeTab(resolvedURL)
                } else {
                    NSDocumentController.shared.openDocument(withContentsOf: resolvedURL, display: true) { _, _, _ in }
                }
            } else {
                showFileNotFoundAlert(
                    title: "Linked File Not Found",
                    message: "The linked Markdown file does not exist at path:\n\n\(resolvedURL.path)"
                )
            }
            return .handled
        } else if ext.isEmpty {
            // Check if appending .md exists
            let withMd = resolvedURL.appendingPathExtension("md")
            if FileManager.default.fileExists(atPath: withMd.path) {
                if let onOpenRelativeTab = onOpenRelativeTab {
                    onOpenRelativeTab(withMd)
                } else {
                    NSDocumentController.shared.openDocument(withContentsOf: withMd, display: true) { _, _, _ in }
                }
                return .handled
            }

            if FileManager.default.fileExists(atPath: resolvedURL.path) {
                NSWorkspace.shared.open(resolvedURL)
            } else {
                showFileNotFoundAlert(
                    title: "Linked File Not Found",
                    message: "The linked file does not exist at path:\n\n\(resolvedURL.path)"
                )
            }
            return .handled
        } else {
            // Other local files (.pdf, images, etc.) open in default viewer
            if FileManager.default.fileExists(atPath: resolvedURL.path) {
                NSWorkspace.shared.open(resolvedURL)
            } else {
                showFileNotFoundAlert(
                    title: "Linked File Not Found",
                    message: "The linked file does not exist at path:\n\n\(resolvedURL.path)"
                )
            }
            return .handled
        }
    }

    @MainActor
    private func showFileNotFoundAlert(title: String, message: String) {
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
    static func nativeMac(scale: Double = 1.0, appearance: AppAppearance = .system) -> Theme {
        let baseFontSize = 14.0 * scale
        let textColor = appearance == .sepia ? Color(red: 0.27, green: 0.22, blue: 0.16) : Color.primary
        let codeBg = appearance == .sepia ? Color(red: 0.92, green: 0.88, blue: 0.79) : Color(nsColor: .quaternaryLabelColor).opacity(0.5)
        let codeBlockBg = appearance == .sepia ? Color(red: 0.94, green: 0.90, blue: 0.82) : Color(nsColor: .controlBackgroundColor)
        let borderColor = appearance == .sepia ? Color(red: 0.85, green: 0.80, blue: 0.70) : Color(nsColor: .separatorColor)

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
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .relativeLineSpacing(.em(0.25))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.88))
                        }
                        .padding(14 * scale)
                }
                .background(codeBlockBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
                .markdownMargin(top: 8 * scale, bottom: 16 * scale)
            }
    }
}
