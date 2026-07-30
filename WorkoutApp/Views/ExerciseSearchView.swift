//  ExerciseSearchView.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import SwiftUI

struct ExerciseSearchView: View {
    @State private var searchText = ""

    @Bindable var routine: Routine

    @Environment(\.dismiss) private var dismiss

    var filtered: [ExerciseTemplate] {
        if searchText.isEmpty {
            return ExerciseCatalog.all
        }
        return ExerciseCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    let newExercise = Exercise(
                        name: exercise.name,
                        reps: [8],
                        completedSets: [],
                        weights: [0],
                        restTime: 60,
                        type: "lb",
                        order: routine.exercises.count
                    )

                    routine.exercises.append(newExercise)
                    dismiss()

                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(Theme.oppositeBackground)

                        Text(exercise.primaryMuscles.joined(separator: ", ").capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
        }
    }
}

#Preview {
    ExerciseSearchView(routine: Routine(name: "Routine 1"))
}
