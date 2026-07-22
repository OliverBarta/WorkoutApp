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
    
    private var sortedExercises: [Exercise] {
        workoutSession.workoutRoutine?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    @State private var showDoneDialog = false
    @Environment(\.dismiss) private var dismiss
    
    var percentSetsDone: CGFloat = 0.1

    var body: some View {
        VStack(spacing: 0) {
            
            VStack {
                HStack {
                    Button("Hide") {
                        workoutSession.showActiveWorkout = false
                    }
                    .buttonStyle(.glass)
                    .frame(alignment: .leading)
                    .padding()
                    .padding(.bottom)
                    
                    Text(routine.name)
                        .headerStyle()
                        .padding(.bottom)
                    
                    Button("Done") {
                        showDoneDialog = true
                    }
                    .buttonStyle(.glass)
                    .frame(alignment: .trailing)
                    .padding()
                    .padding(.bottom)
                }
            }
            .padding(.top, -15)
            
            GeometryReader { geometry in
                ZStack (alignment: .leading) {
                    Rectangle()
                        .fill(Theme.progressBarBackground)
                    
                    Rectangle()
                        .fill(Theme.progressBar)
                        .frame(width: geometry.size.width * workoutSession.getCompletedSetsPercentage())
                        .animation(.smooth(duration: 0.25), value: workoutSession.getCompletedSetsPercentage())
                    
                    WorkoutTimer()
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    WorkoutTimer()
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                        .mask (
                            Rectangle()
                                .frame(width: geometry.size.width * workoutSession.getCompletedSetsPercentage())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }
            }
            .padding(.top, -15)
            .frame(height: 30)
            
            ScrollView {

                Button("Add Exercise") {
                    guard let workoutRoutine = workoutSession.workoutRoutine else { return }
                    let newExercise = Exercise(
                        name: "New Exercise",
                        reps: [8],
                        completedSets: [],
                        weights: [0],
                        restTime: 60,
                        type: "lb",
                        order: workoutRoutine.exercises.count
                    )
                    workoutRoutine.exercises.append(newExercise)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.top, 12)
                
                ForEach(sortedExercises) { exercise in
                    ExerciseDuringWorkoutCard(exercise: exercise)
                }
                .padding(.top, 5)
            }
            .frame(maxHeight: .infinity)
            
        }
        .confirmationDialog("Update original routine?", isPresented: $showDoneDialog, titleVisibility: .visible) {
            Button ("Update routine") {
                
                if let workoutRoutine = workoutSession.workoutRoutine {
                    routine.exercises = workoutRoutine.exercises.map { $0.copyCompletedSetsToZero() }
                }
                workoutSession.end()
                dismiss()
            }
            
            Button ("Keep original routine") {
                
                // add save to history functionality
                
                if let originalRoutine = workoutSession.originalRoutine {
                    routine.exercises = originalRoutine.exercises.map { $0.copyCompletedSetsToZero() }
                }
                
                workoutSession.end()
                dismiss()
            }
            Button ("End workout without saving") {
                if let originalRoutine = workoutSession.originalRoutine {
                    routine.exercises = originalRoutine.exercises.map { $0.copyCompletedSetsToZero() }
                }
                
                workoutSession.end()
                dismiss()
            }
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
