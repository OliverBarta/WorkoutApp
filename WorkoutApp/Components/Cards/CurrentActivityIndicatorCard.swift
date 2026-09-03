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
    
    @State private var showEndWorkoutVerification: Bool = false
    
    var body: some View {
        if let workoutRoutine = workoutSession.workoutRoutine {
            GeometryReader { geometry in
                let barWidth = (geometry.size.width - 32) * workoutSession.getCompletedSetsPercentage()
                
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
                        .frame(width: geometry.size.width - 32, height: 60)
                        .mask(
                            Rectangle()
                                .frame(width: barWidth)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                        
                        // Layer 1: oppositeBackground version, visible everywhere the bar isn't
                        contentRow(routineName: workoutRoutine.name, textColor: Theme.oppositeBackground)
                            .mask(
                                Rectangle()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.leading, barWidth)
                            )
                        
                        // Layer 2: background version, visible only where the bar is covering
                        contentRow(routineName: workoutRoutine.name, textColor: Color.white)
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
            .sheet(isPresented: $showEndWorkoutVerification) {
                VStack {
                    Text("End workout without logging?")
                        .padding()
                        .font(.headline)
                    
                    Button {
                        workoutSession.end()
                    } label: {
                        Text("End")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.red)
                    
                    Button {
                        showEndWorkoutVerification = false
                    } label : {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.glass)
                }
                .padding()
                .presentationDetents([.height(230)])
            }
            .frame(height: 60)
        }
    }
    
    // this function creates a layer of all the content. so I use it to make 2 layers and mask them by the progress bar
    @ViewBuilder
    private func contentRow(routineName: String, textColor: Color) -> some View {
        HStack {
            Text(routineName)
                .foregroundColor(textColor)
                .padding(5)
                .padding(.horizontal)
                .fontWeight(.bold)
            Spacer()
            
            WorkoutTimer()
                .foregroundColor(textColor)
                .fontWeight(.bold)
            
            Button(role: .destructive) {
                showEndWorkoutVerification = true
            } label: {
                Image(systemName: "trash")
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

#Preview {
    let session = WorkoutSession()
    session.start(Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3,3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7,8,9,10], weights: [3,3,3,3,3,3,3,3,3,3,3], restTime: 60)]))

    return CurrentActivityIndicatorCard()
        .environment(session)
}
