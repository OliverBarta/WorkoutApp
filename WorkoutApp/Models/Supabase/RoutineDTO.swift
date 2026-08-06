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
    var weights: [Int]
    var restTime: Int
    var type: String
    var order: Int
}

struct RoutineDTO: Codable {
    var id: UUID
    var user_id: UUID
    var name: String
    var exercises: [ExerciseDTO]
}
