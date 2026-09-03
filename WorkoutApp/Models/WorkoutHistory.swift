//
//  WorkoutHistory.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-25.
//

import SwiftData
import Foundation

// this is the format it is saved to history in. It is different from the Routine class as it has dates completed and duration

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
    var weights: [Double]
    var seconds: [Int]
    var repsColumn: Bool
    var weightColumn: Bool
    var secsColumn: Bool
    var personalBestIndex: Int
    
    var historyEntry: WorkoutHistoryEntry?

    init(name: String, reps: [Int], weights: [Double], seconds: [Int], repsColumn: Bool, weightColumn: Bool, secsColumn: Bool, personalBestIndex: Int) {
        self.name = name
        self.reps = reps
        self.weights = weights
        self.seconds = seconds
        self.repsColumn = repsColumn
        self.weightColumn = weightColumn
        self.secsColumn = secsColumn
        self.personalBestIndex = personalBestIndex
    }
}

func saveRoutineToHistory(_ workoutRoutine: Routine,_ durationSeconds: Int,_ modelContext: ModelContext,_ personalBests: [String: Double]) {
    let snapshots = workoutRoutine.exercises.compactMap { exercise -> ExerciseSnapshot? in
        
        var weights: [Double] = []
        var seconds: [Int] = []
        var reps: [Int] = []
        
        var PB: Double = (personalBests[exercise.name] ?? 0)
        var PBIndex: Int = -1
        
        // adds all sets that got completed to the workout history to be uploaded.
        for completedSetIndex in exercise.completedSets.sorted() {
            reps.append(exercise.reps[completedSetIndex])
            weights.append(exercise.weights[completedSetIndex])
            seconds.append(exercise.seconds[completedSetIndex])
            
            if PB < exercise.weights[completedSetIndex] {
                PB = exercise.weights[completedSetIndex]
                PBIndex = completedSetIndex
            }
        }

        if !reps.isEmpty {
            return ExerciseSnapshot(
                name: exercise.name,
                reps: reps,
                weights: weights,
                seconds: seconds,
                repsColumn: exercise.repsColumn,
                weightColumn: exercise.weightColumn,
                secsColumn: exercise.secsColumn,
                personalBestIndex: PBIndex
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
            seconds: exerciseSnapshot.seconds,
            completedSets: [],
            weights: exerciseSnapshot.weights,
            restTime: 60,// replace this with the users default rest time
            repsColumn: exerciseSnapshot.repsColumn,
            weightColumn: exerciseSnapshot.weightColumn,
            secsColumn: exerciseSnapshot.secsColumn,
            order: orderTracked
        )
        
        exercise.routine = finalRoutine
        
        return exercise
        
    }
    
    return finalRoutine
    
}

