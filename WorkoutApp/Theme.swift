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
    static let grey = Color(.systemGray2)
    
    static let background = Color(.systemBackground)
    static let oppositeBackground = Color.primary
    
    static var checkedSetGreen: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.0, green: 0.25, blue: 0.1, alpha: 1.0)
            } else {
                return UIColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 0.7)
            }
        })
    }
    
    static var checkedSetGold: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.35, green: 0.28, blue: 0.05, alpha: 1.0)
            } else {
                return UIColor(red: 0.95, green: 0.8, blue: 0.35, alpha: 0.7)
            }
        })
    }

    static let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
    
    static let orange = Color.orange

    static var progressBarBackground = Color(.secondarySystemBackground)
    
    static var progressBar = Color.blue
    
    static let cardBackground = Color(.secondarySystemBackground)
    
    // Spacing
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 12

    // Fonts
    static let title = Font.system(.title, weight: .bold)
    static let body = Font.system(.body)
}
