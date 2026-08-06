//
//  LiquidGlassButtonStyle.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-02.
//

import SwiftUI

struct LiquidGlassButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white) // High contrast text for glass
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    // 1. The Glass Base: Standard thin material
                    ContainerRelativeShape()
                        .fill(.thinMaterial)
                    
                    // 2. The Liquid Core: Translucent tint of your primary theme color
                    ContainerRelativeShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    backgroundColor.opacity(0.85),
                                    backgroundColor.opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            // 4. The Glass Edge: Crisp, bright border wrapping the button
            .overlay(
                ContainerRelativeShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule()) // Smooth, liquid capsule edges
            // 5. Liquid Shadow: Inner/Outer soft glow using your theme color
            .shadow(color: backgroundColor.opacity(0.3), radius: 10, x: 0, y: 4)
            // 6. Tactile Press Interaction
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Convenient extension to make call-site clean
extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static func liquidGlass(tintColor: Color) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(backgroundColor: tintColor)
    }
}

#Preview {
    Button("Test button") {
        
    }
    .buttonStyle(.liquidGlass(tintColor: Theme.primary))
    
    Button("Test button 2") {
        
    }
    .buttonStyle(.liquidGlass(tintColor: Theme.grey))
}
