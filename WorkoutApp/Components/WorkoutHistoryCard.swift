//
//  WorkoutHistoryCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-27.
//

import SwiftUI

struct WorkoutHistoryCard: View {
    
    let entry: WorkoutHistoryEntry

    private var formattedDate: String {
        entry.dateCompleted.formatted(date: .abbreviated, time: .shortened)
    }
    
    var body: some View {
        Button {
            // code this in the future
            // this should open this workout
        } label : {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.routineName)
                        .font(.headline)
                    Spacer()
                    Text(SecondsFormatted(seconds: entry.durationSeconds))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(formattedDate)
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
                                ForEach(Array(zip(exercise.reps, exercise.weights).enumerated()), id: \.offset) { index, pair in
                                    let (reps, weight) = pair
                                    Text("\(reps) x \(weight)\(exercise.type)")
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
    }
}

#Preview {
    WorkoutHistoryCard(
        entry: WorkoutHistoryEntry(
            routineName: "Push Day",
            durationSeconds: 2401,
            exerciseSnapshots: [
                ExerciseSnapshot(name: "Bench Press", reps: [8,8,8], weights: [135,135,135], type: "lb")
            ]
        )
    )
}
