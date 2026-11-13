//
//  SafariTabBarView.swift
//  MDView
//
//  A horizontal, pill-shaped Safari-style tab bar.
//  Features rounded capsule pills for active tabs with borders/shadows,
//  document icons, unsaved change indicators, hover close buttons,
//  middle-click (scroll-wheel click) tab closing, and an integrated new-tab (+) button.
//

import SwiftUI
import AppKit

struct SafariTabBarView: View {
    @ObservedObject var windowState: WindowState
    @State private var hoveredTabId: UUID? = nil
    @State private var isHoveringNewTab: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(windowState.tabs) { tab in
                        SafariTabPill(
                            tab: tab,
                            isSelected: windowState.selectedTabId == tab.id,
                            isHovered: hoveredTabId == tab.id,
                            onSelect: {
                                windowState.selectedTabId = tab.id
                            },
                            onClose: {
                                windowState.closeTab(id: tab.id)
                            },
                            onCloseOthers: windowState.tabs.count > 1 ? {
                                windowState.closeOtherTabs(except: tab.id)
                            } : nil
                        )
                        .onHover { isHovered in
                            if isHovered {
                                hoveredTabId = tab.id
                            } else if hoveredTabId == tab.id {
                                hoveredTabId = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }

            // New Tab (+) Button
            Button(action: { windowState.addNewTab() }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isHoveringNewTab ? Color(nsColor: .quaternaryLabelColor).opacity(0.6) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            .help("New Tab (⌘T)")
            .accessibilityLabel("New Tab")
            .onHover { isHoveringNewTab = $0 }
        }
        .frame(height: 38)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(0.85)
        )
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Individual Safari Tab Pill
struct SafariTabPill: View {
    @ObservedObject var tab: TabItem
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    var onCloseOthers: (() -> Void)? = nil

    @State private var isHoveringClose: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Document Icon
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                // Title
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)

                // Unsaved modified indicator dot
                if tab.isModified {
                    Circle()
                        .fill(Color.secondary.opacity(0.8))
                        .frame(width: 5.5, height: 5.5)
                }

                // Close Button ('x')
                if isSelected || isHovered {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(isHoveringClose ? Color.primary : Color.secondary.opacity(0.8))
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(isHoveringClose ? Color(nsColor: .quaternaryLabelColor) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringClose = $0 }
                    .help("Close Tab (⌘W)")
                    .accessibilityLabel("Close \(tab.title)")
                } else {
                    Spacer().frame(width: 16)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .frame(height: 28)
            .background(pillBackground)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(tab.fileURL?.path ?? "Untitled document (not saved yet)")
        .accessibilityLabel(tab.isModified ? "\(tab.title), edited" : tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .overlay(
            MiddleClickDetector(action: onClose)
        )
        .contextMenu {
            Button("Close Tab", action: onClose)
            Button("Close Other Tabs") { onCloseOthers?() }
                .disabled(onCloseOthers == nil)

            if let fileURL = tab.fileURL {
                Divider()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fileURL.path, forType: .string)
                }
            }
        }
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 1.5, x: 0, y: 0.5)
        } else {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? Color(nsColor: .quaternaryLabelColor).opacity(0.35) : Color.clear)
        }
    }
}

// MARK: - Middle Click Detector (AppKit Bridge)
@MainActor
struct MiddleClickDetector: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> MiddleClickDetectorView {
        let view = MiddleClickDetectorView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: MiddleClickDetectorView, context: Context) {
        nsView.action = action
    }
}

@MainActor
final class MiddleClickDetectorView: NSView {
    var action: (() -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only claim hit when a middle-click (buttonNumber 2) event is in progress
        guard let event = NSApp.currentEvent,
              (event.type == .otherMouseDown || event.type == .otherMouseUp),
              event.buttonNumber == 2,
              window != nil else {
            return nil
        }

        let localPoint = convert(event.locationInWindow, from: nil)
        guard bounds.contains(localPoint) else {
            return nil
        }

        return self
    }

    override func otherMouseDown(with event: NSEvent) {
        if event.buttonNumber == 2 {
            action?()
        } else {
            super.otherMouseDown(with: event)
        }
    }

    override func otherMouseUp(with event: NSEvent) {
        // Swallow middle mouse up
    }
}
