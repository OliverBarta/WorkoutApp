//
//  WorkoutHistory.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-25.
//

import SwiftData
import Foundation

@Model
class WorkoutHistoryEntry {
    var routineName: String
    var dateCompleted: Date
    var durationSeconds: Int
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSnapshot.historyEntry)
    var exerciseSnapshots: [ExerciseSnapshot]

    init(routineName: String, dateCompleted: Date = Date(), durationSeconds: Int, exerciseSnapshots: [ExerciseSnapshot]) {
        self.routineName = routineName
        self.dateCompleted = dateCompleted
        self.durationSeconds = durationSeconds
        self.exerciseSnapshots = exerciseSnapshots
    }
}

@Model
class ExerciseSnapshot {
    var name: String
    var reps: [Int]
    var weights: [Int]
    var type: String

    var historyEntry: WorkoutHistoryEntry?

    init(name: String, reps: [Int], weights: [Int], type: String) {
        self.name = name
        self.reps = reps
        self.weights = weights
        self.type = type
    }
}

func saveRoutineToHistory(_ workoutRoutine: Routine,_ durationSeconds: Int,_ modelContext: ModelContext) {
    let snapshots = workoutRoutine.exercises.compactMap { exercise -> ExerciseSnapshot? in
        
        var weights: [Int] = []
        var reps: [Int] = []
        
        for completedSetIndex in exercise.completedSets {
            if completedSetIndex < exercise.weights.count && completedSetIndex < exercise.reps.count {
                weights.append(exercise.weights[completedSetIndex])
                reps.append(exercise.reps[completedSetIndex])
            }
        }
        
        if reps.count > 0 {
            return ExerciseSnapshot(
                name: exercise.name,
                reps: reps,
                weights: weights,
                type: exercise.type
            )
        } else {
            return nil
        }
    }

    let entry = WorkoutHistoryEntry(
        routineName: workoutRoutine.name,
        dateCompleted: Date(),
        durationSeconds: durationSeconds,
        exerciseSnapshots: snapshots
    )

    modelContext.insert(entry)
}

// converts a workoutHistoryEntry into type Routine
func workoutHistoryToRoutine(_ workoutHistoryEntry: WorkoutHistoryEntry) -> Routine {
    let finalRoutine = Routine(name: workoutHistoryEntry.routineName)
    
    var orderTracked = -1
    
    finalRoutine.exercises = workoutHistoryEntry.exerciseSnapshots.compactMap { exerciseSnapshot in
        orderTracked += 1
        
        let exercise = Exercise(
            name: exerciseSnapshot.name,
            reps: exerciseSnapshot.reps,
            completedSets: [],
            weights: exerciseSnapshot.weights,
            restTime: 60,
            type: exerciseSnapshot.type,
            order: orderTracked
        )
        
        exercise.routine = finalRoutine
        
        return exercise
        
    }
    
    return finalRoutine
    
}
