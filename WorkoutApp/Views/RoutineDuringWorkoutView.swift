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
    
    @State private var keyboardObserver = KeyboardObserver()
    
    private var sortedExercises: [Exercise] {
        workoutSession.workoutRoutine?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    @State private var showDoneDialog = false
    @State private var showingAddExerciseAlert = false
    @State private var newExerciseName = ""
    @State private var showExerciseSearch = false
    @State private var showEndWorkoutVerifactionWindow = false
    
    
    @Environment(\.dismiss) private var dismiss
    
    var percentSetsDone: CGFloat = 0.1

    var body: some View {
        VStack(spacing: 0) {
            
            
            
            ScrollView {
                VStack (spacing: 16) {
                    HStack {
                        Button {
                            showExerciseSearch = true
                        } label : {
                            HStack {
                                Text("Exercise")
                                Image(systemName: "plus")
                            }
                        }
                        .buttonStyle(.liquidGlass(tintColor: Theme.primary))
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button {
                            showingAddExerciseAlert = true
                        } label : {
                            HStack {
                                Text("Custom exercise")
                                Image(systemName: "plus")
                            }
                        }
                        .buttonStyle(.liquidGlass(tintColor: Theme.grey))
                        .padding(.horizontal)
                    }
                    .padding(.top, 125)
                    
                    ForEach(sortedExercises) { exercise in
                        ExerciseDuringWorkoutCard(exercise: exercise)
                    }
                    
                    Button(role: .destructive) {
                        showEndWorkoutVerifactionWindow = true
                    } label : {
                        Text("End workout without logging")
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
                    
                    Task {
                        do {
                            try await uploadRoutineToSupabase(routine)
                        } catch {
                            print("Upload failed: \(error)")
                        }
                    }
                    
                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {
                        
                        let duration = Int(Date().timeIntervalSince(startDate))
                        
                        saveRoutineToHistory(workoutRoutine, duration, modelContext)
                        routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }
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
                    
                    if let workoutRoutine = workoutSession.workoutRoutine,
                       let startDate = workoutSession.workoutStartDate {
                        
                        let duration = Int(Date().timeIntervalSince(startDate))
                        
                        saveRoutineToHistory(workoutRoutine, duration, modelContext)
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
                    completedSets: [],
                    weights: [0],
                    restTime: 60,
                    type: "lb",
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
        
}


#Preview {
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))

    return RoutineDuringWorkoutView(routine: Routine(name: "Routine 1"))
        .environment(session)
}
