//
//  timerFullscreen.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-29.
//

import SwiftUI

struct TimerFullscreen: View {

    @Binding var secondsRecorded: Int
    
    let attachedSet: Int

    @Environment(\.dismiss) private var dismiss

    @State private var feedType: String = "stopwatch"

    // stopwatch state. times are tracked with dates so it stays accurate if the app is backgrounded
    @State private var stopwatchStartDate: Date?
    @State private var stopwatchAccumulated: TimeInterval = 0

    // timer state
    @State private var timerEndDate: Date?
    @State private var timerRemainingWhenPaused: TimeInterval = 0
    @State private var timerDuration: TimeInterval = 0
    @State private var pickerHours: Int = 0
    @State private var pickerMinutes: Int = 1
    @State private var pickerSeconds: Int = 0

    private var stopwatchRunning: Bool { stopwatchStartDate != nil }
    private var timerRunning: Bool { timerEndDate != nil }
    // the timer has been set up (running or paused) as opposed to still showing the wheels
    private var timerActive: Bool { timerRunning || timerRemainingWhenPaused > 0 }

    private var pickedDuration: TimeInterval {
        TimeInterval(pickerHours * 3600 + pickerMinutes * 60 + pickerSeconds)
    }

    var body: some View {
        VStack {
            Text("Timer attached to set \(attachedSet)")
                .headerStyle()
            
            Picker("Feed", selection: $feedType) {
                Text("Stopwatch").tag("stopwatch")
                Text("Timer").tag("timer")
            }
            .pickerStyle(.segmented)
            .padding()

            // redraws every frame so the digits and the ring move smoothly, but pauses when nothing is counting
            TimelineView(.animation(paused: !(stopwatchRunning || timerRunning))) { context in
                let now = context.date

                if feedType == "stopwatch" {
                    // the stopwatch has nothing to count down to, so it shows the digits on their own
                    dial(label: formattedStopwatch(stopwatchElapsed(at: now)))
                } else {
                    let remaining = timerRemaining(at: now)

                    if timerActive {
                        dial(
                            label: SecondsFormatted(Int(remaining.rounded(.up))),
                            // the ring drains as the countdown runs down
                            progress: timerDuration > 0 ? remaining / timerDuration : 0,
                            ringColor: Theme.orange
                        )
                    } else {
                        durationPicker
                    }
                }
            }

            controls
                .padding(.horizontal, 40)

            logButton
                .padding()
            
            Button {
                dismiss()
            } label : {
                Text("Close")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal)
            .buttonStyle(.glassProminent)
            .tint(Color.red)
        }
        .onAppear {
            // the timer wheels start on whatever time was already recorded for the set
            guard secondsRecorded > 0 else { return }

            // the hours wheel only goes to 23, so anything longer clamps onto it
            pickerHours = min(23, secondsRecorded / 3600)
            pickerMinutes = (secondsRecorded % 3600) / 60
            pickerSeconds = secondsRecorded % 60
        }
    }

    // MARK: - big circle

    // the ring is optional, so a mode with nothing to fill up can just show the digits
    @ViewBuilder
    private func dial(label: String, progress: Double? = nil, ringColor: Color = Theme.primary) -> some View {
        ZStack {
            if let progress {
                Circle()
                    .stroke(Theme.progressBarBackground, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    // trim starts at 3 o'clock by default, so rotate it up to 12 o'clock
                    .rotationEffect(.degrees(-90))
            }

            Text(label)
                .font(.system(size: 90, weight: .light, design: .rounded))
                // stops the digits from jittering as the numbers change width
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        // the stroke is centred on the circle's path, so half its width sits outside it
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var durationPicker: some View {
        HStack(spacing: 0) {
            wheel(range: 0..<24, selection: $pickerHours, unit: "hours")
            wheel(range: 0..<60, selection: $pickerMinutes, unit: "min")
            wheel(range: 0..<60, selection: $pickerSeconds, unit: "sec")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - buttons

    private var controls: some View {
        HStack {
            if feedType == "stopwatch" {
                circleButton(title: "Reset", tint: Theme.grey, enabled: stopwatchElapsed(at: Date()) > 0) {
                    stopwatchStartDate = nil
                    stopwatchAccumulated = 0
                }

                Spacer()

                circleButton(title: stopwatchRunning ? "Stop" : (stopwatchAccumulated > 0 ? "Resume" : "Start"),
                             tint: stopwatchRunning ? .red : .green,
                             enabled: true) {
                    if stopwatchRunning {
                        stopwatchAccumulated = stopwatchElapsed(at: Date())
                        stopwatchStartDate = nil
                    } else {
                        stopwatchStartDate = Date()
                    }
                }
            } else {
                circleButton(title: "Cancel", tint: Theme.grey, enabled: timerActive) {
                    timerEndDate = nil
                    timerRemainingWhenPaused = 0
                    timerDuration = 0
                }

                Spacer()

                circleButton(title: timerRunning ? "Pause" : (timerActive ? "Resume" : "Start"),
                             tint: timerRunning ? .orange : .green,
                             enabled: timerActive || pickedDuration > 0) {
                    if timerRunning {
                        timerRemainingWhenPaused = timerRemaining(at: Date())
                        timerEndDate = nil
                    } else if timerActive {
                        timerEndDate = Date().addingTimeInterval(timerRemainingWhenPaused)
                        timerRemainingWhenPaused = 0
                    } else {
                        timerDuration = pickedDuration
                        timerEndDate = Date().addingTimeInterval(pickedDuration)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func circleButton(title: String, tint: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .foregroundStyle(enabled ? tint : Theme.grey)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(tint.opacity(0.2))
                        .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }

    // saves whatever the current mode has counted back to the caller
    private var logButton: some View {
        Button {
            if feedType == "stopwatch" {
                secondsRecorded = Int(stopwatchElapsed(at: Date()))
            } else {
                // the timer logs the time that has actually been counted down, not what is left
                secondsRecorded = Int((timerDuration - timerRemaining(at: Date())).rounded())
            }
            dismiss()
        } label: {
            Text("Record to set \(attachedSet)")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.glassProminent)
        
    }

    // MARK: - time math

    private func stopwatchElapsed(at now: Date) -> TimeInterval {
        guard let stopwatchStartDate else { return stopwatchAccumulated }
        return stopwatchAccumulated + now.timeIntervalSince(stopwatchStartDate)
    }

    private func timerRemaining(at now: Date) -> TimeInterval {
        guard let timerEndDate else { return timerRemainingWhenPaused }
        return max(0, timerEndDate.timeIntervalSince(now))
    }

    // stopwatch shows hundredths like the clock app does, until it passes an hour
    private func formattedStopwatch(_ elapsed: TimeInterval) -> String {
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        let hundredths = Int((elapsed - floor(elapsed)) * 100)

        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}


#Preview {
    @Previewable @State var secondsRecorded: Int = 90

    TimerFullscreen(secondsRecorded: $secondsRecorded, attachedSet: 1)
}
