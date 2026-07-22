//
//  GeneralTimer.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-21.
//

import SwiftUI
import SwiftData

struct GeneralCountDownTimer: View {
    
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    
    var countDownFrom: Int
    
    private var startDate: Date = Date()
    
    init(countDownFrom: Int) {
        self.countDownFrom = countDownFrom
    }

    private var formattedTime: String {
        let remaining = max(0, countDownFrom - elapsedSeconds)
        let minutes = remaining / 60
        let seconds = remaining % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        Text(formattedTime)
            .onAppear {
                elapsedSeconds = Int(Date().timeIntervalSince(startDate))
                
                // continuously counts every second it's open
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        elapsedSeconds = Int(Date().timeIntervalSince(startDate))
                }
            }
            .onDisappear {
                // stops processing the timer loops when the screen closes
                timer?.invalidate()
                timer = nil
            }
    }
}

#Preview {
    GeneralCountDownTimer(countDownFrom: 60)
}
