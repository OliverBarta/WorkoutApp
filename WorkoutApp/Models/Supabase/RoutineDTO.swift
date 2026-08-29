//
//  RoutineDTO.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import Foundation
// this is the struct that makes the exercise able to be written into a json file, so it can be written into one cell on a supabase data table
struct ExerciseDTO: Codable {
    var name: String
    var reps: [Int]
    var weights: [Double]
    var seconds: [Int]
    var restTime: Int
    // these 3 bools are whether or not the reps / weight / seconds column is shown for this exercise
    var repsColumn: Bool = true
    var weightColumn: Bool = true
    var secsColumn: Bool = false
    var order: Int
}

struct RoutineDTO: Codable {
    var id: UUID
    var user_id: UUID
    var name: String
    var exercises: [ExerciseDTO]
}

extension RoutineDTO {
    func toModel() -> Routine {
        let routine = Routine(id: id, name: name)
        routine.exercises = exercises.map {
            Exercise(
                name: $0.name,
                reps: $0.reps,
                seconds: $0.seconds,
                completedSets: [],
                weights: $0.weights,
                restTime: $0.restTime,
                repsColumn: $0.repsColumn,
                weightColumn: $0.weightColumn,
                secsColumn: $0.secsColumn,
                order: $0.order
            )
        }
        return routine
    }
}

extension ExerciseDTO {
    func toModel() -> Exercise {
        Exercise(
            name: name,
            reps: reps,
            seconds: seconds,
            completedSets: [],
            weights: weights,
            restTime: restTime,
            repsColumn: repsColumn,
            weightColumn: weightColumn,
            secsColumn: secsColumn,
            order: order
        )
    }
}
