//
//  ExerciseCatalog.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-18.
//

import Foundation

enum ExerciseCatalog {
    static let all: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Bench Press", muscleGroup: "Chest", imageName: "bench-press"),
        ExerciseTemplate(name: "Squat Barbell", muscleGroup: "Legs", imageName: "squat-barbell"),
        // TODO: Add more exercises, perhaps use a JSON file instead
    ]
}
