//
//  RoutineCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI
import SwiftData

struct RoutineCard: View {
    let routine: Routine
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
                Text(routine.name)
                    .font(.headline)
                Spacer()
                
                Button {
                    modelContext.delete(routine)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .symbolRenderingMode(.hierarchical)
                }
                    
            }


            VStack(spacing: 12) {
                ZStack {
                    NavigationLink("") {
                        RoutineEditView(routine: routine)
                    }
                    .opacity(0)

                    Button {
                    } label: {
                        Text("Edit Routine")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .allowsHitTesting(false)
                }
                
                

                

                Button {
                    // wire up later
                } label: {
                    Text("Start Routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    RoutineCard(routine: Routine(name: "Routine 1"))
}
