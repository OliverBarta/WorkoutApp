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
    }
}

extension View {
    func headerStyle() -> some View {
        modifier(HeaderStyle())
    }
}
