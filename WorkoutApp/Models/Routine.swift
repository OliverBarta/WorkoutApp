//
//  Routine.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftData
import Foundation

// this is the base class for exercises and routines. every other class stems from this one

extension Exercise {
    func copy() -> Exercise {
        Exercise(
            name: name,
            reps: reps,
            seconds: seconds,
            completedSets: completedSets,
            weights: weights,
            restTime: restTime,
            repsColumn: repsColumn,
            weightColumn: weightColumn,
            secsColumn: secsColumn,
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

// reps, weights and seconds are parallel arrays with one entry per set, so sets get added and
// removed through these two to keep all three the same length
extension Exercise {
    func addSet() {
        reps.append(reps.last ?? 0)
        weights.append(weights.last ?? 0)
        seconds.append(seconds.last ?? 0)
    }

    func removeSet(at index: Int) {
        reps.remove(at: index)
        weights.remove(at: index)
        seconds.remove(at: index)

        // completedSets holds set indexes, so everything after the removed set shifts down by one
        completedSets = Set(completedSets.compactMap { completedIndex in
            if completedIndex == index { return nil }
            return completedIndex > index ? completedIndex - 1 : completedIndex
        })
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
    var weights: [Double]
    var seconds: [Int]
    var restTime: Int
    // these 3 bools are whether or not the reps / weight / seconds column is shown for this exercise
    var repsColumn: Bool
    var weightColumn: Bool
    var secsColumn: Bool
    var order: Int

    var routine: Routine?

    // seconds has no default so every caller has to pass one the same length as reps
    init(name: String, reps: [Int], seconds: [Int], completedSets: Set<Int>, weights: [Double], restTime: Int, repsColumn: Bool = true, weightColumn: Bool = true, secsColumn: Bool = false, order: Int = 0) {
        self.name = name
        self.reps = reps
        self.seconds = seconds
        self.completedSets = completedSets
        self.weights = weights
        self.restTime = restTime
        self.repsColumn = repsColumn
        self.weightColumn = weightColumn
        self.secsColumn = secsColumn
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

// given exercises and a string returns a routine
func exercisesToRoutine(_ exercises: [Exercise], name: String) -> Routine {
    // exercises is a pointer so we need to copy it
    return Routine(name: name, exercises: exercises.map { $0.copy() })
    
}
