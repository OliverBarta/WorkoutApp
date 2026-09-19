//
//  ContentView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(WorkoutSession.self) private var workoutSession

    @Environment(AuthManager.self) private var authManager

    @Environment(AppSettings.self) private var appSettings
    
    // query makes workoutLongSave the same everywhere so just type this and the variable is the same
    @Query private var workoutLongSave: [WorkOutLongSave]
    
    @State private var askToContinuePrevious: Bool = false

    var body: some View {
        
        @Bindable var workoutSession = workoutSession
        
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                RoutineSelectorView()
                    .tabItem {
                        Label("Routines", systemImage: "dumbbell.fill")
                    }
                RunningView()
                    .tabItem {
                        Label("Running", systemImage: "figure.run")
                    }
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
            }
            if workoutSession.isActive {
                CurrentActivityIndicatorCard()
                .frame(height: 60)
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $workoutSession.showActiveWorkout) {
            if let originalRoutine = workoutSession.originalRoutine {
                ZStack {
                    RoutineDuringWorkoutView(routine: originalRoutine)
                }
                .environment(workoutSession)
            }
        }
        .fullScreenCover(isPresented: $askToContinuePrevious) {
            ContinueWhereYouLeftOff(leftOff: workoutLongSave[0])
        }
        .task {
            askToContinuePrevious = checkWorkOutLongSave()
        }
    }
    private func checkWorkOutLongSave() -> Bool {
        if workoutSession.showActiveWorkout {
            return false
        }
        
        if workoutLongSave.count > 0 {
            return true
        }
        
        return false
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Routine.self, WorkoutHistoryEntry.self, WorkOutLongSave.self], inMemory: true)
        .environment(WorkoutSession())
        .environment(AuthManager())
        .environment(AppSettings())
}
