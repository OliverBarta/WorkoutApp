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
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    
    let rowHeightValue: CGFloat = 61
    
    @State private var timerFullscreen: Bool = false
    @State private var editRestTimeView: Bool = false
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0
    
    // the set the timer is currently effecting so if you log a time it will change the seconds there.
    @State private var setIndexTimerAttatchedTo: Int = 0
    
    @State private var errorMessage: String = ""
    
    @State private var personalBest: Double = 0
    @State private var personalBestIndex: Int = -1// the index of a completed set that has the personal best weight (-1 if no sets have that)
    
    @State private var showExerciseClickedView: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            TopPopUp(message: $errorMessage)
            HStack {
                Button {
                    showExerciseClickedView = true
                } label: {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                
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
                        EditableStatDouble(value: appSettings.weightBinding($exercise.weights[index]))
                        Text(appSettings.weightUnit.label)
                            .foregroundColor(.secondary)
                    }
                    if exercise.secsColumn {
                        Spacer()
                        EditableTime(value: $exercise.seconds[index])
                            .padding(.horizontal)
                            .foregroundStyle(setIndexTimerAttatchedTo == index ? Theme.primary: Theme.oppositeBackground)
                    }

                    Spacer()
                    
                    // complete set button
                    Button {
                        if exercise.completedSets.contains(index) {
                            if workoutSession.exerciseBeingTimed == exercise {
                                workoutSession.stopRestTimer()
                            }
                            
                            exercise.completedSets.remove(index)

                            calculatePersonalBest()

                        } else {
                            workoutSession.startRestTimer(exercise)
                            exercise.completedSets.insert(index)

                            // start personal best animation and set local PB variables
                            if exercise.weights[index] > personalBest {
                                personalBest = exercise.weights[index]
                                personalBestIndex = index

                                workoutSession.newPersonalBest = PersonalBest(exerciseName: exercise.name, weight: personalBest)
                            }
                        }

                        reCalculateSetIndexTimerAttachtedTo()

                    } label: {
                        Image(systemName: "checkmark.square.fill")
                            .font(.title2)
                            .foregroundStyle((exercise.weights[index] > personalBest && !exercise.completedSets.contains(index)) || personalBestIndex == index ? Theme.gold : Color.green)// gold if this set would beat the personal best, green otherwise
                            .symbolRenderingMode(.hierarchical)
                            .frame(maxWidth: 20)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(exercise.completedSets.contains(index) ? (personalBestIndex == index ? Theme.checkedSetGold : Theme.checkedSetGreen) : Color.clear)// gold if this is the personal best and completed, green if completed and not PB, clear otherwise
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        exercise.removeSet(at: index)

                        calculatePersonalBest()

                        reCalculateSetIndexTimerAttachtedTo()
                    }
                    .labelStyle(.titleOnly)
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)// hides the side scroll bar
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
        .task {
            calculatePersonalBest()
        }
        // a weight the user types can knock the record down or push another completed set past it
        .onChange(of: exercise.weights) {
            calculatePersonalBest()
        }
        .fullScreenCover(isPresented: $timerFullscreen) {
            TimerFullscreen(secondsRecorded: $exercise.seconds[setIndexTimerAttatchedTo], attachedSet: setIndexTimerAttatchedTo+1)
        }
        .fullScreenCover(isPresented: $showExerciseClickedView) {
            ExerciseClickedView(exerciseName: exercise.name)
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
    
    // calculates personalBest (the weight) and personalBestIndex (the set that personalBest was acheived)
    private func calculatePersonalBest() {
        personalBest = (appSettings.personalBests[exercise.name] ?? 0)
        personalBestIndex = -1

        for setIndex in exercise.completedSets {
            if personalBest < exercise.weights[setIndex] {
                personalBest = exercise.weights[setIndex]
                personalBestIndex = setIndex
            }
        }
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
    let exercise = Exercise(name: "Barbell bench press", reps: [3,3,3], seconds: [0,0,0], completedSets: [], weights: [10, 20, 30], restTime: 60, repsColumn: true, weightColumn: true, secsColumn: true, order: 0)
    let routine = Routine(name: "Routine 1", exercises: [exercise])
    let session = WorkoutSession()
    let _ = session.start(routine)

    ExerciseDuringWorkoutCard(exercise: exercise)
        .environment(session)
        .environment(AppSettings())
        .environment(AuthManager())
        .modelContainer(for: [Routine.self, Exercise.self], inMemory: true)
}
