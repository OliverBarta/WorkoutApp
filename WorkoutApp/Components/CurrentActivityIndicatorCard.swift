//
//  CurrentActivityIndicatorCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-19.
//

import SwiftUI
import SwiftData

struct CurrentActivityIndicatorCard: View {
    
    @Environment(WorkoutSession.self) private var workoutSession
    
    var body: some View {
        if let workoutRoutine = workoutSession.workoutRoutine {
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // progress bar
                    UnevenRoundedRectangle(
                        topLeadingRadius: 100,
                        bottomLeadingRadius: 100,
                        bottomTrailingRadius: workoutSession.getCompletedSetsPercentage() > 0.9 ? 100 : 0,
                        topTrailingRadius: workoutSession.getCompletedSetsPercentage() > 0.9 ? 100 : 0
                    )
                    .fill(Theme.progressBar)
                    .frame(width: (geometry.size.width - 40) * workoutSession.getCompletedSetsPercentage(), height: 60)
                    
                    Button {
                        workoutSession.showActiveWorkout = true
                    } label : {
                        HStack {
                            Text("\(workoutRoutine.name)")
                                .frame(alignment: .leading)
                                .padding(5)
                                .padding(.horizontal)
                            Spacer()
                            
                            WorkoutTimer()
                            
                            Button (role: .destructive) {
                                workoutSession.end()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Color.red)
                            }
                            .padding(.horizontal)
                            .buttonStyle(.plain)
                            
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .glassEffect()
                }
                .padding(.horizontal)
            }
        }
        
    }
    
}


#Preview {
    
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))

    return CurrentActivityIndicatorCard()
        .environment(session)
}
