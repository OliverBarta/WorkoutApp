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
    @Environment(AppSettings.self) private var appSettings
    
    // if the search bar is focused or not
    @FocusState private var isSearchFocused: Bool

    var filtered: [ExerciseTemplate] {
        if searchText.isEmpty {
            return ExerciseCatalog.all
        }
        return ExerciseCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            List(filtered) { exercise in
                
                Button {
                    var orderOfNewExercise = 0
                    
                    if appSettings.addExerciseOn == "bottom" {
                        orderOfNewExercise = routine.exercises.count
                    } else {
                        orderOfNewExercise = 0
                        
                        for exercise in routine.exercises {
                            exercise.order += 1
                        }
                    }
                    
                    let newExercise = Exercise(
                        name: exercise.name,
                        reps: [8],
                        seconds: [0],
                        completedSets: [],
                        weights: [0],
                        restTime: appSettings.defaultRestSeconds,
                        repsColumn: true,
                        weightColumn: true,
                        secsColumn: false,
                        order: orderOfNewExercise
                    )
                    
                    routine.exercises.append(newExercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(Theme.oppositeBackground)
                        
                        Text((exercise.primaryMuscles + exercise.secondaryMuscles).joined(separator: ", ").capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .padding(.top)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            VStack {
                Spacer()
                
                CustomSearchBar(text: $searchText, isFocused: $isSearchFocused, placeHolderText: "Find Exercise")
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
}

#Preview {
    ExerciseSearchView(routine: Routine(name: "Routine 1"))
        .environment(AppSettings())
}
