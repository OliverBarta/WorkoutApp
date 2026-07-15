//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]

    private var nextRoutineNumber: Int { routines.count + 1 }

    var body: some View {
        NavigationStack {
            VStack {
                Text("Workouts")
                    .headerStyle()

                Button("Add Routine") {
                    let newRoutine = Routine(name: "Routine \(nextRoutineNumber)")
                    modelContext.insert(newRoutine)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()

                List (routines, id: \.self) { routine in
                    RoutineCard(routine: routine)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                .listRowSpacing(24)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: Routine.self, inMemory: true)
}
