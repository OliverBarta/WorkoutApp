//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineSelectorView: View {
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
                if routines.isEmpty {
                    Text("No routines yet, create one by tapping the blue button above or by going to someones profile in Explore and copying one of their routines.")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                        .padding(.horizontal)
                } else {
                    ForEach(routines) { routine in
                        RoutineCard(routine: routine, deletableCard: true)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }

            }
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Routines")
                        .headerStyle()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    RoutineSelectorView()
        .modelContainer(for: Routine.self, inMemory: true)
        .environment(WorkoutSession())
}
