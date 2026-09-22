//
//  SSDInProgressWorkout.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-17.
//

import SwiftUI
import Foundation
import Observation
import SwiftData

// saves an active workout to iphone ssd.
// If the app crashes the WorkoutSession will be lost but since the routine is passed by reference to a WorkOutLongSave instance, it is still saved.
// on launch of the app after a mid workout crash the ContinueWhereYouLeftOff screen will pop up and ask if you want to continue or not.
// if not, it will delete the WorkOutLongSave instance
// if continue, it will start a workout with the routine as a copy of the saved routine and the start date as the saved start date.
@Model
class WorkOutLongSave {
    var startDate: Date
    var routine: Routine
    
    @Relationship(deleteRule: .cascade)
    var originalExercises: [Exercise]
    
    init (startDate: Date, routine: Routine, originalExercises: [Exercise]) {
        self.startDate = startDate
        self.routine = routine
        self.originalExercises = originalExercises
    }
}

