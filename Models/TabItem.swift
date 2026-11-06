//
//  TabItem.swift
//  MDView
//
//  ObservableObject document model representing an individual open Tab inside a Window.
//  Maintains independent text content, file URL, edit state, view mode, and statistics.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

@MainActor
final class TabItem: ObservableObject, Identifiable, Hashable {
    nonisolated let id: UUID
    @Published var fileURL: URL?
    @Published var text: String
    @Published var isModified: Bool = false
    
    // Per-tab view state (retained across tab switching)
    @Published var viewMode: ViewMode = .viewer
    @Published var selectedHeadingId: String? = nil
    @Published var scrollToOffset: Int? = nil
    @Published var statistics: DocumentStatistics = .zero

    init(id: UUID = UUID(), fileURL: URL? = nil, text: String = "") {
        self.id = id
        self.fileURL = fileURL
        
        if let fileURL = fileURL, let loaded = try? String(contentsOf: fileURL, encoding: .utf8) {
            self.text = loaded
            self.isModified = false
        } else {
            self.text = text
            self.isModified = false
        }
    }

    var title: String {
        if let fileURL = fileURL {
            return fileURL.deletingPathExtension().lastPathComponent
        }
        return "Untitled"
    }

    // MARK: - Save Operations
    func save() {
        guard let url = fileURL else {
            saveAs()
            return
        }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            isModified = false
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(importedAs: "net.daringfireball.markdown"),
            .plainText
        ]
        panel.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.md"

        guard let window = NSApp.keyWindow else { return }
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let targetURL = panel.url else { return }
            do {
                try self.text.write(to: targetURL, atomically: true, encoding: .utf8)
                self.fileURL = targetURL
                self.isModified = false
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    // MARK: - Hashable & Equatable
    nonisolated static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
