//
//  ExcerciseCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct EditableStat: View {
    @Binding var value: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", value: $value, format: .number)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .foregroundColor(.secondary)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? Color(.tertiarySystemFill) : .clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct ExerciseCard: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    private let rowHeight: CGFloat = 52

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            List {
                ForEach(Array(exercise.sets.indices), id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        EditableStat(value: $exercise.sets[index])
                        Text("reps")
                            .foregroundColor(.secondary)
                        Spacer()
                        EditableStat(value: $exercise.weights[index])
                        Text(exercise.type)
                            .foregroundColor(.secondary)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exercise.sets.remove(at: index)
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
            .frame(height: CGFloat(exercise.sets.count) * rowHeight)

            Button("Add set") {
                if let lastSetReps = exercise.sets.last, let lastWeight = exercise.weights.last {
                    exercise.sets.append(lastSetReps)
                    exercise.weights.append(lastWeight)
                } else {
                    exercise.sets.append(0)
                    exercise.weights.append(0)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ExerciseCard(
        exercise: Exercise(name: "Bench Press", sets: [3,3,3], weights: [10, 10, 10], type: "lb", order: 0)
    )
}
