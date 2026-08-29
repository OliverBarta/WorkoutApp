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
    
    // query makes routines the same everywhere so just type this and the variable is the same
    @Query private var routines: [Routine]

    private var nextRoutineNumber: Int { routines.count + 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)

                Button {
                    let newRoutine = Routine(name: "Routine \(nextRoutineNumber)")
                    modelContext.insert(newRoutine)
                } label : {
                    HStack {
                        Text("Routine")
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                ForEach(routines) { routine in
                    RoutineCard(routine: routine, deletableCard: true)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

            }
            .scrollIndicators(.hidden)// hides the side scroll bar
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
