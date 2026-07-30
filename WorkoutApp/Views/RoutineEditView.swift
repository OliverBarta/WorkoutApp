//
//  RoutineEditView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineEditView: View {
    @Bindable var routine: Routine
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var keyboardObserver = KeyboardObserver()
    
    @State private var showExerciseSearch = false

    private var sortedExercises: [Exercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // rectangle bumps the rest of the scroll bar down so its under the tool bar (tool bar = overlay)
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 30)
                
                TextField("Routine name", text: $routine.name)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                HStack {
                    Button {
                        showExerciseSearch = true
                    } label : {
                        Text("Exercise")
                        Image(systemName: "plus")
                    }
                    .padding(.horizontal)
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button {
                        let newExercise = Exercise(
                            name: "New Exercise",
                            reps: [8],
                            completedSets: [],
                            weights: [0],
                            restTime: 60,
                            type: "lb",
                            order: routine.exercises.count
                        )
                        routine.exercises.append(newExercise)
                    } label : {
                       Text("Custom Exercise")
                       Image(systemName: "plus")
                    }
                    .padding(.horizontal)
                    
                }
                
                ForEach(sortedExercises) { exercise in
                    ExerciseEditCard(exercise: exercise)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    
                }
                .padding(.top, 10)
                
            }
            .frame(maxHeight: .infinity)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .overlay {
            VStack {
                ZStack {
                    Text("Edit \(routine.name)")
                        .headerStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    .padding(.horizontal)
                    
                }
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if keyboardObserver.isVisible {
                HStack {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            ExerciseSearchView(routine: routine)
        }
    }
}

#Preview {
    RoutineEditView(routine: Routine(name: "Routine 1", exercises: [Exercise(name: "Bench Press", reps: [3,3,3], completedSets: [], weights: [10, 10, 10], restTime: 60, type: "lb")]))
}
