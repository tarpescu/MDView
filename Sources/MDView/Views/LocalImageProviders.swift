//
//  LocalImageProviders.swift
//  MDView
//
//  MarkdownUI loads images through NetworkImage, which only accepts HTTP
//  responses — so `![](assets/diagram.png)` next to a local document never
//  rendered. These providers load `file://` images straight from disk (which
//  also makes them available synchronously for printing) and defer to the
//  default network providers for everything else.
//

import SwiftUI
import AppKit
import MarkdownUI

/// Block images (an image on its own line / paragraph).
struct LocalFileImageProvider: ImageProvider {
    @ViewBuilder
    func makeImage(url: URL?) -> some View {
        if let url, url.isFileURL {
            LocalFileImageView(url: url)
        } else {
            DefaultImageProvider.default.makeImage(url: url)
        }
    }
}

/// Images that appear inline within text.
struct LocalFileInlineImageProvider: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
        guard url.isFileURL else {
            return try await DefaultInlineImageProvider.default.image(with: url, label: label)
        }
        guard let nsImage = NSImage(contentsOf: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return Image(nsImage: nsImage)
    }
}

/// Shows a local image at its natural size, shrinking (never enlarging) to fit.
private struct LocalFileImageView: View {
    let url: URL

    var body: some View {
        if let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                .accessibilityLabel(url.deletingPathExtension().lastPathComponent)
        } else {
            Label(url.lastPathComponent, systemImage: "photo.badge.exclamationmark")
                .font(.caption)
                .foregroundStyle(.secondary)
                .help("Image not found: \(url.path)")
        }
    }
}

extension View {
    /// Installs the local-file aware image providers used by the preview and printing.
    func localMarkdownImages() -> some View {
        self
            .markdownImageProvider(LocalFileImageProvider())
            .markdownInlineImageProvider(LocalFileInlineImageProvider())
    }
}
