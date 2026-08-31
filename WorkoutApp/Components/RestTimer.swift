//
//  RestTimer.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-22.
//


import SwiftUI
import SwiftData

struct RestTimer: View {
    @Environment(WorkoutSession.self) private var workoutSession
    
    @State private var now = Date()
    @State private var tickTimer: Timer?
    
    var body: some View {
        if let restTimerStartDate = workoutSession.restTimerStartDate,
           let exerciseBeingTimed = workoutSession.exerciseBeingTimed {
            GeometryReader { geometry in
                
                let rawWidth = (geometry.size.width - 32) * workoutSession.getCompletedRestTimePercentage()
                let barWidth = rawWidth.isFinite ? max(0, rawWidth) : 0
                let backgroundWidth = max(0, geometry.size.width - 32)
                
                Button {
                    workoutSession.showActiveWorkout = true
                } label: {
                    ZStack(alignment: .leading) {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 30,
                            bottomTrailingRadius: 30,
                            topTrailingRadius: 30
                        )
                        .fill(Theme.progressBar)
                        .frame(width: backgroundWidth)
                        .mask (
                            Rectangle()
                                .frame(width: barWidth)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .animation(.smooth(duration: 0.25), value: workoutSession.getCompletedRestTimePercentage())
                        )
                        
                        
                        // Layer 1: oppositeBackground version, visible everywhere the bar isn't
                        contentRow(textColor: Theme.oppositeBackground, startDate: restTimerStartDate, exercise: exerciseBeingTimed)
                            .mask(
                                Rectangle()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.leading, barWidth) // masks out (hides) everything left of the bar's edge
                            )
                        
                        // Layer 2: background version, visible only where the bar is covering
                        contentRow(textColor: Color.white, startDate: restTimerStartDate, exercise: exerciseBeingTimed)
                            .mask(
                                Rectangle()
                                    .frame(width: barWidth, alignment: .leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            )
                    }
                }
                .glassEffect()
                .padding(.horizontal)
            }
            .frame(height: 60)
            .onAppear {
                tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    now = Date()
                }
            }
            .onDisappear {
                tickTimer?.invalidate()
                tickTimer = nil
            }
        }
    }
    
    // this function creates a layer of all the content. so I use it to make 2 layers and mask them by the progress bar
    @ViewBuilder
    private func contentRow(textColor: Color, startDate: Date, exercise: Exercise) -> some View {
        
        HStack {
            Text("Rest time")
                .foregroundColor(textColor)
                .padding(5)
                .padding(.horizontal)
                .fontWeight(.bold)
            Spacer()
            
            let remainingTime = max(0, exercise.restTime - Int(now.timeIntervalSince(startDate)))
            
            Text(SecondsFormatted(remainingTime))
                .foregroundColor(textColor)
                .fontWeight(.bold)
            
            Button(role: .destructive) {
                workoutSession.stopRestTimer()
            } label: {
                Image(systemName: "forward.end")
                    .foregroundColor(textColor == Color.white ? Color.white : Color.red)
            }
            .padding(.horizontal)
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
//
//#Preview {
//    let session = WorkoutSession()
//    let exercise = Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3], seconds: [], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: false, order: 0)
//    session.start(Routine(name: "Routine 1", exercises: [exercise]))
//    session.startRestTimer(exercise)
//
//    return RestTimer()
//        .environment(session)
//}
