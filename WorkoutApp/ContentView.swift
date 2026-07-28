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
    
    var body: some View {
        
        @Bindable var workoutSession = workoutSession
        
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                WorkoutView()
                    .tabItem {
                        Label("Workout", systemImage: "dumbbell.fill")
                    }
                RunningView()
                    .tabItem {
                        Label("Running", systemImage: "figure.run")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Routine.self, WorkoutHistoryEntry.self], inMemory: true)
        .environment(WorkoutSession())
}
