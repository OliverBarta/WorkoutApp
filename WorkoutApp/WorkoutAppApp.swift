//
//  WorkoutAppApp.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

@main
struct WorkoutAppApp: App {
    @State private var workoutSession = WorkoutSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(workoutSession)
        }
        .modelContainer(for: [Routine.self, WorkoutHistoryEntry.self])
    }
}
