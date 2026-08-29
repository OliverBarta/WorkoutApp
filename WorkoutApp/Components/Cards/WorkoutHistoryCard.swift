//
//  WorkoutHistoryCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-27.
//

import SwiftUI


struct WorkoutHistoryCard: View {
    
    let entry: WorkoutHistoryEntry
    
    @State private var showSpectateView: Bool = false
    
    var body: some View {
        Button {
            // code this in the future
            showSpectateView = true
        } label : {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.routineName)
                        .font(.headline)
                    Spacer()
                    Text(SecondsFormatted(entry.durationSeconds))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(formattedDate(entry.dateCompleted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(entry.exerciseSnapshots) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<min(exercise.reps.count, exercise.weights.count, exercise.seconds.count), id: \.self) { index in
                                    Text(formattedSet(reps: exercise.reps[index], weight: exercise.weights[index], seconds: exercise.seconds[index], repsColumn: exercise.repsColumn, weightColumn: exercise.weightColumn, secsColumn: exercise.secsColumn))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)
            .cornerRadius(12)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $showSpectateView) {
            RoutineSpectateView(routine: workoutHistoryToRoutine(entry))
        }
    }
}

#Preview {
    WorkoutHistoryCard(
        entry: WorkoutHistoryEntry(
            routineName: "Push Day",
            durationSeconds: 30000,
            exerciseSnapshots: [
                ExerciseSnapshot(name: "Bench Press", reps: [8,8,8], weights: [135.0,135.0,135.0], seconds: [0,0,0], repsColumn: true, weightColumn: true, secsColumn: false)
            ]
        )
    )
}
