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
                    Toggle("Reps column", isOn: $exercise.repsColumn)
                    Toggle("Weight column", isOn: $exercise.weightColumn)
                    Toggle("Seconds column", isOn: $exercise.secsColumn)

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
                        if exercise.repsColumn {
                            Spacer()
                            EditableStat(value: $exercise.reps[index])
                            Text("reps")
                                .foregroundColor(.secondary)
                        }
                        if exercise.weightColumn {
                            Spacer()
                            EditableStatDouble(value: $exercise.weights[index])
                            Text("lb")
                                .foregroundColor(.secondary)
                        }
                        if exercise.secsColumn {
                            Spacer()
                            EditableStat(value: $exercise.seconds[index])
                            Text("sec")
                                .foregroundColor(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exercise.removeSet(at: index)
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

            Button {
                exercise.addSet()
            } label : {
                Text("Add set")
                Image(systemName: "plus")
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ExerciseEditCard(
        exercise: Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 0)
    )
}
