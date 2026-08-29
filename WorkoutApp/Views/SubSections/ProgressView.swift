//
//  ProgressView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import SwiftUI

// should really be called loading view
struct ProgressView: View {
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
            case .leftUp, .rightUp: return -3
            case .leftDown, .rightDown: return 0
            }
        }
    }

    var body: some View {
        HStack {
            PhaseAnimator(WalkPhase.allCases) { phase in
                Image(systemName: "dumbbell")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
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
        }
    }
}

#Preview {
    ProgressView()
}
