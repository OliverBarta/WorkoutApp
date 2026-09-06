//
//  AppSettings.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-30.
//

import SwiftUI

struct ExerciseSetup: Codable {
    let reps: [Int]
    let weights: [Double]
    let seconds: [Int]
    let restTime: Int
    let repsColumn: Bool
    let weightColumn: Bool
    let secsColumn: Bool
    
    init(reps: [Int], weights: [Double], seconds: [Int], restTime: Int, repsColumn: Bool, weightColumn: Bool, secsColumn: Bool) {
        self.reps = reps
        self.weights = weights
        self.seconds = seconds
        self.restTime = restTime
        self.repsColumn = repsColumn
        self.weightColumn = weightColumn
        self.secsColumn = secsColumn
    }
}

// weights are always stored in pounds, so anything shown in kilograms is converted on the way
// out to the screen and back again on the way in. Routines get shared between users, so the
// stored number has to mean the same thing no matter what unit either of them is set to
enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }

    // the raw value doubles as the label shown next to a weight
    var label: String { rawValue }

    static let poundsPerKilogram = 2.20462262

    func fromPounds(_ pounds: Double) -> Double {
        switch self {
        case .pounds: pounds
        case .kilograms: pounds / Self.poundsPerKilogram
        }
    }

    func toPounds(_ shown: Double) -> Double {
        switch self {
        case .pounds: shown
        case .kilograms: shown * Self.poundsPerKilogram
        }
    }
}

// settings that apply across the whole app, kept on the device
@Observable
class AppSettings {

    private static let weightUnitKey = "weightUnit"
    private static let defaultRestSecondsKey = "defaultRestSeconds"
    private static let timerDefaultKey = "timerDefault"// whether the fullscreen timer starts as a stopwatch or countdown
    private static let routineNumberKey = "routineNumber"
    private static let addExerciseButtonsTopKey = "addExerciseButtonsTop"
    private static let addExerciseButtonsBotKey = "addExerciseButtonsBot"
    private static let addExerciseOnKey = "addExerciseOn"
    private static let personalBestsKey = "personalBests"
    private static let homeLeaderBoardModeKey = "homeLeaderBoardMode"// the mode of the leaderboard on the home page ("following" or "global"). saved here so theire choice stays where they left it
    private static let homeLeaderBoardExerciseNameKey = "homeLeaderBoardExerciseName"// the name of the leaderboard exercise on the home page
    private static let exerciseLeaderBoardModeKey = "exerciseLeaderBoardMode"// same as above but in the exerciseclickedView
    private static let weightHistoryKey = "weightHistory"// [String: [GraphDataPoint]]
    private static let volumeHistoryKey = "volumeHistory"// [String: [GraphDataPoint]]
    // the last setup for a given exercise so when you add an exercise to your workout it sets it up the same way you did last time
    private static let exerciseSetupKey = "exerciseSetup"
    private static let lastRestTimeKey = "lastRestTime"

