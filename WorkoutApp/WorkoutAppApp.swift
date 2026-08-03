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
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView()
                } else if authManager.isSignedIn {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .environment(workoutSession)
            .environment(authManager)
        }
        .modelContainer(for: [Routine.self, WorkoutHistoryEntry.self])
    }
}
