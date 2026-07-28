//  ExerciseSearchView.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import SwiftUI

struct ExerciseSearchView: View {
    @State private var searchText = ""
    
    // bindable basically makes the variable passed in call by reference. So you can add the routine to this variable and it will do the same change to the routine that was put into this bindable variable.
    @Bindable var routine: Routine
    
    // environment variable so we can dismiss the .sheet exerciseSearchView is wrapped in
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
              List(filtered, id: \.name) { exercise in
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
                      HStack {
                          Image(exercise.imageName)
                              .resizable()
                              .scaledToFit()
                              .frame(width: 50, height: 50)
                          
                          VStack(alignment: .leading) {
                              Text(exercise.name)
                                  .font(.headline)
                                  .foregroundColor(Theme.oppositeBackground)
                              Text(exercise.muscleGroup)
                                  .font(.subheadline)
                                  .foregroundStyle(.secondary)
                                  .foregroundColor(Theme.oppositeBackground)
                              
                          }
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
