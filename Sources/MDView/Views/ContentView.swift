//
//  ContentView.swift
//  MDView
//
//  Main editor & viewer view bound to an individual TabItem.
//  Maintains per-tab view mode (Viewer, Split, Editor), outline headings,
//  relative link handling routed to the WindowState tab manager, and statistics.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var tab: TabItem
    var windowState: WindowState? = nil

    // User preferences persisted via AppStorage
    @AppStorage(DefaultsKey.fontScale) private var fontScale: Double = 1.0
    @AppStorage(DefaultsKey.appearance) private var appearance: AppAppearance = .system
    // Persisted so the outline keeps its state when switching tabs or relaunching.
    @AppStorage(DefaultsKey.sidebarVisible) private var isSidebarVisible: Bool = true

    @Environment(\.controlActiveState) private var controlActiveState

    private var sidebarVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { isSidebarVisible ? .all : .detailOnly },
            set: { isSidebarVisible = ($0 != .detailOnly) }
        )
    }

    var body: some View {
        // Parsed once per render and shared by the outline and the preview(s).
        let headings = MarkdownHeading.parse(from: tab.text)

        NavigationSplitView(columnVisibility: sidebarVisibility) {
            TableOfContentsSidebarView(
                headings: headings,
                selectedHeadingId: $tab.selectedHeadingId,
                onSelect: navigateToHeading
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 230, max: 320)
        } detail: {
            VStack(spacing: 0) {
                mainEditorArea(headings: headings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                StatusBarView(statistics: tab.statistics)
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .preferredColorScheme(appearance.colorScheme)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Outline Sidebar")
                .accessibilityLabel("Toggle Outline Sidebar")
            }

            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $tab.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("Toggle between Viewer (⌘1), Split (⌘2), and Editor (⌘3)")
            }

            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { item in
                            Label(item.rawValue, systemImage: item.icon).tag(item)
                        }
                    }
                } label: {
                    Image(systemName: appearance.icon)
                }
                .help("Appearance (System, Light, Dark, Sepia)")
                .accessibilityLabel("Appearance")
            }
        }
        // Asynchronous, debounced statistics computation keeping typing at 120 FPS
        .task(id: tab.text) {
            do {
                try await Task.sleep(nanoseconds: 120_000_000)
            } catch {
                return
            }
            let calculated = await DocumentStatistics.calculate(for: tab.text)
            self.tab.statistics = calculated
        }
        // Print & PDF Export handlers
        .onReceive(NotificationCenter.default.publisher(for: .printActiveDocument)) { _ in
            guard controlActiveState == .key else { return }
            MarkdownPrinter.print(tab, fontScale: fontScale)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPDFActiveDocument)) { _ in
            guard controlActiveState == .key else { return }
            MarkdownPrinter.exportPDF(tab)
        }
        .background(
            Group {
                Button("") { tab.viewMode = .viewer }
                    .keyboardShortcut("1", modifiers: .command)
                Button("") { tab.viewMode = .split }
                    .keyboardShortcut("2", modifiers: .command)
                Button("") { tab.viewMode = .editor }
                    .keyboardShortcut("3", modifiers: .command)
            }
            .opacity(0)
        )
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private func mainEditorArea(headings: [MarkdownHeading]) -> some View {
        switch tab.viewMode {
        case .viewer:
            preview(headings: headings)

        case .split:
            HSplitView {
                editor
                    .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
                preview(headings: headings)
                    .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
            }

        case .editor:
            editor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func preview(headings: [MarkdownHeading]) -> some View {
        MarkdownPreviewView(
            markdown: tab.text,
            headings: headings,
            targetHeadingId: $tab.selectedHeadingId,
            fileURL: tab.fileURL,
            fontScale: fontScale,
            appearance: appearance,
            onOpenRelativeTab: { url in
                windowState?.openTab(url: url)
            }
        )
    }

    private var editor: some View {
        NativeMarkdownEditorView(
            text: $tab.text,
            scrollToOffset: $tab.scrollToOffset,
            fontScale: fontScale,
            appearance: appearance,
            documentDirectory: tab.baseDirectory,
            onModeSwitch: { tab.viewMode = $0 },
            onOpenFiles: { urls in
                for url in urls { windowState?.openTab(url: url) }
            }
        )
        .background(appearance.backgroundColor)
    }

    private func navigateToHeading(_ heading: MarkdownHeading) {
        tab.selectedHeadingId = heading.id
        tab.scrollToOffset = heading.characterOffset
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSidebarVisible.toggle()
        }
    }
}
