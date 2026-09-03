//
//  GlobalLeaderBoard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-03.
//

import SwiftUI
import Foundation

struct LeaderBoardCard: View {
    
    let exerciseName: String// name of the exercise
    
    let initialNumRows: Int// the number of rows initially loaded and increased every time the user clicks "load x more"
    
    @Environment(AppSettings.self) private var appSettings
    @Environment(AuthManager.self) private var authManager
    
    @State private var loadingTop: Int = 0// how many people are being loaded to the leaderboard
    
    @State private var leaderBoard: [leaderBoardRow] = []
    
    @State private var loading: Bool = true
    
    @State private var showProfileView: Bool = false
    
    @State private var profileIdToView: UUID = UUID()
    
    @State private var cardMode: String = "global"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack{
                Text(exerciseName)
                    .font(.headline)
                
                Spacer()
                
                if cardMode == "global" {
                    Button {
                        cardMode = "following"
                    } label : {
                        Text("Global")
                    }
                    .buttonStyle(.glass)
                } else {
                    Button {
                        cardMode = "global"
                    } label : {
                        Text("Following")
                    }
                    .buttonStyle(.glass)
                }
            }
            
            if leaderBoard.isEmpty {
                if loading {
                    ProgressView()
                } else {
                    Text("Empty leaderboard")
                }
            } else {
                ForEach(Array(leaderBoard.prefix(loadingTop).enumerated()), id:\.element.id) { index, row in
                    HStack {
                        Text("\(index+1).")
                            .foregroundStyle(index == 0 ? Theme.gold : .secondary)
                        Button(row.username) {
                            profileIdToView = row.userId
                            showProfileView = true
                        }
                        Spacer()
                        Text("\(formattedWeight(row.weight, unit: appSettings.weightUnit)) \(appSettings.weightUnit.label)")
                    }
                }
            }
            
            if leaderBoard.count == loadingTop {
                Button {
                    loadingTop += initialNumRows
                    
                    Task {
                        await loadMore()
                    }
                } label : {
                    Text("Load \(initialNumRows) more")
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            loadingTop = initialNumRows
            
            do {
                leaderBoard = try await pullGlobalTop(exerciseName: exerciseName, startLoad: 0, endLoad: loadingTop-1)
                
                loading = false
            } catch {
                leaderBoard = []
                print("Error loading leaderboard \(error)")
                
                loading = false
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $showProfileView) {
            ProfileView(givenId: profileIdToView)
        }
    }
        
    
    private func loadMore() async {
        var leaderBoardTemp: [leaderBoardRow] = []
        do {
            leaderBoardTemp = try await pullGlobalTop(exerciseName: exerciseName, startLoad: loadingTop-initialNumRows, endLoad: loadingTop-1)
        } catch {
            leaderBoardTemp = []
            print("Error loading more onto the leaderboard \(error)")
        }
        
        for newRow in leaderBoardTemp {
            leaderBoard.append(newRow)
        }

    }
}

#Preview {
    LeaderBoardCard(exerciseName: "Barbell bench press", initialNumRows: 5)
        .environment(AppSettings())
        .environment(AuthManager())
}
