//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \WorkoutHistoryEntry.dateCompleted, order: .reverse) private var history: [WorkoutHistoryEntry]

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    if history.isEmpty {
                        Text("No workouts logged yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 60)
                    } else {
                        ForEach(history) { entry in
                            WorkoutHistoryCard(entry: entry)
                        }
                    }
                }
                .padding(.top, 45)
            }
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Profile")
                        .headerStyle()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: WorkoutHistoryEntry.self, inMemory: true)
}
