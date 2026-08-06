//
//  ClassColor.swift
//  UCAL
//

import SwiftUI

enum ClassColor: String, CaseIterable, Codable, Identifiable {
    case red, orange, yellow, green, mint, teal, blue, indigo, purple, pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        }
    }
}
