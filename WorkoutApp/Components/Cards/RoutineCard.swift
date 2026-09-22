//
//  RoutineCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineCard: View {
    @Bindable var routine: Routine
    
    // whether or not the trash icon appears allowing you to delete the routine
    var deletableCard: Bool
    
    // environment variable for saving to the phone
    @Environment(\.modelContext) private var modelContext
    // environemnt variable for the current workout routine
    @Environment(WorkoutSession.self) private var workoutSession
    
    @Query(sort: \Routine.order) private var routines: [Routine]
    
    // environment variable for the user login
    @Environment(AuthManager.self) private var authManager
    
    @State private var showEditView = false
    @State private var showDoneDialog = false
    
    @State private var errorMessage = ""
    
    // a string of the exercises in the routine
    var exerciseString: String {
        var finalString = ""
        
        if routine.exercises.count == 1 {
            return routine.exercises[0].name
        }
        
        if routine.exercises.count == 0 {
            return "No exercises"
        }
        
        for exercise in routine.exercises.dropLast() {
            finalString += exercise.name + ", "
        }
        
        finalString += "and " + routine.exercises.last!.name
        
        return finalString
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                EditableTitle(name: $routine.name)
                    .font(.headline)
                
                Spacer()
                
                if deletableCard {
                    Button {
                        if workoutSession.isActive && workoutSession.workoutRoutine == routine {
                            errorMessage = "Cannot delete active workouts"
                        } else {
                            showDoneDialog = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .opacity((workoutSession.isActive && workoutSession.workoutRoutine == routine) ? 0.5 : 1)
                    
                }
                
            }
            
            Text(exerciseString)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            
            VStack(spacing: 12) {
                Button {
                    if workoutSession.isActive && workoutSession.workoutRoutine == routine {
                        errorMessage = "Cannot edit active workouts"
                    } else {
                        showEditView = true
                    }
                } label: {
                    Text("Edit Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .opacity((workoutSession.isActive && workoutSession.workoutRoutine == routine) ? 0.5 : 1)
                
                Button {
                    if workoutSession.isActive {
                        errorMessage = "End current workout to start a new one"
                    } else {
                        workoutSession.start(routine, modelContext, Date(), false, givenOriginalExercises: [], useGivenOriginalExercises: false)// the given original exercises is only used for WorkOutLongSave
                    }
                    
                } label: {
                    Text("Start Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .opacity(workoutSession.isActive ? 0.5 : 1)
                
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .fullScreenCover(isPresented: $showEditView) {
            RoutineEditView(routine: routine)
        }
        .sheet(isPresented: $showDoneDialog) {
            VStack(spacing: 16) {
                Text("Delete \"\(routine.name)?\"")
                    .font(.headline)
                    .padding()
                
                Button {
                    // deletes routine from supabase
                    Task {
                        do {
                            try await deleteRoutineFromSupabase(routine)
                            
                        } catch {
                            print("Supabase delete failed: \(error)")
                        }
                    }
                    
                    let routineOrder: Int = routine.order
                    
                    // deletes routine from the phones local storage
                    modelContext.delete(routine)
                    
                    for r in routines {
                        if r.order > routineOrder {
                            r.order -= 1
                        }
                    }
                } label: {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                
                Button {
                    showDoneDialog = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glass)
            }
            .padding()
            .presentationDetents([.height(230)])
            
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            TopPopUp(message: $errorMessage)
                .padding(.top)
        }
    }
}

#Preview {
    RoutineCard(routine: Routine(name: "Routine 1", order: 0), deletableCard: true)
        .environment(WorkoutSession())
        .environment(AuthManager())
}
