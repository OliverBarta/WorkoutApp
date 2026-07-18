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
            
            Text("Workouts")
                .headerStyle()
            
            ScrollView {

                Button("Add Routine") {
                    let newRoutine = Routine(name: "Routine \(nextRoutineNumber)")
                    modelContext.insert(newRoutine)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
                
                ForEach(routines) { routine in
                    RoutineCard(routine: routine)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.bottom, 15)
                }

            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: Routine.self, inMemory: true)
}
