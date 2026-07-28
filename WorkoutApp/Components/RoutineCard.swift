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
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSession.self) private var workoutSession
    
    @State private var showEditView = false
    @State private var showDoneDialog = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                Spacer()
                
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

            VStack(spacing: 12) {
                Button {
                    showEditView = true
                } label: {
                    Text("Edit Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    workoutSession.start(routine)
                    
                } label: {
                    Text("Start Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
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
    }
}

#Preview {
    RoutineCard(routine: Routine(name: "Routine 1"))
        .environment(WorkoutSession())
}
