//
//  RoutineEditView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RoutineEditView: View {
    @Bindable var routine: Routine

    private var sortedExercises: [Exercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack {
            Text("Edit \(routine.name)")
                .headerStyle()
            
            ScrollView {
                TextField("Routine name", text: $routine.name)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Add Exercise") {
                    let newExercise = Exercise(
                        name: "New Exercise",
                        sets: [10, 10, 10],
                        weights: [0, 0, 0],
                        type: "lb",
                        order: routine.exercises.count
                    )
                    routine.exercises.append(newExercise)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                
                ForEach(sortedExercises) { exercise in
                    ExerciseCard(exercise: exercise)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    
                }
                .padding(.top, 20)
                
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Edit Routine")
    }
}

#Preview {
    RoutineEditView(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", sets: [3,3,3], weights: [10, 10, 10], type: "lb")]))
}
