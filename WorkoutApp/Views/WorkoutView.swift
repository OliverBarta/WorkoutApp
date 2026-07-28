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
            ScrollView {

                Button {
                    let newRoutine = Routine(name: "Routine \(nextRoutineNumber)")
                    modelContext.insert(newRoutine)
                } label : {
                    Text("Routine")
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 50)
                .padding(.horizontal)
                
                ForEach(routines) { routine in
                    RoutineCard(routine: routine)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.bottom, 15)
                }

            }
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Workouts")
                        .headerStyle()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
            .modelContainer(for: Routine.self, inMemory: true)
            .environment(WorkoutSession())
}
