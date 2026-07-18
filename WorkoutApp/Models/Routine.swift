//
//  Routine.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftData
import Foundation

@Model
class Exercise {
    var name: String
    var reps: [Int] // sets
    var weights: [Int]
    var restTime: Int
    var type: String
    var order: Int

    var routine: Routine?

    init(name: String, reps: [Int], weights: [Int], restTime: Int, type: String, order: Int = 0) {
        self.name = name
        self.reps = reps
        self.weights = weights
        self.restTime = restTime
        self.type = type
        self.order = order
    }
}

@Model
class Routine {
    var id: UUID
    var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \Exercise.routine)
    var exercises: [Exercise]

    init(id: UUID = UUID(), name: String, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}
