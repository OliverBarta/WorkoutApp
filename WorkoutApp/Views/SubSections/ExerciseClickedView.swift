//
//  ExerciseClickedView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-03.
//

import SwiftUI

struct ExerciseClickedView: View {
    
    @State var exerciseName: String
    
    @Environment(AppSettings.self) private var appSettings
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            
            ScrollView {
                
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)
                
                Text("Average weight history:")
                    .font(.headline)
                    
                ExerciseHistoryGraphCard(dataPoints: (appSettings.weightHistory[exerciseName] ?? []))
                    .padding(.bottom)
                
                Text("Average volume history:")
                    .font(.headline)
                
                ExerciseHistoryGraphCard(dataPoints: (appSettings.volumeHistory[exerciseName] ?? []))
                    .padding(.bottom)
                
                LeaderBoardCard(exerciseName: exerciseName, initialNumRows: 5, cardMode: Bindable(appSettings).exerciseLeaderBoardMode)
            }
        }
        .overlay {
            VStack {
                ZStack {
                    Text("\(exerciseName)")
                        .headerStyle()
                    
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding(5)
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ExerciseClickedView(exerciseName: "Barbell bench press")
        .environment(AuthManager())
        .environment(AppSettings())
}
