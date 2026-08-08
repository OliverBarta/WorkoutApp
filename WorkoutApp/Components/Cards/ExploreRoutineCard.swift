//
//  ExploreRoutineCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//


import SwiftUI

// the routine card you see on other people's profiles
struct ExploreRoutineCard: View {
    
    let routine: Routine

    @State private var showSpectateView: Bool = false
    
    var body: some View {
        Button {
            // code this in the future
            showSpectateView = true
        } label : {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(routine.name)
                        .font(.headline)
                    Spacer()
                }
                
                ForEach(routine.exercises) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(zip(exercise.reps, exercise.weights).enumerated()), id: \.offset) { index, pair in
                                    let (reps, weight) = pair
                                    Text("\(reps) x \(weight)\(exercise.type)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)
            .cornerRadius(12)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $showSpectateView) {
            RoutineSpectateView(routine: routine)
        }
    }
}

#Preview {
    ExploreRoutineCard(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb"),Exercise(name: "Squat", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
}
