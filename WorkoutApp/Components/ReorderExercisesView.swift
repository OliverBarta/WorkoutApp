//
//  ReorderExercisesView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-05.
//

import SwiftUI
import SwiftData

// the exercise cards are too tall and too interactive (nested set list, swipe actions, text fields)
// to drag directly, so reordering happens here instead: a name-only list pinned to edit mode so the
// native drag handles are always there.
struct ReorderExercisesView: View {
    var routine: Routine

    @Environment(\.dismiss) private var dismiss

    // local copy so the ForEach data doesn't shift underneath the drag animation
    @State private var ordered: [Exercise] = []

    var body: some View {
        VStack(spacing: 0) {
            Text("Reorder exercises")
                .font(.headline)
                .padding(.top)

            List {
                ForEach(ordered) { exercise in
                    Text(exercise.name)
                        .font(.headline)
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .onMove(perform: move)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)// hides the side scroll bar
            .environment(\.editMode, .constant(.active))// always draggable, so no Edit button is needed
        }
        .onAppear {
            ordered = routine.exercises.sorted { $0.order < $1.order }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        ordered.move(fromOffsets: source, toOffset: destination)

        // renumbering the whole list keeps order dense (0..<n), which also clears out any duplicate
        // order values left behind by earlier deletes
        for (index, exercise) in ordered.enumerated() {
            exercise.order = index
        }
    }
}

#Preview {
    let names = ["Barbell bench press", "Incline dumbbell press", "Cable fly", "Tricep pushdown"]

    let exercises: [Exercise] = names.enumerated().map { index, name in
        Exercise(name: name, reps: [8], seconds: [0], completedSets: [], weights: [135], restTime: 60, order: index)
    }

    ReorderExercisesView(routine: Routine(name: "Push day", exercises: exercises))
}
