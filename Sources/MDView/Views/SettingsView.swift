//
//  SettingsView.swift
//  MDView
//
//  macOS Settings Scene (Cmd+,) for configuring theme appearance and zoom scaling.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("markdown_appearance") private var appearance: AppAppearance = .system
    @AppStorage("markdown_font_scale") private var fontScale: Double = 1.0

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 450, height: 230)
    }

    private var generalTab: some View {
        Form {
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
                    Slider(value: $fontScale, in: 0.7...2.2, step: 0.1) {
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
    }
}
