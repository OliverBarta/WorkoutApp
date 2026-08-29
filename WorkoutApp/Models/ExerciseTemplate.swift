//
//    ExerciseTemplate.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import SwiftData
import Foundation

struct ExerciseTemplate: Decodable, Identifiable, Hashable { // Should be decodable as we are converting a JSON file into instances of this struct
    var id: String
    var name: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
}
