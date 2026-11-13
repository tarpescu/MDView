//
//  SettingsView.swift
//  MDView
//
//  macOS Settings Scene (Cmd+,) for configuring session restoration,
//  theme appearance, and zoom scaling.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(DefaultsKey.restorePreviousSession) private var restorePreviousSession: Bool = true
    @AppStorage(DefaultsKey.appearance) private var appearance: AppAppearance = .system
    @AppStorage(DefaultsKey.fontScale) private var fontScale: Double = 1.0

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 470, height: 320)
    }

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Restore windows and tabs on reopen", isOn: $restorePreviousSession)
            } header: {
                Text("Startup")
            } footer: {
                Text("MDView reopens the windows and tabs you had open, including unsaved Untitled drafts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Appearance:", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { item in
                        Label(item.rawValue, systemImage: item.icon).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text("Sepia mode applies a soothing warm paper tint with soft ink typography.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Slider(value: $fontScale, in: FontScale.range, step: FontScale.step) {
                        Text("Default Zoom:")
                    }
                    Text("\(Int(round(fontScale * 100)))%")
                        .font(.body.monospacedDigit())
                        .frame(width: 48, alignment: .trailing)
                }

                Button("Reset to Actual Size (100%)") {
                    fontScale = 1.0
                }
                .disabled(fontScale == 1.0)
            } footer: {
                Text("You can also zoom dynamically using ⌘+, ⌘-, and ⌘0.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .onChange(of: restorePreviousSession) { _, isOn in
            // Apply immediately: write the current session or delete the stored one.
            if isOn { WindowManager.shared.saveSession() } else { WindowManager.shared.clearSession() }
        }
    }
}
