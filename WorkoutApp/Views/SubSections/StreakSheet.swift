//
//  StreakSheet.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-19.
//

import SwiftUI

struct StreakSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 40))
                .foregroundColor(Theme.orange)

            Text("Streaks")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.oppositeBackground)

            Text("Your streak counts the number of consecutive weeks that you've logged a workout. Complete a workout at least one time from saturday to sunday to keep it growing — miss a week and your streak resets back to zero.")
                .font(.body)
                .foregroundColor(Theme.oppositeBackground)
                .padding(.horizontal)
            
            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.liquidGlass(tintColor: Theme.primary))
            .padding(.horizontal)
        }
        .padding(.top, 60)
        .padding(.bottom, 24)
    }
}

#Preview {
    StreakSheet()
}
