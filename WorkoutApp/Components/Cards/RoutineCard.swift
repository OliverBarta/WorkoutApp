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
    
    // environment variable for the user login
    @Environment(AuthManager.self) private var authManager
    
    @State private var showEditView = false
    @State private var showDoneDialog = false
    
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
                Text(routine.name)
                    .font(.headline)
                
                Spacer()
                
                if deletableCard {
                    Button {
                        showDoneDialog = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
                
            }
            
            Text(exerciseString)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            
            VStack(spacing: 12) {
                Button {
                    showEditView = true
                } label: {
                    Text("Edit Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.liquidGlass(tintColor: Theme.grey))
                
                Button {
                    workoutSession.start(routine)
                    
                } label: {
                    Text("Start Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.liquidGlass(tintColor: Theme.primary))
                
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
                
                Button {
                    // deletes routine from supabase
                    Task {
                        do {
                            try await deleteRoutineFromSupabase(routine)
                        } catch {
                            print("Supabase delete failed: \(error)")
                        }
                    }
                    // deletes routine from the phones local storage
                    modelContext.delete(routine)
                } label: {
                    Text("Delete")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Color.red)
                .cornerRadius(12)
                
                Button {
                    showDoneDialog = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(Color.black)
                }
                .background(Theme.grey)
                .cornerRadius(12)
            }
            .padding()
            .presentationDetents([.height(180)])
            
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        
    }
}

//#Preview {
//    RoutineCard(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb"),Exercise(name: "Squats", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb"),Exercise(name: "Abs", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
//        .environment(WorkoutSession())
//}


//#Preview {
//    RoutineCard(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb"),Exercise(name: "Squats", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
//        .environment(WorkoutSession())
//}
//
//#Preview {
//    RoutineCard(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
//        .environment(WorkoutSession())
//}

#Preview {
    RoutineCard(routine: Routine(name: "Routine 1"), deletableCard: true)
        .environment(WorkoutSession())
        .environment(AuthManager())
}