    var weightUnit: WeightUnit {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: Self.weightUnitKey) }
    }
    
    var defaultRestSeconds: Int {
        didSet { UserDefaults.standard.set(defaultRestSeconds, forKey: Self.defaultRestSecondsKey) }
    }
    
    var timerDefault: String {
        didSet { UserDefaults.standard.set(timerDefault, forKey: Self.timerDefaultKey) }
    }
    
    var routineNumber: Int {
        didSet { UserDefaults.standard.set(routineNumber, forKey: Self.routineNumberKey) }
    }
    
    var addExerciseButtonsTop: Bool {
        didSet { UserDefaults.standard.set(addExerciseButtonsTop, forKey: Self.addExerciseButtonsTopKey) }
    }
    
    var addExerciseButtonsBot: Bool {
        didSet { UserDefaults.standard.set(addExerciseButtonsBot, forKey: Self.addExerciseButtonsBotKey) }
    }
    
    var addExerciseOn: String {
        didSet { UserDefaults.standard.set(addExerciseOn, forKey: Self.addExerciseOnKey) }
    }
    
    var personalBests: [String: Double] {
        didSet { UserDefaults.standard.set(personalBests, forKey: Self.personalBestsKey) }
    }
    
    var homeLeaderBoardMode: String {
        didSet { UserDefaults.standard.set(homeLeaderBoardMode, forKey: Self.homeLeaderBoardModeKey) }
    }
    
    var exerciseLeaderBoardMode: String {
        didSet { UserDefaults.standard.set(exerciseLeaderBoardMode, forKey: Self.exerciseLeaderBoardModeKey) }
    }
    
    var homeLeaderBoardExerciseName: String {
        didSet { UserDefaults.standard.set(homeLeaderBoardExerciseName, forKey: Self.homeLeaderBoardExerciseNameKey)}
    }
    
    var weightHistory: [String: [GraphDataPoint]] {
        didSet {
            if let encoded = try? JSONEncoder().encode(weightHistory) {
                UserDefaults.standard.set(encoded, forKey: "weightHistory")
            }
        }
    }
    
    var volumeHistory: [String: [GraphDataPoint]] {
        didSet {
            if let encoded = try? JSONEncoder().encode(volumeHistory) {
                UserDefaults.standard.set(encoded, forKey: "volumeHistory")
            }
        }
    }
    
    // the last setup for a given exercise so when you add an exercise to your workout it sets it up the same way you did last time
    var exerciseSetup: [String: ExerciseSetup] {
        didSet {
            if let encoded = try? JSONEncoder().encode(exerciseSetup) {
                UserDefaults.standard.set(encoded, forKey: "exerciseSetup")
            }
        }
    }
    
    var lastRestTime: Bool {
        didSet { UserDefaults.standard.set(lastRestTime, forKey: Self.lastRestTimeKey) }
    }

    // runs everytime the phone opens the app
    init() {
        let stored = UserDefaults.standard.string(forKey: Self.weightUnitKey)

        weightUnit = stored.flatMap(WeightUnit.init(rawValue:)) ?? .pounds
        
        if let stored = UserDefaults.standard.object(forKey: Self.defaultRestSecondsKey) as? Int {
            defaultRestSeconds = stored
        } else {
            defaultRestSeconds = 90// the default default rest seconds is 90
        }
        if let timerStored = UserDefaults.standard.string(forKey: Self.timerDefaultKey) {
            timerDefault = timerStored
        } else {
            timerDefault = "stopwatch"
        }

        if let routineNumberStored = UserDefaults.standard.object(forKey: Self.routineNumberKey) as? Int {
            routineNumber = routineNumberStored
        } else {
            routineNumber = 1
        }
        
        if let addExerciseButtonsTopStored = UserDefaults.standard.object(forKey: Self.addExerciseButtonsTopKey) as? Bool {
            addExerciseButtonsTop = addExerciseButtonsTopStored
        } else {
            addExerciseButtonsTop = true
        }
        
        if let addExerciseButtonsBotStored = UserDefaults.standard.object(forKey: Self.addExerciseButtonsBotKey) as? Bool {
            addExerciseButtonsBot = addExerciseButtonsBotStored
        } else {
            addExerciseButtonsBot = false
        }
        
        if let addExerciseOnStored = UserDefaults.standard.string(forKey: Self.addExerciseOnKey) {
            addExerciseOn = addExerciseOnStored
        } else {
            addExerciseOn = "bottom"
        }
        
        if let homeLeaderBoardModeStored = UserDefaults.standard.string(forKey: Self.homeLeaderBoardModeKey) {
            homeLeaderBoardMode = homeLeaderBoardModeStored
        } else {
            homeLeaderBoardMode = "global"
        }
        
        if let exerciseLeaderBoardModeStored = UserDefaults.standard.string(forKey: Self.exerciseLeaderBoardModeKey) {
            exerciseLeaderBoardMode = exerciseLeaderBoardModeStored
        } else {
            exerciseLeaderBoardMode = "following"
        }
        
        if let homeLeaderBoardExerciseNameStored = UserDefaults.standard.string(forKey: Self.homeLeaderBoardExerciseNameKey) {
            homeLeaderBoardExerciseName = homeLeaderBoardExerciseNameStored
        } else {
            homeLeaderBoardExerciseName = "Barbell bench press"
        }

        personalBests = UserDefaults.standard.dictionary(forKey: Self.personalBestsKey) as? [String: Double] ?? [:]
        
        if let data = UserDefaults.standard.data(forKey: "weightHistory"),
           let decoded = try? JSONDecoder().decode([String : [GraphDataPoint]].self, from: data) {
            weightHistory = decoded
        } else {
            weightHistory = [:]
        }
        
        if let data = UserDefaults.standard.data(forKey: "volumeHistory"),
           let decoded = try? JSONDecoder().decode([String : [GraphDataPoint]].self, from: data) {
            volumeHistory = decoded
        } else {
            volumeHistory = [:]
        }
        
        if let data = UserDefaults.standard.data(forKey: "exerciseSetup"),
           let decoded = try? JSONDecoder().decode([String : ExerciseSetup].self, from: data) {
            exerciseSetup = decoded
        } else {
            exerciseSetup = [:]
        }
        
        if let lastRestTimeStored = UserDefaults.standard.object(forKey: Self.lastRestTimeKey) as? Bool {
            lastRestTime = lastRestTimeStored
        } else {
            lastRestTime = true
        }
        
    }

    // wraps a binding holding pounds so an input box reads and writes the unit the user picked
    func weightBinding(_ pounds: Binding<Double>) -> Binding<Double> {
        // read the unit here rather than inside the closures so that using the binding in a view
        // body is what makes the view redraw when the unit changes
        let unit = weightUnit

        return Binding(
            // rounded because converting to kilograms otherwise fills the field with decimals
            get: { (unit.fromPounds(pounds.wrappedValue) * 100).rounded() / 100 },
            set: { pounds.wrappedValue = unit.toPounds($0) }
        )
    }
}
