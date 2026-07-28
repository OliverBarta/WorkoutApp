//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            ScrollView {
                Text("See you and the people you follow's workout and run history here. Coming soon.")
                    .padding(.top, 45)
                    .padding(.horizontal)
                
                WorkoutHistoryCard(
                    entry: WorkoutHistoryEntry(
                        routineName: "Push Day",
                        durationSeconds: 2400,
                        exerciseSnapshots: [
                            ExerciseSnapshot(name: "Bench Press", reps: [8,8,8], weights: [135,135,135], type: "lb")
                        ]
                    )
                )
                
                WorkoutHistoryCard(
                    entry: WorkoutHistoryEntry(
                        routineName: "Push Day",
                        durationSeconds: 2400,
                        exerciseSnapshots: [
                            ExerciseSnapshot(name: "Bench Press", reps: [8,8,8], weights: [135,135,135], type: "lb")
                        ]
                    )
                )
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Home")
                        .headerStyle()
                    
                    Spacer()
                }
            }
            
        }
    }
}

#Preview {
    HomeView()
}
