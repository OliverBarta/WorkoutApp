//
//  WorkoutSession.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-19.
//

import SwiftUI
import Observation

@Observable
class WorkoutSession {
    // if you change the routine during the workout your changing this variable
    var workoutRoutine: Routine?
    // the unedited routine. 
    var originalRoutine: Routine?
    
    var showActiveWorkout: Bool = false
    // tracks when the workout actually started so that the timer can run even when the workout isnt on screen
    var workoutStartDate: Date?
    
    // tracks the last time a rest happened
    var restTimerStartDate: Date?
    
    // the exercise that restimerstartdate is for
    var exerciseBeingTimed: Exercise?
    
    func startRestTimer(_ exercise: Exercise) {
        restTimerStartDate = Date()
        exerciseBeingTimed = exercise
    }
    
    func stopRestTimer() {
        restTimerStartDate = nil
    }

    var isActive: Bool {
        workoutRoutine != nil
    }

    func start(_ routine: Routine) {
        workoutRoutine = routine.copy()
        // any edit on original routine edits routine.
        originalRoutine = routine
        workoutStartDate = Date()
        showActiveWorkout = true
    }

    func end() {
        workoutRoutine = nil
        originalRoutine = nil
        workoutStartDate = nil
        showActiveWorkout = false
    }
    
    // removes the exercise you gave from the workout routine
    func removeExercise(_ exercise: Exercise) {
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
}
