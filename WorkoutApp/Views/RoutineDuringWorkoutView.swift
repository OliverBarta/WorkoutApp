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
    
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WorkoutHistoryEntry.dateCompleted, order: .reverse) private var history: [WorkoutHistoryEntry]
    
    @State private var keyboardObserver = KeyboardObserver()
    
    private var sortedExercises: [Exercise] {
        workoutSession.workoutRoutine?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    @State private var showDoneDialog = false
    @State private var showingAddExerciseAlert = false
    @State private var newExerciseName = ""
    @State private var showExerciseSearch = false
    @State private var showReorder = false
    @State private var showEndWorkoutVerifactionWindow = false
    @State private var showClearExercisesVerifactionWindow = false
    @State private var errorMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var percentSetsDone: CGFloat = 0.1
    
    @State private var showChangeAllRestTimes = false
    
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack (spacing: 12) {
                    
                    Rectangle()
                        .padding(.top, 100)
                        .opacity(0)
                    
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
                            Text("Enable the add exercise buttons in settings.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 60)
                        }
                    } else {
                        ForEach(sortedExercises) { exercise in
                            ExerciseDuringWorkoutCard(exercise: exercise)
                        }
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
                    
                    Button {
                        showChangeAllRestTimes = true
                    } label : {
                        Text("Change all rest times for this routine")
                        Image(systemName: "clock")
                    }
                    
                    Button(role: .destructive) {
                        showClearExercisesVerifactionWindow = true
                    } label : {
                        Text("Clear all exercises")
                        Image(systemName: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showEndWorkoutVerifactionWindow = true
                    } label : {
                        Text("End workout without logging or updating")
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
        .sheet(isPresented: $showReorder) {
            if let workoutRoutine = workoutSession.workoutRoutine {
                ReorderExercisesView(routine: workoutRoutine)
                    .presentationCornerRadius(12)
            }
        }
        .sheet(isPresented: $showDoneDialog) {
            VStack(spacing: 16) {
                Text("Log and update \"\(routine.name)\"?")
                    .font(.headline)
                    .padding()
                
                Button {
                    // saves routine to history and updates the routine

                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {

                        let duration = Int(Date().timeIntervalSince(startDate))
                        let historySnapshot = history

                        saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)

                        // updates routine
                        routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }

                        Task {
                            do {
                                try await uploadRoutineToSupabase(routine)
                                try await uploadRoutineToHistorySupabase(workoutRoutine, routineId: routine.id, duration: duration, appSettings: appSettings)
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
                    
                    // ends workout
                    workoutSession.end()
                    dismiss()
                } label : {
                    Text("Log and update")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.green)
                
                Button {
                    // saves routine to history

                    // saves to local storage, uploads to supabase, then updates the streak.
                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {

                        let duration = Int(Date().timeIntervalSince(startDate))
                        let historySnapshot = history
                        
                        saveRoutineToHistory(workoutRoutine, duration, modelContext, appSettings.personalBests)

                        Task {
                            do {
                                try await uploadRoutineToHistorySupabase(workoutRoutine, routineId: routine.id, duration: duration, appSettings: appSettings)
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
                    
                    // ends workout
                    workoutSession.end()
                    dismiss()
                } label : {
                    Text("Log")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.yellow)
                
                Button {
                    
                    workoutSession.end()
                    dismiss()
                } label : {
                    Text("Don't log or update")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                
                Button {
                    showDoneDialog = false
                } label : {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glass)
                
            }
            .padding()
            .presentationDetents([.height(390)])
        }
        .alert("Enter a name for your new exercise", isPresented: $showingAddExerciseAlert) {
            TextField("Exercise Name", text: $newExerciseName)
            
            Button("Add") {
                // Ensure the text isn't empty, otherwise fall back to a default name
                let trimmedName = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? "New Exercise" : trimmedName
                
                guard let workoutRoutine = workoutSession.workoutRoutine else { return }
                
                var orderOfNewExercise = 0
                
                if appSettings.addExerciseOn == "bottom" {
                    orderOfNewExercise = (workoutRoutine.exercises.map(\.order).max() ?? -1) + 1
                } else {
                    orderOfNewExercise = 0
                    
                    for exercise in workoutRoutine.exercises {
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
                
                workoutRoutine.exercises.append(newExercise)
                
                // Reset the text field for the next time it opens
                newExerciseName = ""
            }
            
            Button("Cancel", role: .cancel) {
                newExerciseName = ""
            }
        }
        .sheet(isPresented: $showChangeAllRestTimes) {
            VStack {
                HStack {
                    wheel(range: 0..<60, selection: $pickerMinutes, unit: "min")
                    wheel(range: 0..<60, selection: $pickerSeconds, unit: "sec")
                }
                
                Button {
                    ChangeAllRestTimes()
                    showChangeAllRestTimes = false
                } label: {
                    Text("Change all rest times")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                
                Button {
                    showChangeAllRestTimes = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glass)
            }
            .padding()
            .presentationDetents([.height(320)])
        }
        .sheet(isPresented: $showEndWorkoutVerifactionWindow) {
            VStack(spacing: 16) {
                Text("End workout without logging or updating?")
                    .padding()
                    .font(.headline)
                
                Button {
                    workoutSession.end()
                    dismiss()
                } label: {
                    Text("End")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                
                Button {
                    showEndWorkoutVerifactionWindow = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glass)
                
            }
            .padding()
            .presentationDetents([.height(230)])
            
        }
        .sheet(isPresented: $showClearExercisesVerifactionWindow) {
            VStack(spacing: 16) {
                Text("Clear all exercises?")
                    .padding()
                    .font(.headline)
                
                Button {
                    guard let workoutRoutine = workoutSession.workoutRoutine else { return }
                    
                    workoutRoutine.exercises = []
                    
                    showClearExercisesVerifactionWindow = false
                    
                } label: {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                
                Button {
                    showClearExercisesVerifactionWindow = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glass)
            }
            .padding()
            .presentationDetents([.height(230)])
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        // the personal best celebration
        .overlay {
            ZStack {
                if let personalBest = workoutSession.newPersonalBest {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            workoutSession.newPersonalBest = nil
                        }

                    CelebrationAlert(exerciseName: personalBest.exerciseName, weight: personalBest.weight) {
                        workoutSession.newPersonalBest = nil
                    }
                    .transition(.scale(scale: 1.15).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: workoutSession.newPersonalBest)
        }
    }

    private func ChangeAllRestTimes() {
        guard let exercises = workoutSession.workoutRoutine?.exercises else {
            errorMessage = "Couldn't Change rest times"
            return
        }
        
        let newRestTime = 60*pickerMinutes + pickerSeconds
        
        for exercise in exercises {
            exercise.restTime = newRestTime
        }
        
        errorMessage = "All rest times set to \(SecondsFormatted(newRestTime))"
    }
}


#Preview {
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 0),Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 1)]))

    return RoutineDuringWorkoutView(routine: Routine(name: "Routine 1"))
        .environment(session)
        .environment(AuthManager())
        .environment(AppSettings())
        .modelContainer(for: WorkoutHistoryEntry.self, inMemory: true)
}
