//
//  ExerciseCatalog.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-18.
//

import Foundation

enum ExerciseCatalog {
    static let all: [ExerciseTemplate] = load()

    private static func load() -> [ExerciseTemplate] {
        guard let url = Bundle.main.url(forResource: "exercises-2", withExtension: "json") else {
            assertionFailure("exercises.json not in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ExerciseTemplate].self, from: data)
        } catch {
            assertionFailure("Decode failed: \(error)")
            return []
        }
    }
}
