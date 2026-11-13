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

/// Called on the main actor with `true` once the content is safely on disk.
typealias SaveCompletion = @MainActor (Bool) -> Void

@MainActor
final class TabItem: ObservableObject, Identifiable, Hashable {
    nonisolated let id: UUID
    @Published var fileURL: URL?
    @Published var text: String {
        didSet {
            // Any edit (typing, formatting shortcut, external sync) dirties the tab.
            if text != oldValue { isModified = true }
        }
    }
    @Published var isModified: Bool = false

    /// Set when the backing file could not be read. Saving such a tab always
    /// goes through "Save As…" so the original file is never overwritten with
    /// an empty buffer.
    private(set) var loadError: Error?

    // Per-tab view state (retained across tab switching)
    @Published var viewMode: ViewMode = .viewer
    @Published var selectedHeadingId: String? = nil
    @Published var scrollToOffset: Int? = nil
    @Published var statistics: DocumentStatistics = .zero

    init(id: UUID = UUID(), fileURL: URL? = nil, text: String = "") {
        self.id = id
        self.fileURL = fileURL

        if let fileURL = fileURL {
            do {
                self.text = try MarkdownFile.read(fileURL)
            } catch {
                self.text = text
                self.loadError = error
            }
        } else {
            self.text = text
        }
    }

    var title: String {
        if let fileURL = fileURL {
            return fileURL.deletingPathExtension().lastPathComponent
        }
        return "Untitled"
    }

    /// Directory used to resolve relative links and images.
    var baseDirectory: URL? {
        fileURL?.deletingLastPathComponent()
    }

    // MARK: - Save Operations

    /// Saves to the current file, or asks for a location if the tab is untitled.
    /// `completion` receives `true` once the content is safely on disk.
    func save(completion: SaveCompletion? = nil) {
        guard let url = fileURL, loadError == nil else {
            saveAs(completion: completion)
            return
        }
        completion?(write(to: url))
    }

    /// Presents a Save panel as a sheet (or app-modal when no window is key).
    func saveAs(completion: SaveCompletion? = nil) {
        let panel = makeSavePanel()

        guard let window = NSApp.keyWindow else {
            let response = panel.runModal()
            completion?(response == .OK && panel.url.map { finishSaveAs(to: $0) } == true)
            return
        }

        panel.beginSheetModal(for: window) { response in
            MainActor.assumeIsolated {
                guard response == .OK, let targetURL = panel.url else {
                    completion?(false)
                    return
                }
                completion?(self.finishSaveAs(to: targetURL))
            }
        }
    }

    /// Blocking save used while the app is terminating, where sheets cannot run.
    func saveSynchronously() -> Bool {
        if let url = fileURL, loadError == nil {
            return write(to: url)
        }
        let panel = makeSavePanel()
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return finishSaveAs(to: url)
    }

    private func makeSavePanel() -> NSSavePanel {
        let panel = NSSavePanel()
        panel.allowedContentTypes = MarkdownFile.contentTypes
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.md"
        return panel
    }

    private func finishSaveAs(to url: URL) -> Bool {
        guard write(to: url) else { return false }
        fileURL = url
        loadError = nil
        return true
    }

    @discardableResult
    private func write(to url: URL) -> Bool {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            isModified = false
            return true
        } catch {
            NSAlert(error: error).runModal()
            return false
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
