//
//  ExcerciseEditCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData


// the exercise card for edit view
struct ExerciseEditCard: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    private let rowHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                EditableTitle(name: $exercise.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Menu {
                    Button("Change type") {
                        if exercise.type == "lb" {
                            exercise.type = "kg"
                        } else if exercise.type == "kg" {
                            exercise.type = "sec"
                        } else {
                            exercise.type = "lb"
                        }
                    }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(exercise)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .frame(alignment: .trailing)
            }
            HStack {
                EditableStat(value: $exercise.restTime)
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
                        EditableStat(value: $exercise.reps[index])
                        Text("reps")
                            .foregroundColor(.secondary)
                        Spacer()
                        EditableStat(value: $exercise.weights[index])
                        Text(exercise.type)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exercise.reps.remove(at: index)
                            exercise.weights.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listRowSpacing(0)
            .padding(.horizontal, -16)
            .frame(height: CGFloat(exercise.reps.count) * rowHeight)

            Button("Add set") {
                if let lastSetReps = exercise.reps.last, let lastWeight = exercise.weights.last {
                    exercise.reps.append(lastSetReps)
                    exercise.weights.append(lastWeight)
                } else {
                    exercise.reps.append(0)
                    exercise.weights.append(0)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ExerciseEditCard(
        exercise: Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb", order: 0)
    )
}
