//
//  MDViewApp.swift
//  MDView
//
//  Custom Window & Tab Architecture:
//  - Multi-tab Window management with Safari pill-shaped tab bar
//  - Finder "Open With", Cmd+O, and relative links open as Tabs in the active window
//  - Cmd+N spawns a completely new separate window instance
//  - Cmd+T creates a new blank tab, Cmd+W closes the active tab (or window if last tab)
//  - Cmd+Shift+] and Cmd+Shift+[ cycle through tabs
//

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        WindowManager.shared.openURLsInActiveWindow(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            WindowManager.shared.openNewWindowAction?()
            return false
        }
        return true
    }
}

@main
struct MDViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @AppStorage("markdown_font_scale") private var fontScale: Double = 1.0
    @AppStorage("markdown_appearance") private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup(for: UUID.self) { $windowID in
            WindowRootView(windowID: windowID)
        }
        .defaultSize(width: 900, height: 680)
        .commands {
            TextEditingCommands()
            ToolbarCommands()

            // File Menu: Custom Window & Tab Management
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    openWindow(value: UUID())
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Tab") {
                    NotificationCenter.default.post(name: .createNewTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Open...") {
                    WindowManager.shared.showOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeCurrentTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Close Window") {
                    NSApp.keyWindow?.performClose(nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }

            // Save operations
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveActiveTab, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveAsActiveTab, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            // Tab Navigation Menu
            CommandMenu("Tab") {
                Button("Show Next Tab") {
                    NotificationCenter.default.post(name: .selectNextTab, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Show Previous Tab") {
                    NotificationCenter.default.post(name: .selectPreviousTab, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            }

            // Print and Export as PDF
            CommandGroup(replacing: .printItem) {
                Button("Print...") {
                    NotificationCenter.default.post(name: .printActiveDocument, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)

                Button("Export as PDF...") {
                    NotificationCenter.default.post(name: .exportPDFActiveDocument, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            // View Menu: Dynamic Font Scaling (Zoom)
            CommandGroup(after: .toolbar) {
                Section {
                    Button("Zoom In") {
                        fontScale = min(fontScale + 0.1, 2.5)
                    }
                    .keyboardShortcut("+", modifiers: .command)

                    Button("Zoom In (Equals)") {
                        fontScale = min(fontScale + 0.1, 2.5)
                    }
                    .keyboardShortcut("=", modifiers: .command)
                    .opacity(0)

                    Button("Zoom Out") {
                        fontScale = max(fontScale - 0.1, 0.7)
                    }
                    .keyboardShortcut("-", modifiers: .command)

                    Button("Actual Size") {
                        fontScale = 1.0
                    }
                    .keyboardShortcut("0", modifiers: .command)
                }
            }
        }

        // Native macOS Settings Scene (Cmd+,)
        Settings {
            SettingsView()
        }
    }
}
