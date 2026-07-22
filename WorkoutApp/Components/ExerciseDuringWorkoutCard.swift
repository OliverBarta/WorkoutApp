//
//  ExcerciseEditCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

// the exercise card for edit view
struct ExerciseDuringWorkoutCard: View {
    @Bindable var exercise: Exercise
    @Environment(WorkoutSession.self) private var workoutSession
    @Environment(\.modelContext) private var modelContext
    let rowHeightValue: CGFloat = 62
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Menu {
                    Button("Change units") {
                        if exercise.type == "lb" {
                            exercise.type = "kg"
                        } else if exercise.type == "kg" {
                            exercise.type = "sec"
                        } else {
                            exercise.type = "lb"
                        }
                    }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(exercise)
                        workoutSession.removeExercise(exercise)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .frame(alignment: .trailing)
            }
            
            
            List(Array(exercise.reps.indices), id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    EditableStat(value: $exercise.reps[index])
                    Text("reps")
                        .foregroundColor(.secondary)
                    Spacer()
                    EditableStat(value: $exercise.weights[index])
                    Text(exercise.type)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        if exercise.completedSets.contains(index) {
                            if workoutSession.exerciseBeingTimed == exercise {
                                workoutSession.stopRestTimer()
                            }
                            exercise.completedSets.remove(index)
                        } else {
                            workoutSession.startRestTimer(exercise)
                            exercise.completedSets.insert(index)
                        }
                        
                    } label: {
                        Image(systemName: "checkmark.square.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .symbolRenderingMode(.hierarchical)
                            .frame(maxWidth: 20)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(exercise.completedSets.contains(index) ? Theme.progressBarBackground : Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        exercise.reps.remove(at: index)
                        exercise.weights.remove(at: index)
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listRowSpacing(0)
            .padding(.horizontal, -16)
            .padding(.top, 8)
            .frame(height: rowHeightValue * CGFloat(exercise.reps.count))
            
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                GeometryReader { geometry in
                    ZStack {
                        ZStack (alignment: .leading) {
                            Rectangle()
                                .fill(Theme.progressBarBackground)
                                .frame(width: geometry.size.width ,height: 18)
                            if let restStart = workoutSession.restTimerStartDate,
                               Date().timeIntervalSince(restStart) < Double(exercise.restTime) && workoutSession.exerciseBeingTimed == exercise {
                                let elapsed = Date().timeIntervalSince(restStart)
                                let remainingFraction = max(0, 1 - (elapsed / Double(exercise.restTime)))
                                
                                Rectangle()
                                    .fill(Theme.progressBar)
                                    .frame(width: geometry.size.width * remainingFraction, height: 18)
                                    .animation(.smooth(duration: 0.25), value: remainingFraction)
                            }
                        }
                        .overlay {
                            if let restStart = workoutSession.restTimerStartDate,
                               Date().timeIntervalSince(restStart) < Double(exercise.restTime) && workoutSession.exerciseBeingTimed == exercise {
                                GeneralCountDownTimer(countDownFrom: exercise.restTime)
                                    .font(.system(size: 18))
                                    .id(restStart)// makes the timer reset every new check
                                
                            } else {
                                FrozenTimeDisplay(displayTimeSeconds: exercise.restTime)
                                    .font(.system(size: 18))
                            }
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 20)
            }
            .padding(.top, 18)
            .padding(.horizontal, -16)
            
            Button("Add set") {
                if let lastSetReps = exercise.reps.last, let lastWeight = exercise.weights.last {
                    exercise.reps.append(lastSetReps)
                    exercise.weights.append(lastWeight)
                } else {
                    exercise.reps.append(0)
                    exercise.weights.append(0)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 25)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


#Preview {
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
    
    
    return ExerciseDuringWorkoutCard(
        exercise: Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb", order: 0)
    )
    .environment(session)
}
