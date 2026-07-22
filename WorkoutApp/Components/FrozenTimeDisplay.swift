//
//  FrozenTimeDisplay.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-21.
//

import SwiftUI
import SwiftData

struct FrozenTimeDisplay: View {
    
    var displayTimeSeconds: Int

    private var formattedTime: String {
        
        let minutes = displayTimeSeconds / 60
        let seconds = displayTimeSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        Text(formattedTime)
    }
}

#Preview {
    FrozenTimeDisplay(displayTimeSeconds: 60)
}
