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
    
    @Environment(WorkoutSession.self) private var workoutSession

    @Environment(\.modelContext) private var modelContext

    @Environment(AuthManager.self) private var authManager

    @Query(sort: \WorkoutHistoryEntry.dateCompleted, order: .reverse) private var history: [WorkoutHistoryEntry]
    
    @State private var keyboardObserver = KeyboardObserver()
    
    private var sortedExercises: [Exercise] {
        workoutSession.workoutRoutine?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    @State private var showDoneDialog = false
    @State private var showingAddExerciseAlert = false
    @State private var newExerciseName = ""
    @State private var showExerciseSearch = false
    @State private var showEndWorkoutVerifactionWindow = false
    @State private var showClearExercisesVerifactionWindow = false
    @State private var errorMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var percentSetsDone: CGFloat = 0.1

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack (spacing: 12) {
                    
                    Rectangle()
                        .padding(.top, 100)
                        .opacity(0)
                    
                    HStack(spacing: 2) {
                        Button {
                            showExerciseSearch = true
                        } label : {
                            HStack {
                                Text("Exercise")
                                Image(systemName: "plus")
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .padding(.horizontal)
                        
                        Button {
                            showingAddExerciseAlert = true
                        } label : {
                            HStack {
                                Text("Custom exercise")
                                Image(systemName: "plus")
                            }
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(sortedExercises) { exercise in
                        ExerciseDuringWorkoutCard(exercise: exercise)
                    }
                    
                    Button(role: .destructive) {
                        showEndWorkoutVerifactionWindow = true
                    } label : {
                        Text("End workout without logging")
                        Image(systemName: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showClearExercisesVerifactionWindow = true
                    } label : {
                        Text("Clear all exercises")
                        Image(systemName: "trash")
                    }
                }
                .padding(.bottom, 100)
                
            }
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxHeight: .infinity)
            .overlay {
                // this overlay houses the back button finish button title (Routine 1) and both progress bars
                VStack {
                    VStack {
                        ZStack {
                            HStack {
                                Button {
                                    workoutSession.showActiveWorkout = false
                                } label: {
                                    Image(systemName: "chevron.backward")
                                        .padding(5)
                                }
                                .buttonStyle(.glass)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button {
                                    showDoneDialog = true
                                } label: {
                                    Text("Finish")
                                        .padding(5)
                                }
                                .buttonStyle(.glass)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                
                            }
                            .padding(.horizontal)
                            
                            Text(routine.name)
                                .headerStyle()
                        }
                    }
                    .padding(.bottom, 25)
                    
                    GeometryReader { geometry in
                        Button {
                            
                        } label: {
                            ZStack (alignment: .leading) {
                                
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 30,
                                    bottomLeadingRadius: 30,
                                    bottomTrailingRadius: 30,
                                    topTrailingRadius: 30
                                )
                                    .fill(Theme.progressBar)
                                    .frame(width: geometry.size.width - 32)
                                    .mask (
                                        Rectangle()
                                            .frame(width: geometry.size.width * workoutSession.getCompletedSetsPercentage())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .animation(.smooth(duration: 0.25), value: workoutSession.getCompletedRestTimePercentage())
                                    )
                            
                                
                                WorkoutTimer()
                                    .foregroundColor(Theme.oppositeBackground)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                                
                                WorkoutTimer()
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                                    .mask (
                                        Rectangle()
                                            .frame(width: geometry.size.width * workoutSession.getCompletedSetsPercentage())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    )
                            }
                        }
                        .glassEffect()
                        .padding(.horizontal)
                    }
                    .overlay {
                        TopPopUp(message: $errorMessage)
                    }
                    .padding(.top, -15)
                    .frame(height: 30)
                    Spacer()
                }
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
            } else {
                RestTimer()
                    .id("rest-timer")
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            if let workoutRoutine = workoutSession.workoutRoutine {
                ExerciseSearchView(routine: workoutRoutine)
                    .presentationCornerRadius(12)// makes the sheet 12 radius corners
            }
        }
        .sheet(isPresented: $showDoneDialog) {
            VStack(spacing: 16) {
                Text("Log and update \"\(routine.name)\"?")
                    .font(.headline)
                
                Button {
                    // saves routine to history and updates the routine

                    // the workout has to be read out here, not inside a Task. Tasks only start once
                    // this closure has finished, and workoutSession.end() below has nil'd it by then
                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {

                        let duration = Int(Date().timeIntervalSince(startDate))
                        let historySnapshot = history

                        saveRoutineToHistory(workoutRoutine, duration, modelContext)

                        // updates routine
                        routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }

                        Task {
                            do {
                                try await uploadRoutineToSupabase(routine)
                                try await uploadRoutineToHistorySupabase(workoutRoutine, routineId: routine.id, duration: duration)
                            } catch {
                                print("History upload error: \(error)")
                                errorMessage = "Upload failed: \(error)"
                            }
                        }

                        Task {
                            do {
                                try await authManager.updateStreakAfterWorkout(history: historySnapshot)
                            } catch {
                                print("Streak update failed: \(error)")
                                errorMessage = "Streak update failed: \(error)"
                            }
                        }
                    }

                    
                    workoutSession.end()

                    dismiss()
                } label : {
                    Text("Log and update")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.green)
                .cornerRadius(12)
                
                Button {
                    // saves routine to history

                    // saves to local storage, uploads to supabase, then updates the streak.
                    // the workout has to be read out here, not inside a Task. Tasks only start once
                    // this closure has finished, and workoutSession.end() below has nil'd it by then
                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {

                        let duration = Int(Date().timeIntervalSince(startDate))
                        let historySnapshot = history

                        saveRoutineToHistory(workoutRoutine, duration, modelContext)

                        Task {
                            do {
                                try await uploadRoutineToHistorySupabase(workoutRoutine, routineId: routine.id, duration: duration)
                            } catch {
                                print("Routine upload error: \(error)")
                                errorMessage = "Upload failed: \(error)"
                            }
                        }

                        Task {
                            do {
                                try await authManager.updateStreakAfterWorkout(history: historySnapshot)
                            } catch {
                                print("Streak update failed: \(error)")
                                errorMessage = "Streak update failed: \(error)"
                            }
                        }
                    }

                    workoutSession.end()
                    dismiss()
                } label : {
                    Text("Log")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.yellow)
                .cornerRadius(12)
                
                Button {
                    
                    workoutSession.end()
                    dismiss()
                } label : {
                    Text("Don't log or update")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding()
            .presentationDetents([.height(270)])
        }
        .alert("Enter a name for your new exercise", isPresented: $showingAddExerciseAlert) {
            TextField("Exercise Name", text: $newExerciseName)
            
            Button("Add") {
                // Ensure the text isn't empty, otherwise fall back to a default name
                let trimmedName = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? "New Exercise" : trimmedName
                
                guard let workoutRoutine = workoutSession.workoutRoutine else { return }
                
                let newExercise = Exercise(
                    name: finalName,
                    reps: [8],
                    seconds: [0],
                    completedSets: [],
                    weights: [0],
                    restTime: 60,
                    repsColumn: true,
                    weightColumn: true,
                    secsColumn: false,
                    order: workoutRoutine.exercises.count
                )
                
                workoutRoutine.exercises.append(newExercise)
                
                // Reset the text field for the next time it opens
                newExerciseName = ""
            }
            
            Button("Cancel", role: .cancel) {
                newExerciseName = ""
            }
        }
        .sheet(isPresented: $showEndWorkoutVerifactionWindow) {
            VStack(spacing: 16) {
                Text("End workout without logging?")
                    .font(.headline)
                
                Button {
                    workoutSession.end()
                    dismiss()
                } label: {
                    Text("End")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.red)
                .cornerRadius(12)
                
                Button {
                    showEndWorkoutVerifactionWindow = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Theme.grey)
                .cornerRadius(12)
            }
            .padding()
            .presentationDetents([.height(180)])
            
        }
        .sheet(isPresented: $showClearExercisesVerifactionWindow) {
            VStack(spacing: 16) {
                Text("Clear all exercises?")
                    .font(.headline)
                
                Button {
                    guard let workoutRoutine = workoutSession.workoutRoutine else { return }
                    
                    workoutRoutine.exercises = []
                    
                    showClearExercisesVerifactionWindow = false
                    
                } label: {
                    Text("Clear")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.red)
                .cornerRadius(12)
                
                Button {
                    showClearExercisesVerifactionWindow = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Theme.grey)
                .cornerRadius(12)
            }
            .padding()
            .presentationDetents([.height(180)])
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
        
}


#Preview {
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 0)]))

    return RoutineDuringWorkoutView(routine: Routine(name: "Routine 1"))
        .environment(session)
        .environment(AuthManager())
        .modelContainer(for: WorkoutHistoryEntry.self, inMemory: true)
}
