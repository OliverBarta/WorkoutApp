//
//  LoadingStartView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-27.
//


import SwiftUI

struct LoadingStartView: View {
    // One step of the walk - left end lifts, then settles, right end lifts, then settles
    private enum WalkPhase: CaseIterable {
        case leftUp, leftDown, rightUp, rightDown

        var tilt: Double {
            switch self {
            case .leftUp: return -16
            case .rightUp: return 16
            case .leftDown, .rightDown: return 0
            }
        }

        var lift: CGFloat {
            switch self {
            case .leftUp, .rightUp: return -100
            case .leftDown, .rightDown: return 0
            }
        }
    }

    var body: some View {
        PhaseAnimator(WalkPhase.allCases) { phase in
            Image(systemName: "dumbbell")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(phase.tilt))
                .offset(y: phase.lift)
        } animation: { phase in
            switch phase {
            case .leftUp, .rightUp:
                return .spring(response: 0.32, dampingFraction: 0.45)
            case .leftDown, .rightDown:
                return .spring(response: 0.28, dampingFraction: 0.55)
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
