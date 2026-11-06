//
//  WindowState.swift
//  MDView
//
//  ObservableObject managing the multi-tab state for an individual Window instance
//  and routing global application events (Finder open, Cmd+O, Cmd+T, Cmd+W) to the active window.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

extension Notification.Name {
    static let createNewWindow = Notification.Name("MDView.createNewWindow")
    static let createNewTab = Notification.Name("MDView.createNewTab")
    static let openDocumentDialog = Notification.Name("MDView.openDocumentDialog")
    static let closeCurrentTab = Notification.Name("MDView.closeCurrentTab")
    static let selectNextTab = Notification.Name("MDView.selectNextTab")
    static let selectPreviousTab = Notification.Name("MDView.selectPreviousTab")
    static let saveActiveTab = Notification.Name("MDView.saveActiveTab")
    static let saveAsActiveTab = Notification.Name("MDView.saveAsActiveTab")
}

// MARK: - Global Window Manager
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    var activeWindowState: WindowState?
    var pendingURLs: [URL] = []
    var openNewWindowAction: (() -> Void)?

    /// Opens file URLs as tabs in the currently focused window, or launches a new window.
    func openURLsInActiveWindow(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        if let activeState = activeWindowState {
            for url in urls {
                activeState.openTab(url: url)
            }
        } else {
            pendingURLs.append(contentsOf: urls)
            openNewWindowAction?()
        }
    }

    /// Displays the native NSOpenPanel modal for selecting files to open as tabs.
    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(importedAs: "net.daringfireball.markdown"),
            .plainText
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window) { [weak self] response in
                if response == .OK {
                    self?.openURLsInActiveWindow(panel.urls)
                }
            }
        } else {
            if panel.runModal() == .OK {
                openURLsInActiveWindow(panel.urls)
            }
        }
    }
}

// MARK: - Window-Specific Tab State
@MainActor
final class WindowState: ObservableObject, Identifiable {
    let id: UUID
    @Published var tabs: [TabItem] = []
    @Published var selectedTabId: UUID?

    init(id: UUID = UUID()) {
        self.id = id

        // Consume any pending URLs queued before this window appeared
        let queued = WindowManager.shared.pendingURLs
        WindowManager.shared.pendingURLs.removeAll()

        if !queued.isEmpty {
            for url in queued {
                let tab = TabItem(fileURL: url)
                tabs.append(tab)
            }
            selectedTabId = tabs.first?.id
        } else {
            let initialTab = TabItem()
            tabs.append(initialTab)
            selectedTabId = initialTab.id
        }
    }

    var selectedTab: TabItem? {
        get {
            if let id = selectedTabId {
                return tabs.first(where: { $0.id == id }) ?? tabs.first
            }
            return tabs.first
        }
        set {
            selectedTabId = newValue?.id
        }
    }

    // MARK: - Tab Operations

    /// Opens a file URL in this window. Focuses the existing tab if already open.
    func openTab(url: URL) {
        let standardized = url.standardizedFileURL
        if let existing = tabs.first(where: { $0.fileURL?.standardizedFileURL == standardized }) {
            selectedTabId = existing.id
            return
        }

        let newTab = TabItem(fileURL: url)
        tabs.append(newTab)
        selectedTabId = newTab.id
    }

    /// Appends a new blank tab and selects it.
    func addNewTab(fileURL: URL? = nil, text: String = "") {
        let newTab = TabItem(fileURL: fileURL, text: text)
        tabs.append(newTab)
        selectedTabId = newTab.id
    }

    /// Closes a tab. If it is the last tab, closes the window.
    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        if tabs.count <= 1 {
            NSApp.keyWindow?.performClose(nil)
            return
        }

        if selectedTabId == id {
            if index + 1 < tabs.count {
                selectedTabId = tabs[index + 1].id
            } else if index - 1 >= 0 {
                selectedTabId = tabs[index - 1].id
            }
        }

        tabs.remove(at: index)
    }

    func selectNextTab() {
        guard tabs.count > 1, let currentId = selectedTabId,
              let index = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        let nextIndex = (index + 1) % tabs.count
        selectedTabId = tabs[nextIndex].id
    }

    func selectPreviousTab() {
        guard tabs.count > 1, let currentId = selectedTabId,
              let index = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        let prevIndex = (index - 1 + tabs.count) % tabs.count
        selectedTabId = tabs[prevIndex].id
    }
}
