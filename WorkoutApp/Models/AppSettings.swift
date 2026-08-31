//
//  AppSettings.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-30.
//

import SwiftUI

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
    private static let timerDefaultKey = "timerDefault"

    var weightUnit: WeightUnit {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: Self.weightUnitKey) }
    }
    
    var defaultRestSeconds: Int {
        didSet { UserDefaults.standard.set(defaultRestSeconds, forKey: Self.defaultRestSecondsKey) }
    }
    
    var timerDefault: String {
        didSet { UserDefaults.standard.set(timerDefault, forKey: Self.timerDefaultKey) }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.weightUnitKey)

        weightUnit = stored.flatMap(WeightUnit.init(rawValue:)) ?? .pounds
        
        if let stored = UserDefaults.standard.object(forKey: Self.defaultRestSecondsKey) as? Int {
            defaultRestSeconds = stored
        } else {
            defaultRestSeconds = 90// the default default rest seconds is 90
        }
        
        timerDefault = "stopwatch"
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
