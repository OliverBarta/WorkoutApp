//
//    ExerciseTemplate.swift
//  WorkoutApp
//
//  Created by Joshua Lin on 2026-07-17.
//

import SwiftData
import Foundation

@Model
class ExerciseTemplate {
    var name: String
    var muscleGroup: String
    var imageName: String
    
    init(name: String, muscleGroup: String, imageName: String) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.imageName = imageName
    }
}
