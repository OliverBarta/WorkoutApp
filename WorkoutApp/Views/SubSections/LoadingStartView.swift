//
//  LoadingStartView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-27.
//


import SwiftUI

struct LoadingStartView: View {
    var body: some View {
        Image(systemName: "dumbbell")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        Text("Loading...")
        Button("Continue in offline mode") {
            
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    LoadingStartView()
}
