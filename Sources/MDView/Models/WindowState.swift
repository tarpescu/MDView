//
//  WindowState.swift
//  MDView
//
//  ObservableObject managing the multi-tab state for an individual Window instance,
//  routing global application events (Finder open, Cmd+O, Cmd+T, Cmd+W) to the active window,
//  and handling session preservation/restoration across app launches.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

extension Notification.Name {
    static let createNewTab = Notification.Name("MDView.createNewTab")
    static let closeCurrentTab = Notification.Name("MDView.closeCurrentTab")
    static let selectNextTab = Notification.Name("MDView.selectNextTab")
    static let selectPreviousTab = Notification.Name("MDView.selectPreviousTab")
    static let saveActiveTab = Notification.Name("MDView.saveActiveTab")
    static let saveAsActiveTab = Notification.Name("MDView.saveAsActiveTab")
}

/// UserDefaults keys shared by the app, the Settings scene and the window manager.
enum DefaultsKey {
    static let restorePreviousSession = "restore_previous_session"
    static let fontScale = "markdown_font_scale"
    static let appearance = "markdown_appearance"
    static let sidebarVisible = "outline_sidebar_visible"
    /// Pre-1.1 location of the session blob (migrated to Application Support).
    static let legacySessionData = "saved_session_data"
}

// MARK: - Persistent Session Models
struct SavedTabState: Codable {
    var fileURLString: String?
    var text: String?
    var viewMode: String
    var selectedHeadingId: String?
    var scrollToOffset: Int?
}

struct SavedWindowState: Codable {
    var id: UUID
    var tabs: [SavedTabState]
    var selectedTabURLString: String?
    var selectedIndex: Int
}

struct SavedSessionState: Codable {
    var windows: [SavedWindowState]
}

