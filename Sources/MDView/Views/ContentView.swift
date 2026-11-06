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
    @AppStorage("markdown_font_scale") private var fontScale: Double = 1.0
    @AppStorage("markdown_appearance") private var appearance: AppAppearance = .system

    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.controlActiveState) private var controlActiveState

    private var headings: [MarkdownHeading] {
        MarkdownHeading.parse(from: tab.text)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            TableOfContentsSidebarView(
                headings: headings,
                selectedHeadingId: $tab.selectedHeadingId,
                onSelect: navigateToHeading
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 230, max: 320)
        } detail: {
            VStack(spacing: 0) {
                mainEditorArea
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
        .onChange(of: tab.text) { _, _ in
            tab.isModified = true
        }
        // Print & PDF Export handlers
        .onReceive(NotificationCenter.default.publisher(for: .printActiveDocument)) { _ in
            guard controlActiveState == .key else { return }
            printDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPDFActiveDocument)) { _ in
            guard controlActiveState == .key else { return }
            exportAsPDF()
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
    private var mainEditorArea: some View {
        switch tab.viewMode {
        case .viewer:
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

        case .split:
            HSplitView {
                NativeMarkdownEditorView(
                    text: $tab.text,
                    scrollToOffset: $tab.scrollToOffset,
                    fontScale: fontScale,
                    appearance: appearance,
                    onModeSwitch: { tab.viewMode = $0 }
                )
                .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
                .background(appearance.backgroundColor)

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
                .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
            }

        case .editor:
            NativeMarkdownEditorView(
                text: $tab.text,
                scrollToOffset: $tab.scrollToOffset,
                fontScale: fontScale,
                appearance: appearance,
                onModeSwitch: { tab.viewMode = $0 }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(appearance.backgroundColor)
        }
    }

    private func navigateToHeading(_ heading: MarkdownHeading) {
        tab.selectedHeadingId = heading.id
        tab.scrollToOffset = heading.characterOffset
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if sidebarVisibility == .detailOnly {
                sidebarVisibility = .all
            } else {
                sidebarVisibility = .detailOnly
            }
        }
    }

    // MARK: - Native Quartz Print & PDF
    private func printDocument() {
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.topMargin = 40
        printInfo.bottomMargin = 40
        printInfo.leftMargin = 40
        printInfo.rightMargin = 40
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let printableContent = PrintableMarkdownContainer(
            markdown: tab.text,
            fileURL: tab.fileURL,
            fontScale: fontScale
        )
        .frame(width: printInfo.paperSize.width - 80)

        let hostingView = NSHostingView(rootView: printableContent)
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(
            origin: .zero,
            size: NSSize(width: printInfo.paperSize.width - 80, height: max(fittingSize.height, printInfo.paperSize.height - 80))
        )
        hostingView.layoutSubtreeIfNeeded()

        let operation = NSPrintOperation(view: hostingView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true

        if let window = NSApp.keyWindow {
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        }
    }

    private func exportAsPDF() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        let defaultName = tab.fileURL?.deletingPathExtension().lastPathComponent ?? tab.title
        savePanel.nameFieldStringValue = "\(defaultName).pdf"
        savePanel.canCreateDirectories = true

        guard let window = NSApp.keyWindow else { return }
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK, let targetURL = savePanel.url else { return }

            let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
            printInfo.topMargin = 40
            printInfo.bottomMargin = 40
            printInfo.leftMargin = 40
            printInfo.rightMargin = 40
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = false
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic

            printInfo.jobDisposition = .save
            printInfo.dictionary().setObject(targetURL, forKey: NSPrintInfo.AttributeKey.jobSavingURL as NSCopying)

            let printableContent = PrintableMarkdownContainer(
                markdown: tab.text,
                fileURL: tab.fileURL,
                fontScale: 1.0
            )
            .frame(width: printInfo.paperSize.width - 80)

            let hostingView = NSHostingView(rootView: printableContent)
            let fittingSize = hostingView.fittingSize
            hostingView.frame = NSRect(
                origin: .zero,
                size: NSSize(width: printInfo.paperSize.width - 80, height: max(fittingSize.height, printInfo.paperSize.height - 80))
            )
            hostingView.layoutSubtreeIfNeeded()

            let operation = NSPrintOperation(view: hostingView, printInfo: printInfo)
            operation.showsPrintPanel = false
            operation.showsProgressPanel = false
            operation.run()
        }
    }
}
