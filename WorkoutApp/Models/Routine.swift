//
//  Routine.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftData
import Foundation


extension Exercise {
    func copy() -> Exercise {
        Exercise(
            name: name,
            reps: reps,
            completedSets: completedSets,
            weights: weights,
            restTime: restTime,
            type: type,
            order: order
        )
    }
}

// copies but sets the completed sets to zero. So when you update the routine it updates everything but resets the completedSets.
extension Exercise {
    func copyCompletedSetsToZero() -> Exercise {
        Exercise(
            name: name,
            reps: reps,
            completedSets: [],
            weights: weights,
            restTime: restTime,
            type: type,
            order: order
        )
    }
}

extension Routine {
    func copy() -> Routine {
        Routine(
            name: name,
            exercises: exercises.map { $0.copy() }
        )
    }
}

@Model
class Exercise {
    var name: String
    var reps: [Int] // a array of reps
    var completedSets: Set<Int>
    var weights: [Int]
    var restTime: Int
    var type: String
    var order: Int

    var routine: Routine?

    init(name: String, reps: [Int], completedSets: Set<Int>, weights: [Int], restTime: Int, type: String, order: Int = 0) {
        self.name = name
        self.reps = reps
        self.completedSets = completedSets
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
