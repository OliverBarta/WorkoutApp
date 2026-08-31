//
//  ExcerciseEditCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData


// the exercise card for edit view
struct ExerciseEditCard: View {
    @Bindable var exercise: Exercise
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    private let rowHeight: CGFloat = 60
    
    @State private var editRestTimeView: Bool = false
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                EditableTitle(name: $exercise.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Menu {
                    Toggle("Reps column", isOn: $exercise.repsColumn)
                    Toggle("Weight column", isOn: $exercise.weightColumn)
                    Toggle("Time column", isOn: $exercise.secsColumn)
                    Button {
                        editRestTimeView = true
                    } label: {
                        Text("Edit rest time")
                        Image(systemName: "clock")
                    }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(exercise)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .frame(alignment: .trailing)
            }
            
            List {
                ForEach(Array(exercise.reps.indices), id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if exercise.repsColumn {
                            Spacer()
                            EditableStat(value: $exercise.reps[index])
                            Text("reps")
                                .foregroundColor(.secondary)
                        }
                        if exercise.weightColumn {
                            Spacer()
                            EditableStatDouble(value: appSettings.weightBinding($exercise.weights[index]))
                            Text(appSettings.weightUnit.label)
                                .foregroundColor(.secondary)
                        }
                        if exercise.secsColumn {
                            Spacer()
                            EditableTime(value: $exercise.seconds[index])
                                .padding(.leading)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exercise.removeSet(at: index)
                        }
                        .labelStyle(.titleOnly)
                    }
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)// hides the side scroll bar
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .listRowSpacing(0)
            .padding(.horizontal, -16)
            .frame(height: CGFloat(exercise.reps.count) * rowHeight)

            Button {
                exercise.addSet()
            } label : {
                Text("Add set")
                Image(systemName: "plus")
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: editRestTimeView) { _, isPresented in// sets the picker wheel variables to the current rest time
            if isPresented {
                pickerMinutes = exercise.restTime / 60
                pickerSeconds = exercise.restTime % 60
            }
        }
        .sheet(isPresented: $editRestTimeView) {// edit rest timer sheet
            VStack {
                Text("Edit rest time from \(SecondsFormatted(exercise.restTime))")
                    .padding()
                    .font(.headline)
                
                HStack(spacing: 0) {
                    wheel(range: 0..<60, selection: $pickerMinutes, unit: "min")
                    wheel(range: 0..<60, selection: $pickerSeconds, unit: "sec")
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    exercise.restTime = pickerMinutes*60 + pickerSeconds
                    editRestTimeView = false
                } label : {
                    Text("Set rest time")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal)
                
                Button {
                    editRestTimeView = false
                } label : {
                    Text("Cancel")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.red)
                .padding(.horizontal)
            }
            .presentationDetents([.height(380)])
        }
        
    }
    
}

#Preview {
    ExerciseEditCard(
        exercise: Exercise(name: "Dumbell Bicep curl", reps: [3,3,3,3,3,3,3,3], seconds: [0,0,0,0,0,0,0,0], completedSets: [1,2,3,4,5,6,7], weights: [3,3,3,3,3,3,3,3], restTime: 10, repsColumn: true, weightColumn: true, secsColumn: true, order: 0)
    )
    .environment(AppSettings())
}
