//
//  ExerciseCatalog.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-18.
//

import Foundation

enum ExerciseCatalog {
    static let all: [ExerciseTemplate] = load()

    /// O(1) lookup by slug, e.g. "Barbell_Curl".
    static let byId: [String: ExerciseTemplate] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    /// Alphabetical, for the exercise picker.
    static let sortedByName: [ExerciseTemplate] = all.sorted {
        $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }

    /// Every primary muscle present in the catalog, alphabetical. 17 values.
    static let muscleGroups: [String] = Set(all.map(\.primaryMuscle))
        .filter { !$0.isEmpty }
        .sorted()

    static func exercises(forMuscle muscle: String) -> [ExerciseTemplate] {
        sortedByName.filter { $0.primaryMuscle == muscle }
    }

    static func search(_ query: String) -> [ExerciseTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sortedByName }
        return sortedByName.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private static func load() -> [ExerciseTemplate] {
        guard let url = Bundle.main.url(forResource: "exercises-3", withExtension: "json") else {
            assertionFailure("exercises-3.json not in bundle — check Target Membership")
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
