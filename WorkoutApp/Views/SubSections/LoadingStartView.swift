//
//  LoadingStartView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-27.
//


import SwiftUI

struct LoadingStartView: View {
    var body: some View {
        // keyframes rather than repeatForever, so the spin can be followed by a hold.
        // springs around once over the first 0.5s, overshooting 360 and settling back,
        // then sits still for the remaining 1.5s, on repeat
        KeyframeAnimator(initialValue: 0.0, repeating: true) { angle in
            Image(systemName: "dumbbell")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(angle))
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(360.0, duration: 2, spring: Spring(duration: 0.5, bounce: 0.45))
                LinearKeyframe(360.0, duration: 1.5)
            }
        }
        Text("Loading...")
        Button("Continue in offline mode") {
            // unfinished
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    LoadingStartView()
}
