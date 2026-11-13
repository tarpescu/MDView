//
//  WindowRootView.swift
//  MDView
//
//  Root view for an individual Window instance. Houses the Safari-style
//  pill tab bar and hosts the active tab's ContentView.
//

import SwiftUI
import AppKit

struct WindowRootView: View {
    let windowID: UUID?
    @StateObject private var windowState: WindowState
    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.openWindow) private var openWindow

    init(windowID: UUID?) {
        self.windowID = windowID
        _windowState = StateObject(wrappedValue: WindowState(id: windowID ?? UUID()))
    }

    var body: some View {
        VStack(spacing: 0) {
            SafariTabBarView(windowState: windowState)

            if let activeTab = windowState.selectedTab {
                ContentView(tab: activeTab, windowState: windowState)
                    .id(activeTab.id)
            } else {
                emptyWindowView
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        // Ask about unsaved tabs before the window itself closes.
        .background(WindowCloseInterceptor {
            UnsavedChanges.resolve(
                WindowManager.shared.tabsAtRisk(onClosing: windowState),
                whileDoing: "closing this window"
            )
        })
        // Markdown/text files dragged from Finder onto the window open as tabs.
        // (The editor handles its own drops, see MarkdownTextView.)
        .dropDestination(for: URL.self) { urls, _ in
            let files = urls.filter { $0.isFileURL && MarkdownFile.isOpenable($0) }
            for url in files { windowState.openTab(url: url) }
            return !files.isEmpty
        }
        .onAppear {
            WindowManager.shared.registerWindow(windowState)
            // At cold launch, Finder's open event can arrive after this window's
            // state was created but before it appeared.
            WindowManager.shared.drainPendingURLs(into: windowState)
            WindowManager.shared.openNewWindowAction = {
                openWindow(value: UUID())
            }
            WindowManager.shared.restoreAdditionalWindows(using: openWindow)
        }
        .onDisappear {
            WindowManager.shared.unregisterWindow(windowState)
        }
        .onChange(of: controlActiveState) { _, newState in
            if newState == .key {
                WindowManager.shared.activeWindowState = windowState
            }
        }
        // Menu command notification bindings
        .onReceive(NotificationCenter.default.publisher(for: .createNewTab)) { _ in
            guard controlActiveState == .key else { return }
            windowState.addNewTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeCurrentTab)) { _ in
            guard controlActiveState == .key, let activeId = windowState.selectedTabId else { return }
            windowState.closeTab(id: activeId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectNextTab)) { _ in
            guard controlActiveState == .key else { return }
            windowState.selectNextTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectPreviousTab)) { _ in
            guard controlActiveState == .key else { return }
            windowState.selectPreviousTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveActiveTab)) { _ in
            guard controlActiveState == .key else { return }
            windowState.selectedTab?.save()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveAsActiveTab)) { _ in
            guard controlActiveState == .key else { return }
            windowState.selectedTab?.saveAs()
        }
    }

    private var emptyWindowView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.dashed")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No Open Tabs")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("New Tab (⌘T)") {
                windowState.addNewTab()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
