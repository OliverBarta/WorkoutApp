//
//  WorkoutTimer.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-21.
//

import SwiftUI
import SwiftData

// the timer at the top of a workout session counting the total time a workout has lasted
struct WorkoutTimer: View {
    
    @Environment(WorkoutSession.self) private var workoutSession
    
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    private var formattedTime: String {
        return SecondsFormatted(elapsedSeconds)
    }

    var body: some View {
        Text(formattedTime)
            .onAppear {
                // gets the start date of the timer from the workoutSession environment variable
                if let startDate = workoutSession.workoutStartDate {
                    elapsedSeconds = Int(Date().timeIntervalSince(startDate))
                }
                
                // continuously counts every second it's open
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if let startDate = workoutSession.workoutStartDate {
                        elapsedSeconds = Int(Date().timeIntervalSince(startDate))
                    }
                }
            }
            .onDisappear {
                // stops processing the timer loops when the screen closes
                timer?.invalidate()
                timer = nil
            }
    }
}

#Preview {
    WorkoutTimer()
        .environment(WorkoutSession())
}