// MARK: - Global Window Manager
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private(set) var openWindows: [WindowState] = []
    weak var activeWindowState: WindowState?
    var pendingURLs: [URL] = []
    var openNewWindowAction: (() -> Void)?

    /// Windows from the previous launch that have not been re-opened yet.
    private var windowsToRestore: [SavedWindowState] = []
    /// The saved session is read exactly once per launch. Without this guard a
    /// later ⌘N would re-read the *current* session file and clone an existing
    /// window's tabs into the new window.
    private var didLoadSavedSession = false
    private var didRequestAdditionalWindows = false

    var allTabs: [TabItem] {
        openWindows.flatMap(\.tabs)
    }

    var totalTabCount: Int {
        openWindows.reduce(0) { $0 + $1.tabs.count }
    }

    var shouldRestoreSession: Bool {
        // The default (true) is registered in MDViewApp.init.
        UserDefaults.standard.bool(forKey: DefaultsKey.restorePreviousSession)
    }

    private var sessionFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("MDView", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.json")
    }

    func registerWindow(_ window: WindowState) {
        if !openWindows.contains(where: { $0.id == window.id }) {
            openWindows.append(window)
        }
        activeWindowState = window
        saveSession()
    }

    func unregisterWindow(_ window: WindowState) {
        // Save before removal so that closing the last window (which quits the
        // app) still leaves its tabs in the session, Safari-style.
        if totalTabCount > 0 {
            saveSession()
        }
        openWindows.removeAll { $0.id == window.id }
        if activeWindowState?.id == window.id {
            activeWindowState = openWindows.first
        }
    }

    // MARK: - Session Persistence & Restoration
    func saveSession() {
        guard shouldRestoreSession else {
            clearSession()
            return
        }

        var savedWindows: [SavedWindowState] = []
        for window in openWindows {
            let savedTabs: [SavedTabState] = window.tabs.compactMap { tab in
                if let fileURL = tab.fileURL {
                    return SavedTabState(
                        fileURLString: fileURL.absoluteString,
                        text: nil,
                        viewMode: tab.viewMode.rawValue,
                        selectedHeadingId: tab.selectedHeadingId,
                        scrollToOffset: tab.scrollToOffset
                    )
                }
                guard !tab.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                // Untitled drafts are persisted with their full text.
                return SavedTabState(
                    fileURLString: nil,
                    text: tab.text,
                    viewMode: tab.viewMode.rawValue,
                    selectedHeadingId: tab.selectedHeadingId,
                    scrollToOffset: tab.scrollToOffset
                )
            }

            guard !savedTabs.isEmpty else { continue }

            let selectedIndex = window.selectedTabId
                .flatMap { id in window.tabs.firstIndex(where: { $0.id == id }) } ?? 0
            savedWindows.append(SavedWindowState(
                id: window.id,
                tabs: savedTabs,
                selectedTabURLString: window.selectedTab?.fileURL?.absoluteString,
                selectedIndex: selectedIndex
            ))
        }

        guard !savedWindows.isEmpty else {
            clearSession()
            return
        }

        guard let data = try? JSONEncoder().encode(SavedSessionState(windows: savedWindows)),
              let fileURL = sessionFileURL else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.legacySessionData)
        if let fileURL = sessionFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func loadSavedSession() -> SavedSessionState? {
        guard shouldRestoreSession else { return nil }
        let decoder = JSONDecoder()

        if let fileURL = sessionFileURL,
           let data = try? Data(contentsOf: fileURL),
           let session = try? decoder.decode(SavedSessionState.self, from: data) {
            return session
        }

        // Migrate sessions written by earlier builds into UserDefaults.
        if let data = UserDefaults.standard.data(forKey: DefaultsKey.legacySessionData) {
            UserDefaults.standard.removeObject(forKey: DefaultsKey.legacySessionData)
            return try? decoder.decode(SavedSessionState.self, from: data)
        }

        return nil
    }

    /// Hands a window from the previous session to a newly created window.
    /// Returns `nil` once every saved window has been claimed.
    func popSavedWindow(for id: UUID) -> SavedWindowState? {
        if !didLoadSavedSession {
            didLoadSavedSession = true
            windowsToRestore = loadSavedSession()?.windows ?? []
        }
        guard !windowsToRestore.isEmpty else { return nil }

        let matchedIndex = windowsToRestore.firstIndex(where: { $0.id == id }) ?? 0
        return windowsToRestore.remove(at: matchedIndex)
    }

    /// Opens one window per remaining saved window. Every window calls this on
    /// appear, but only the first call (from the first window) has an effect.
    func restoreAdditionalWindows(using openWindow: OpenWindowAction) {
        guard !didRequestAdditionalWindows else { return }
        didRequestAdditionalWindows = true
        let remaining = windowsToRestore
        guard !remaining.isEmpty else { return }
        // Keep the entries queued: each new window claims its own by id.
        for window in remaining {
            openWindow(value: window.id)
        }
    }

    // MARK: - Unsaved Changes

    /// Tabs whose edits would be lost on quit. Untitled drafts are excluded
    /// while session restoration is on, because the session keeps their text.
    var tabsAtRiskOnQuit: [TabItem] {
        allTabs.filter { tab in
            guard tab.isModified else { return false }
            if tab.fileURL == nil {
                let hasText = !tab.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return hasText && !shouldRestoreSession
            }
            return true
        }
    }

    /// Tabs of `window` whose edits would be lost if it closed now. Untitled
    /// drafts are safe only when this is the last window and the session is
    /// kept (closing the last window keeps it in the session, like Safari).
    func tabsAtRisk(onClosing window: WindowState) -> [TabItem] {
        let sessionKeepsDrafts = shouldRestoreSession && openWindows.count <= 1
        return window.tabs.filter { tab in
            guard tab.isModified else { return false }
            if tab.fileURL == nil {
                let hasText = !tab.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return hasText && !sessionKeepsDrafts
            }
            return true
        }
    }

    // MARK: - Global File & Panel Opening
    /// Opens file URLs as tabs in the currently focused window, or launches a new window.
    func openURLsInActiveWindow(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        if let target = activeWindowState ?? openWindows.last {
            for url in urls {
                target.openTab(url: url)
            }
        } else {
            // No window is on screen yet (cold launch from Finder): queue the
            // URLs; the next window to register drains them.
            pendingURLs.append(contentsOf: urls)
            openNewWindowAction?()
        }
    }

    /// Opens URLs that arrived before any window was ready.
    func drainPendingURLs(into window: WindowState) {
        guard !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs.removeAll()
        for url in urls {
            window.openTab(url: url)
        }
    }

    /// Displays the native NSOpenPanel modal for selecting files to open as tabs.
    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = MarkdownFile.contentTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window) { response in
                MainActor.assumeIsolated {
                    if response == .OK {
                        WindowManager.shared.openURLsInActiveWindow(panel.urls)
                    }
                }
            }
        } else if panel.runModal() == .OK {
            openURLsInActiveWindow(panel.urls)
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

        // 1. Consume pending external URLs (e.g. from Finder double-click or CLI)
        let queued = WindowManager.shared.pendingURLs
        WindowManager.shared.pendingURLs.removeAll()

        // 2. Attempt session restoration if enabled
        if WindowManager.shared.shouldRestoreSession,
           let savedWindow = WindowManager.shared.popSavedWindow(for: id) {
            restore(savedWindow)
        }

        // 3. Append any queued external URLs
        for url in queued {
            if let existing = tab(for: url) {
                selectedTabId = existing.id
            } else {
                let tab = TabItem(fileURL: url)
                tabs.append(tab)
                selectedTabId = tab.id
            }
        }

        // 4. Fallback if still completely empty: single blank tab
        if tabs.isEmpty {
            let initialTab = TabItem()
            tabs.append(initialTab)
            selectedTabId = initialTab.id
        }
    }

    private func restore(_ savedWindow: SavedWindowState) {
        var restoredSelectedId: UUID?

        for savedTab in savedWindow.tabs {
            let tab: TabItem
            if let urlString = savedTab.fileURLString, let url = URL(string: urlString) {
                // Files deleted or moved since the last launch are skipped.
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                tab = TabItem(fileURL: url)
                tab.selectedHeadingId = savedTab.selectedHeadingId
                tab.scrollToOffset = savedTab.scrollToOffset
                if urlString == savedWindow.selectedTabURLString {
                    restoredSelectedId = tab.id
                }
            } else if let text = savedTab.text,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tab = TabItem(text: text)
                // A restored draft has never been saved: closing it must still
                // ask before discarding the text.
                tab.isModified = true
            } else {
                continue
            }
            if let mode = ViewMode(rawValue: savedTab.viewMode) {
                tab.viewMode = mode
            }
            tabs.append(tab)
        }

        if restoredSelectedId == nil, savedWindow.selectedIndex < tabs.count {
            restoredSelectedId = tabs[savedWindow.selectedIndex].id
        }
        selectedTabId = restoredSelectedId ?? tabs.first?.id
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
            WindowManager.shared.saveSession()
        }
    }

    private func tab(for url: URL) -> TabItem? {
        let standardized = url.standardizedFileURL
        return tabs.first(where: { $0.fileURL?.standardizedFileURL == standardized })
    }

    // MARK: - Tab Operations

    /// Opens a file URL in this window. Focuses the existing tab if already open.
    func openTab(url: URL) {
        if let existing = tab(for: url) {
            selectedTabId = existing.id
        } else {
            let newTab = TabItem(fileURL: url)
            // Replace a lone, pristine Untitled tab instead of keeping it around.
            if tabs.count == 1, let only = tabs.first, only.fileURL == nil,
               !only.isModified, only.text.isEmpty {
                tabs = [newTab]
            } else {
                tabs.append(newTab)
            }
            selectedTabId = newTab.id
        }
        WindowManager.shared.saveSession()
    }

    /// Appends a new blank tab and selects it.
    func addNewTab(fileURL: URL? = nil, text: String = "") {
        let newTab = TabItem(fileURL: fileURL, text: text)
        tabs.append(newTab)
        selectedTabId = newTab.id
        WindowManager.shared.saveSession()
    }

    /// Closes a tab, asking to save unsaved changes first.
    /// Closing the last tab of the window closes the window; closing the last
    /// tab of the whole app quits it.
    func closeTab(id: UUID) {
        guard let tabToClose = tabs.first(where: { $0.id == id }) else { return }

        guard tabToClose.isModified else {
            removeTab(id: id)
            return
        }

        selectedTabId = id
        switch Self.askToSaveChanges(of: tabToClose) {
        case .save:
            tabToClose.save { [weak self] saved in
                if saved { self?.removeTab(id: id) }
            }
        case .discard:
            removeTab(id: id)
        case .cancel:
            break
        }
    }

    /// Closes every tab except `id`, prompting for each unsaved one.
    func closeOtherTabs(except id: UUID) {
        for tab in tabs where tab.id != id {
            closeTab(id: tab.id)
        }
        selectedTabId = id
    }

    private func removeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        // Last tab of the whole application: quit and start fresh next time.
        if WindowManager.shared.totalTabCount == 0 {
            WindowManager.shared.clearSession()
            NSApp.terminate(nil)
            return
        }

        // Last tab of this window: close the window.
        if tabs.isEmpty {
            NSApp.keyWindow?.performClose(nil)
            WindowManager.shared.saveSession()
            return
        }

        if selectedTabId == id || !tabs.contains(where: { $0.id == selectedTabId }) {
            selectedTabId = tabs[min(index, tabs.count - 1)].id
        }

        WindowManager.shared.saveSession()
    }

    func selectNextTab() {
        guard tabs.count > 1, let currentId = selectedTabId,
              let index = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        selectedTabId = tabs[(index + 1) % tabs.count].id
        WindowManager.shared.saveSession()
    }

    func selectPreviousTab() {
        guard tabs.count > 1, let currentId = selectedTabId,
              let index = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        selectedTabId = tabs[(index - 1 + tabs.count) % tabs.count].id
        WindowManager.shared.saveSession()
    }

    // MARK: - Unsaved Changes Prompt
    enum SaveDecision { case save, discard, cancel }

    static func askToSaveChanges(of tab: TabItem) -> SaveDecision {
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes made to \u{201C}\(tab.title)\u{201D}?"
        alert.informativeText = "Your changes will be lost if you don\u{2019}t save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let dontSave = alert.addButton(withTitle: "Don\u{2019}t Save")
        dontSave.hasDestructiveAction = true

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .save
        case .alertThirdButtonReturn: return .discard
        default: return .cancel
        }
    }
}

// MARK: - Unsaved Changes Prompt (quit / window close)
@MainActor
enum UnsavedChanges {
    /// Asks what to do with `tabs` before an operation such as quitting or
    /// closing a window. Returns `true` when the operation may proceed.
    static func resolve(_ tabs: [TabItem], whileDoing operation: String) -> Bool {
        guard !tabs.isEmpty else { return true }

        if tabs.count == 1, let tab = tabs.first {
            switch WindowState.askToSaveChanges(of: tab) {
            case .save: return tab.saveSynchronously()
            case .discard: return true
            case .cancel: return false
            }
        }

        let alert = NSAlert()
        alert.messageText = "You have \(tabs.count) documents with unsaved changes. Do you want to save them before \(operation)?"
        alert.informativeText = "Your changes will be lost if you don\u{2019}t save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard Changes").hasDestructiveAction = true

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            // Stop at the first failure/cancel so nothing is silently lost.
            return tabs.allSatisfy { $0.saveSynchronously() }
        case .alertThirdButtonReturn:
            return true
        default:
            return false
        }
    }
}
