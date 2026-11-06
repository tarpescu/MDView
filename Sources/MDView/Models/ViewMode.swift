//
//  ViewMode.swift
//  MDView
//

import Foundation

enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case viewer = "Viewer"
    case split = "Split"
    case editor = "Editor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .viewer:
            return "doc.richtext"
        case .split:
            return "square.split.2x1"
        case .editor:
            return "doc.text"
        }
    }
}
