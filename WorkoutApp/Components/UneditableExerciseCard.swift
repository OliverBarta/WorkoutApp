//
//  UneditableExerciseCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-05.
//

import SwiftUI


// uneditable exercise card.
// this is for when ur viewing someone else's workout
struct UneditableExerciseCard: View {
    let exercise: Exercise
    
    private let rowHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Text("\(exercise.restTime)")
                    .foregroundColor(.secondary)
                    
                Text("second rest timer")
                    .foregroundColor(.secondary)
            }
            
            List {
                ForEach(Array(exercise.reps.indices), id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(exercise.reps[index])")
                        Text("reps")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(exercise.weights[index])")
                        Text(exercise.type)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exercise.reps.remove(at: index)
                            exercise.weights.remove(at: index)
                        }
                        .labelStyle(.titleOnly)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listRowSpacing(0)
            .padding(.horizontal, -16)
            .frame(height: CGFloat(exercise.reps.count) * rowHeight)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    UneditableExerciseCard(
        exercise: Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb", order: 0)
    )
}
