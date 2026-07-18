//  ExerciseSearchView.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import SwiftUI

struct ExerciseSearchView: View {
    @State private var searchText = ""
    
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
                  HStack {
                      Image(exercise.imageName)
                          .resizable()
                          .scaledToFit()
                          .frame(width: 50, height: 50)
                      
                      VStack(alignment: .leading) {
                          Text(exercise.name)
                              .font(.headline)
                          Text(exercise.muscleGroup)
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
    ExerciseSearchView()
}
