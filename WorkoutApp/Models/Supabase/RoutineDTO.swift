//
//  RoutineDTO.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import Foundation

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
