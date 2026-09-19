//
//  HeaderStyle.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//
import SwiftUI

struct HeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .glassEffect(in: Capsule())
            .lineLimit(1)
    }
}

extension View {
    func headerStyle() -> some View {
        modifier(HeaderStyle())
    }
}

#Preview {
    Text("Home")
        .headerStyle()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
