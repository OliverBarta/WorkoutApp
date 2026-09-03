//
//  RoutineHistory.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-02.
//
import SwiftData
import Foundation

// the class that is saved to supabase history
@Model
class ExerciseHistory {
    var name: String
    var reps: [Int]
    var weights: [Double]
    var seconds: [Int]
    var restTime: Int
    var repsColumn: Bool
    var weightColumn: Bool
    var secsColumn: Bool
    var order: Int
    var personalBestIndex: Int

    var routine: RoutineHistory?

    init(name: String, reps: [Int], seconds: [Int], weights: [Double], restTime: Int, repsColumn: Bool = true, weightColumn: Bool = true, secsColumn: Bool = false, order: Int = 0, personalBestIndex: Int) {
        self.name = name
        self.reps = reps
        self.seconds = seconds
        self.weights = weights
        self.restTime = restTime
        self.repsColumn = repsColumn
        self.weightColumn = weightColumn
        self.secsColumn = secsColumn
        self.order = order
        self.personalBestIndex = personalBestIndex
    }
}

@Model
class RoutineHistory {
    var id: UUID
    var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseHistory.routine)
    var exercises: [ExerciseHistory]

    init(id: UUID = UUID(), name: String, exercises: [ExerciseHistory] = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

// exerciseHistoryDTO and name of routine to RoutineHistory
func exercisesToRoutineHistory(_ exercises: [ExerciseHistoryDTO], name: String) -> RoutineHistory {
    let routineHistory = RoutineHistory(name: name)

    routineHistory.exercises = exercises.map { exerciseDTO in
        let exerciseHistory = exerciseDTO.toModel()

        exerciseHistory.routine = routineHistory

        return exerciseHistory
    }

    return routineHistory
}

// converts a RoutineHistory into type Routine, so a logged workout can be re-run or copied.
// the routine gets a fresh id rather than reusing the history id, since the two live in
// separate tables. personalBestIndex has no equivalent on Exercise so it is dropped
func routineHistoryToRoutine(_ routineHistory: RoutineHistory) -> Routine {
    let finalRoutine = Routine(name: routineHistory.name)

    finalRoutine.exercises = routineHistory.exercises.map { exerciseHistory in
        let exercise = Exercise(
            name: exerciseHistory.name,
            reps: exerciseHistory.reps,
            seconds: exerciseHistory.seconds,
            completedSets: [],
            weights: exerciseHistory.weights,
            restTime: exerciseHistory.restTime,
            repsColumn: exerciseHistory.repsColumn,
            weightColumn: exerciseHistory.weightColumn,
            secsColumn: exerciseHistory.secsColumn,
            order: exerciseHistory.order
        )

        exercise.routine = finalRoutine

        return exercise
    }

    return finalRoutine
}

