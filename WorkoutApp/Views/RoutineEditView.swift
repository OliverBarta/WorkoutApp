//
//  RoutineEditView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineEditView: View {
    @Bindable var routine: Routine
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(AuthManager.self) private var authManager
    
    @State private var keyboardObserver = KeyboardObserver()
    
    @State private var showExerciseSearch = false

    @State private var showReorder = false

    @State private var showingAddExerciseAlert = false
    @State private var newExerciseName = ""

    @State private var errorMessage: String = ""
    
    @FocusState private var isRoutineNameEditorFocused: Bool

    private var sortedExercises: [Exercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)
                
                CustomSearchBar(text: $routine.name, isFocused: $isRoutineNameEditorFocused, placeHolderText: "Routine name")
                    .padding()
                
                
                if appSettings.addExerciseButtonsTop {
                    HStack {
                        Button {
                            showExerciseSearch = true
                        } label : {
                            Text("Exercise")
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
                        
                        Button {
                            showingAddExerciseAlert = true
                        } label : {
                            Text("Custom Exercise")
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
                        
                        Button {
                            showReorder = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .disabled(sortedExercises.count < 2)
                        
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if sortedExercises.isEmpty {
                    if appSettings.addExerciseButtonsTop || appSettings.addExerciseButtonsBot {
                        Text("Add exercises by clicking either \"Exercise +\" button.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 60)
                    } else {
                        Text("Enable the exercise buttons in settings.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 60)
                    }
                } else {
                    ForEach(sortedExercises) { exercise in
                        ExerciseEditCard(exercise: exercise)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        
                    }
                    .padding(.top, 10)
                }
                
                if appSettings.addExerciseButtonsBot {
                    HStack {
                        Button {
                            showExerciseSearch = true
                        } label : {
                            Text("Exercise")
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
                        
                        Button {
                            showingAddExerciseAlert = true
                        } label : {
                            Text("Custom Exercise")
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
                        
                        Button {
                            showReorder = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .disabled(sortedExercises.count < 2)
                        
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxHeight: .infinity)
        }
        .onTapGesture {
            isRoutineNameEditorFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .overlay {
            VStack {
                ZStack {
                    Text("Edit \(routine.name)")
                        .headerStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack {
                        Button {
                            
                            Task {
                                do {
                                    try await uploadRoutineToSupabase(routine)
                                } catch {
                                    errorMessage = "Upload failed: \(error)"
                                    print("Upload failed: \(error)")
                                }
                            }
                            
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .padding(5)
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    }
                    .padding(.horizontal)
                    
                }
                TopPopUp(message: $errorMessage)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if keyboardObserver.isVisible {
                HStack {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .fontWeight(.semibold)
                            .padding()
                            .glassEffect()
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            ExerciseSearchView(routine: routine)
                .presentationCornerRadius(12)
        }
        .sheet(isPresented: $showReorder) {
            ReorderExercisesView(routine: routine)
                .presentationCornerRadius(12)
        }
        .alert("Enter a name for your new exercise", isPresented: $showingAddExerciseAlert) {
            TextField("Exercise Name", text: $newExerciseName)

            Button("Add") {
                // Ensure the text isn't empty, otherwise fall back to a default name
                let trimmedName = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? "New Exercise" : trimmedName

                var orderOfNewExercise = 0

                if appSettings.addExerciseOn == "bottom" {
                    orderOfNewExercise = (routine.exercises.map(\.order).max() ?? -1) + 1
                } else {
                    orderOfNewExercise = 0

                    for exercise in routine.exercises {
                        exercise.order += 1
                    }
                }

                // the previous setup this exercise had (if it had one)
                let setup = appSettings.exerciseSetup[finalName]
                
                let newExercise = Exercise(
                    name: finalName,
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

                // Reset the text field for the next time it opens
                newExerciseName = ""
            }

            Button("Cancel", role: .cancel) {
                newExerciseName = ""
            }
        }
    }
}

#Preview {
    RoutineEditView(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 0)]))
        .environment(AppSettings())
        .environment(AuthManager())
}
