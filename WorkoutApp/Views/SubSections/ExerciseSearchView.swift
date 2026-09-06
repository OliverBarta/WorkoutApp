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
    
    var filteredRecentExerciseNames: [String] {
        if searchText.isEmpty {
            return Array(appSettings.exerciseSetup.keys)
        }
        let exerciseNames: [String] = Array(appSettings.exerciseSetup.keys)
        
        return exerciseNames.filter{
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @State private var showUsedExercises = true

    var body: some View {
        ZStack {
            List {
                if !filteredRecentExerciseNames.isEmpty {
                    Section {
                        if showUsedExercises {
                            ForEach(filteredRecentExerciseNames, id: \.self) { name in
                                Button {
                                    var orderOfNewExercise = 0

                                    if appSettings.addExerciseOn == "bottom" {
                                        // one past the highest existing order, not the count, so deleted
                                        // exercises don't leave the new one colliding with a used order
                                        orderOfNewExercise = (routine.exercises.map(\.order).max() ?? -1) + 1
                                    } else {
                                        orderOfNewExercise = 0
                                        for exercise in routine.exercises {
                                            exercise.order += 1
                                        }
                                    }

                                    let setup = appSettings.exerciseSetup[name]

                                    let newExercise = Exercise(
                                        name: name,
                                        reps: setup?.reps ?? [8],
                                        seconds: setup?.seconds ?? [0],
                                        completedSets: [],
                                        weights: setup?.weights ?? [0],
                                        restTime: (appSettings.lastRestTime ? setup?.restTime ?? appSettings.defaultRestSeconds : appSettings.defaultRestSeconds),
                                        repsColumn: setup?.repsColumn ?? true,
                                        weightColumn: setup?.weightColumn ?? true,
                                        secsColumn: setup?.secsColumn ?? false,
                                        order: orderOfNewExercise
                                    )

                                    routine.exercises.append(newExercise)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                    } header: {
                        HStack {
                            Text("Previous Exercises")
                                .font(.headline)

                            Spacer()

                            Button {
                                showUsedExercises.toggle()
                            } label: {
                                Text(showUsedExercises ? "Hide" : "Show")
                            }
                        }
                    }
                }

                Section {
                    ForEach(filtered) { exercise in
                        Button {
                            var orderOfNewExercise = 0

                            if appSettings.addExerciseOn == "bottom" {
                                // one past the highest existing order, not the count, so deleted
                                // exercises don't leave the new one colliding with a used order
                                orderOfNewExercise = (routine.exercises.map(\.order).max() ?? -1) + 1
                            } else {
                                orderOfNewExercise = 0
                                for exercise in routine.exercises {
                                    exercise.order += 1
                                }
                            }

                            let setup = appSettings.exerciseSetup[exercise.name]

                            let newExercise = Exercise(
                                name: exercise.name,
                                reps: setup?.reps ?? [8],
                                seconds: setup?.seconds ?? [0],
                                completedSets: [],
                                weights: setup?.weights ?? [0],
                                restTime: (appSettings.lastRestTime ? setup?.restTime ?? appSettings.defaultRestSeconds : appSettings.defaultRestSeconds),
                                repsColumn: setup?.repsColumn ?? true,
                                weightColumn: setup?.weightColumn ?? true,
                                secsColumn: setup?.secsColumn ?? false,
                                order: orderOfNewExercise
                            )

                            routine.exercises.append(newExercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.headline)

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
                } header: {
                    Text("All Exercises")
                        .font(.headline)
                }
            }
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
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isSearchFocused = true
        }
    }
}

#Preview {
    ExerciseSearchView(routine: Routine(name: "Routine 1"))
        .environment(AppSettings())
}
