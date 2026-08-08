//
//  RoutineSpectateView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import SwiftUI
import SwiftData

// a view to see other peoples workouts. You cant edit the routine but you can save it to your own routines.
struct RoutineSpectateView: View {
    
    let routine: Routine
    
    @Query private var routines: [Routine]
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var errorMessage: String = ""
    
    private var sortedExercises: [Exercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // rectangle bumps the rest of the scroll bar down so its under the tool bar (tool bar = overlay)
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)
                
                ForEach(sortedExercises) { exercise in
                    UneditableExerciseCard(exercise: exercise)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    
                }
                .padding(.top, 10)
                
            }
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxHeight: .infinity)
        }
        .overlay {
            VStack {
                ZStack {
                    Text(routine.name)
                        .headerStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .padding(5)
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            // saves the routine to the users routines on the database and locally
                            // database save
                            Task {
                                do {
                                    
                                    let newRoutine = try await copyRoutineToSupabase(routine)
                                    
                                    modelContext.insert(newRoutine)
                                } catch {
                                    errorMessage = "Failed to upload routine error: \(error.localizedDescription)"
                                }
                            }
                            
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .padding(5)
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        
                    }
                    .padding(.horizontal)
                    
                }
                
                TopPopUp(message: $errorMessage)
                
                Spacer()
            }
        }
    }
}

#Preview {
    RoutineSpectateView(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb"),Exercise(name: "Squat", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
        .modelContainer(for: Routine.self, inMemory: true)
}
