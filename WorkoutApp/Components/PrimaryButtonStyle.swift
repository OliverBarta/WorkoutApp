//
//  PrimaryButtonStyle.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.primary)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.7 : 1.0) // dims slightly when tapped
    }
}
