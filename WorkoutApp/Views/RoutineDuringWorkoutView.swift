//
//  RoutineDuringWorkoutView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-17.
//

import SwiftUI
import SwiftData

struct RoutineDuringWorkoutView: View {
    @Bindable var routine: Routine

    private var sortedExercises: [Exercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack {
            Text(routine.name)
                .headerStyle()
            
            ScrollView {

                Button("Add Exercise") {
                    let newExercise = Exercise(
                        name: "New Exercise",
                        reps: [10, 10, 10],
                        weights: [0, 0, 0],
                        restTime: 60,
                        type: "lb",
                        order: routine.exercises.count
                    )
                    routine.exercises.append(newExercise)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                
                ForEach(sortedExercises) { exercise in
                    ExerciseDuringWorkoutCard(exercise: exercise)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    
                }
                .padding(.top, 20)
                
            }
            .frame(maxHeight: .infinity)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle("Edit Routine")
    }
}

#Preview {
    RoutineDuringWorkoutView(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], weights: [10, 10, 10], restTime: 60, type: "lb")]))
}
