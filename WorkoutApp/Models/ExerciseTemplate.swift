//
//    ExerciseTemplate.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import Foundation

struct ExerciseTemplate: Decodable, Identifiable, Hashable {
    var id: String
    var name: String
    var force: String?          // null on 30 exercises
    var level: String
    var mechanic: String?       // null on 87 exercises
    var equipment: String?      // null on 77 exercises
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var category: String
    var images: [String]        // relative paths; empty on 3 exercises
}

extension ExerciseTemplate {
    /// The single muscle this exercise is filed under. 875 of 876 have exactly one.
    var primaryMuscle: String { primaryMuscles.first ?? "" }

    var equipmentLabel: String { equipment ?? "Other" }

    var hasImages: Bool { !images.isEmpty }

    /// Prefix the relative paths once you've picked a host.
    func imageURLs(base: URL) -> [URL] {
        images.map { base.appendingPathComponent($0) }
    }
}
