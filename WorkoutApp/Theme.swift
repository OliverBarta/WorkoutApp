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

    // Spacing
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 12

    // Fonts
    static let title = Font.system(.title, weight: .bold)
    static let body = Font.system(.body)
}
