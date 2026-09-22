//
//  WorkoutSession.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-19.
//

import SwiftUI
import Observation
import SwiftData

// the class for a active workout.

struct PersonalBest: Equatable {
    let exerciseName: String
    // in pounds, since every weight is stored in pounds
    let weight: Double
}

@Observable
class WorkoutSession {
    // if you change the routine during the workout your changing this variable
    var workoutRoutine: Routine?
    
    // the unedited routine
    var originalRoutineExercises: [Exercise] = []
    
    // if we are showing the RoutineDuringWorkoutView or not
    var showActiveWorkout: Bool = false
    
    // tracks when the workout actually started so that the timer can run even when the workout isnt on screen
    var workoutStartDate: Date?
    
    // tracks the last time a rest happened
    var restTimerStartDate: Date?
    
    // the exercise that restimerstartdate is for
    var exerciseBeingTimed: Exercise?

    // set when a completed set beats the record, cleared when the celebration is dismissed.
    var newPersonalBest: PersonalBest?
    // known ERROR: if someone has 2 instances of the same exercise it will celebrate their PB twice.

    func startRestTimer(_ exercise: Exercise) {
        restTimerStartDate = Date()
        exerciseBeingTimed = exercise
    }
    
    func stopRestTimer() {
        restTimerStartDate = nil
        exerciseBeingTimed = nil
    }

    var isActive: Bool {
        workoutRoutine != nil
    }

    func start(_ routine: Routine,_ context: ModelContext,_ givenStart: Date,_ workoutHasPreviousStartDate: Bool, givenOriginalExercises: [Exercise], useGivenOriginalExercises: Bool) {
        var startDate = Date()
        if workoutHasPreviousStartDate {
            startDate = givenStart
        }
        
        workoutRoutine = routine
        
        if useGivenOriginalExercises {
            originalRoutineExercises = givenOriginalExercises.map { $0.copy() }// these are only given in the case of a start from a crash (WorkOutSaveLong)
        } else {
            originalRoutineExercises = routine.exercises.map { $0.copy() }
        }
        
        workoutStartDate = startDate
        showActiveWorkout = true
        
        // Clear workoutlongsave
        for stale in (try? context.fetch(FetchDescriptor<WorkOutLongSave>())) ?? [] {
            context.delete(stale)
        }

        context.insert(WorkOutLongSave(startDate: startDate, routine: routine, originalExercises: originalRoutineExercises))
        try? context.save() // autosave may not have run when a crash hits
    }
    
    func end(_ context: ModelContext) {
        // Clear workoutlongsave
        for stale in (try? context.fetch(FetchDescriptor<WorkOutLongSave>())) ?? [] {
            context.delete(stale)
        }
        
        workoutRoutine = nil
        originalRoutineExercises = []
        workoutStartDate = nil
        showActiveWorkout = false
        newPersonalBest = nil
        stopRestTimer()
        
        try? context.save() // autosave may not have run when a crash hits
    }
    
    // removes the exercise you gave from the workout routine
    func removeExercise(_ exercise: Exercise) {
        if exerciseBeingTimed === exercise {
            stopRestTimer()
        }

        workoutRoutine?.exercises.removeAll { $0 === exercise }
    }
    
    func getCompletedSetsPercentage() -> CGFloat {
        guard let exercises = workoutRoutine?.exercises, !exercises.isEmpty else {
            return 0.0
        }
        
        let totalSets = exercises.reduce(0) { $0 + $1.reps.count }
        guard totalSets > 0 else { return 0.0 }
        
        let completedSets = exercises.reduce(0) { $0 + $1.completedSets.count }
        
        return CGFloat(completedSets) / CGFloat(totalSets)
    }
    
    func getCompletedRestTimePercentage() -> CGFloat {
        guard let restStart = restTimerStartDate,
              let totalRestTime = exerciseBeingTimed?.restTime,
              totalRestTime > 0
        else {
            return 0.0
        }
        
        let timePassed = Date().timeIntervalSince(restStart)
        let percentage = CGFloat(timePassed) / CGFloat(totalRestTime)
        
        return min(max(percentage, 0.0), 1.0)
    }
}
