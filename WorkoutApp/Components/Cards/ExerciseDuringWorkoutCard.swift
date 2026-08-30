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
    let rowHeightValue: CGFloat = 61
    
    @State private var timerFullscreen: Bool = false
    @State private var editRestTimeView: Bool = false
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0
    
    // the set the timer is currently effecting so if you log a time it will change the seconds there.
    @State private var setIndexTimerAttatchedTo: Int = 0
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            TopPopUp(message: $errorMessage)
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if exercise.secsColumn {
                    Button {
                        if exercise.reps.count == 0 {// if no sets
                            errorMessage = "No sets to time"
                        } else {
                            timerFullscreen = true
                        }
                    } label : {
                        Image(systemName: "clock")
                    }
                }
                
                Menu {
                    Toggle("Reps column", isOn: $exercise.repsColumn)
                    Toggle("Weight column", isOn: $exercise.weightColumn)
                    Toggle("Time column", isOn: $exercise.secsColumn)
                    Button {
                        editRestTimeView = true
                    } label: {
                        Text("Edit rest time")
                        Image(systemName: "clock")
                    }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(exercise)
                        workoutSession.removeExercise(exercise)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
            }
            
            
            List(Array(exercise.reps.indices), id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if exercise.repsColumn {
                        Spacer()
                        EditableStat(value: $exercise.reps[index])
                        Text("reps")
                            .foregroundColor(.secondary)
                    }
                    if exercise.weightColumn {
                        Spacer()
                        EditableStatDouble(value: $exercise.weights[index])
                        Text("lb")
                            .foregroundColor(.secondary)
                    }
                    if exercise.secsColumn {
                        Spacer()
                        EditableTime(value: $exercise.seconds[index])
                            .padding(.horizontal)
                            .foregroundStyle(setIndexTimerAttatchedTo == index ? Theme.primary: Theme.oppositeBackground)
                    }

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
                        
                        reCalculateSetIndexTimerAttachtedTo()
                        
                    } label: {
                        Image(systemName: "checkmark.square.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .symbolRenderingMode(.hierarchical)
                            .frame(maxWidth: 20)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(exercise.completedSets.contains(index) ? Theme.checkedSetGreen : Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        exercise.removeSet(at: index)
                        
                        reCalculateSetIndexTimerAttachtedTo()
                    }
                    .labelStyle(.titleOnly)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listRowSpacing(0)
            .padding(.horizontal, -16)
            .padding(.top, 8)
            .frame(height: rowHeightValue * CGFloat(exercise.reps.count))
            
            Button {
                exercise.addSet()
                
                reCalculateSetIndexTimerAttachtedTo()
            } label : {
                Text("Add set")
                Image(systemName: "plus")
            }
            .padding(.top, 10)
        }
        .fullScreenCover(isPresented: $timerFullscreen) {
            TimerFullscreen(secondsRecorded: $exercise.seconds[setIndexTimerAttatchedTo], attachedSet: setIndexTimerAttatchedTo+1)
        }
        .onChange(of: editRestTimeView) { _, isPresented in// sets the picker wheel variables to the current rest time
            if isPresented {
                pickerMinutes = exercise.restTime / 60
                pickerSeconds = exercise.restTime % 60
            }
        }
        .sheet(isPresented: $editRestTimeView) {// edit rest timer sheet
            VStack {
                Text("Edit rest time from \(SecondsFormatted(exercise.restTime))")
                    .padding()
                    .font(.headline)
                
                HStack(spacing: 0) {
                    wheel(range: 0..<60, selection: $pickerMinutes, unit: "min")
                    wheel(range: 0..<60, selection: $pickerSeconds, unit: "sec")
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    exercise.restTime = pickerMinutes*60 + pickerSeconds
                    editRestTimeView = false
                } label : {
                    Text("Set rest time")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal)
                
                Button {
                    editRestTimeView = false
                } label : {
                    Text("Cancel")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                .padding(.horizontal)
            }
            .presentationDetents([.height(380)])
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func reCalculateSetIndexTimerAttachtedTo() {
        if exercise.completedSets.count == exercise.reps.count {// if all sets are done
            setIndexTimerAttatchedTo = exercise.completedSets.count-1
        } else {
            for setIndex in exercise.reps.indices {
                if !exercise.completedSets.contains(setIndex) {
                    setIndexTimerAttatchedTo = setIndex
                    break
                }
            }
        }
    }
}


#Preview {
    let exercise = Exercise(name: "Bench Press", reps: [3,3,3], seconds: [0,0,0], completedSets: [], weights: [10, 10, 10], restTime: 60, repsColumn: true, weightColumn: true, secsColumn: true, order: 0)
    let routine = Routine(name: "Routine 1", exercises: [exercise])
    let session = WorkoutSession()
    let _ = session.start(routine)

    ExerciseDuringWorkoutCard(exercise: exercise)
        .environment(session)
        .modelContainer(for: [Routine.self, Exercise.self], inMemory: true)
}
