//
//  WorkoutSession.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-19.
//

import SwiftUI
import Observation

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
    var originalRoutine: Routine?
    
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

    func endAndRecordPBs(_ appSettings: AppSettings, userId: UUID) async throws {
        guard let exercises = workoutRoutine?.exercises else {
            print("No workoutRoutine and/or exercises")
            endWithoutRecordingPbs()
            return
        }
        
        // record Pbs
        for exercise in exercises {
            var PB = (appSettings.personalBests[exercise.name] ?? 0)
            var betterPBFound = false
            for setIndex in exercise.completedSets {
                if PB < exercise.weights[setIndex] {
                    PB = exercise.weights[setIndex]
                    betterPBFound = true
                }
            }
            
            if betterPBFound {
                appSettings.personalBests[exercise.name] = PB // local save
                
                try await uploadPBToSupabase(userId: userId, exerciseName: exercise.name, weight: PB) // database save
            }
        }
        
        endWithoutRecordingPbs()
    }
    
    func endWithoutRecordingPbs() {
        workoutRoutine = nil
        originalRoutine = nil
        workoutStartDate = nil
        showActiveWorkout = false
        newPersonalBest = nil
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
