//
//  Theme.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI

enum Theme {
    // Colors
    static let primary = Color.blue
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let lightGreen = Color(red: 0.6, green: 0.9, blue: 0.6, opacity: 0.7)

    // Spacing
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 12

    // Fonts
    static let title = Font.system(.title, weight: .bold)
    static let body = Font.system(.body)
}
