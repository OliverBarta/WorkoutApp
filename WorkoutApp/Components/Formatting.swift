//
//  SecondsToFormatted.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-22.
//

import SwiftUI
import SwiftData

// formats a given int of seconds to the format 00:00. 63 -> 01:03 or 00:00:00 if it is longer then 60 mins
func SecondsFormatted(_ seconds: Int) -> String {
    
    let minutes = seconds / 60
    
    if minutes >= 60 {
        let hours = minutes / 60
        let minutes = minutes - hours*60
        let seconds = seconds - 3600*hours - 60*minutes
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // only if under 60 mins
    let seconds = seconds % 60
    
    return String(format: "%02d:%02d", minutes, seconds)
}

// sets the weight number to display with at most 2 decimal places, but will try to use 0 decimal places unless the second or first decimal is non zero
// the weight comes in as pounds, since that is how every weight is stored
func formattedWeight(_ weight: Double, unit: WeightUnit) -> String {
    unit.fromPounds(weight).formatted(.number.precision(.fractionLength(0...2)))
}

// formats a given date and returns it as a string -> "Aug 22, 2026 at 6:09 PM"
func formattedDate(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .shortened)
}

// formats the sets for the workoutHistoryCard into "reps (if repsColumn) x weight (if weightColumn) lb x time (if secsColumn)"
// Example "10 x 10 lb x 01:30"
func formattedSet(reps: Int, weight: Double, seconds: Int, repsColumn: Bool, weightColumn: Bool, secsColumn: Bool, unit: WeightUnit) -> String {
    var parts: [String] = []

    if repsColumn { parts.append("\(reps)") }
    if weightColumn { parts.append("\(formattedWeight(weight, unit: unit)) \(unit.label)") }
    if secsColumn { parts.append(SecondsFormatted(seconds)) }

    return parts.joined(separator: " x ")
}
