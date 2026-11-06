//
//  AppAppearance.swift
//  MDView
//
//  Appearance modes: System, Light, Dark, and a warm "Sepia/Paper" mode
//  inspired by TextEdit and Safari Reader.
//

import SwiftUI
import AppKit

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        case .sepia: return "book.closed"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .sepia: return .light
        case .dark: return .dark
        }
    }

    // MARK: - SwiftUI Colors
    var backgroundColor: Color {
        switch self {
        case .system: return Color(nsColor: .textBackgroundColor)
        case .light: return Color.white
        case .dark: return Color(nsColor: .textBackgroundColor)
        case .sepia: return Color(red: 0.97, green: 0.95, blue: 0.89) // #F8F2E4 warm paper
        }
    }

    var secondaryBackgroundColor: Color {
        switch self {
        case .system: return Color(nsColor: .windowBackgroundColor)
        case .light: return Color(nsColor: .windowBackgroundColor)
        case .dark: return Color(nsColor: .windowBackgroundColor)
        case .sepia: return Color(red: 0.93, green: 0.90, blue: 0.83) // #EDE6D4
        }
    }

    var textColor: Color {
        switch self {
        case .system: return Color.primary
        case .light: return Color.black
        case .dark: return Color.white
        case .sepia: return Color(red: 0.27, green: 0.22, blue: 0.16) // #453828 warm ink
        }
    }

    // MARK: - AppKit Colors for NSTextView
    var nsBackgroundColor: NSColor {
        switch self {
        case .system: return .textBackgroundColor
        case .light: return .white
        case .dark: return .textBackgroundColor
        case .sepia: return NSColor(red: 0.97, green: 0.95, blue: 0.89, alpha: 1.0)
        }
    }

    var nsTextColor: NSColor {
        switch self {
        case .system: return .textColor
        case .light: return .black
        case .dark: return .white
        case .sepia: return NSColor(red: 0.27, green: 0.22, blue: 0.16, alpha: 1.0)
        }
    }
}
