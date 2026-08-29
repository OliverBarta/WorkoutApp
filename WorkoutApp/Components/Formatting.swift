//
//  SecondsToFormatted.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-22.
//

import SwiftUI
import SwiftData

// formats a given int of seconds to the format 00:00. 63 -> 01:03
func SecondsFormatted(seconds: Int) -> String {
    
    let minutes = seconds / 60
    let seconds = seconds % 60
    
    return String(format: "%02d:%02d", minutes, seconds)
}
