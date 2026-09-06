//
//  LeaderBoardCardHome.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-03.
//


import SwiftUI
import Foundation

struct LeaderBoardCardHome: View {
    @State private var errorMessage: String = ""
    
    let initialNumRows: Int// the number of rows initially loaded and increased every time the user clicks "load x more"
    
    @Environment(AppSettings.self) private var appSettings
    @Environment(AuthManager.self) private var authManager
    
    @State private var loadingTop: Int = 0// how many people are being loaded to the leaderboard
    
    @State private var leaderBoard: [leaderBoardRow] = []
    
    @State private var loading: Bool = true
    
    @State private var profileToView: ProfileTarget?

    @State private var IdsUserIsFollowing: [UUID] = []
    
    var body: some View {
        VStack(spacing: 20) {
            HStack{
                TextField("Enter exercise name", text: Bindable(appSettings).homeLeaderBoardExerciseName)
                    .font(.headline)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            
                            loading = true
                            leaderBoard = []
                            loadingTop = initialNumRows
                            
                            if appSettings.homeLeaderBoardMode == "global" {
                                await loadMore()
                                
                                loading = false
                            } else {
                                if let userId = authManager.currentUserId {
                                    Task {
                                        do {
                                            IdsUserIsFollowing = try await theUserIdsXisFollowing(userId)
                                            IdsUserIsFollowing.append(userId)
                                            
                                            await loadMore()
                                            
                                            loading = false
                                        } catch {
                                            print("Error pulling following: \(error)")
                                            errorMessage = "Error pulling following"
                                            loading = false
                                        }
                                    }
                                } else {
                                    print("Error: Not signed in")
                                    errorMessage = "Error: Not signed in"
                                    loading = false
                                }
                            }
                        }
                    }

                Spacer()
                
                if appSettings.homeLeaderBoardMode == "global" {
                    Button {
                        appSettings.homeLeaderBoardMode = "following"
                        
                        leaderBoard = []
                        loading = true
                        loadingTop = initialNumRows
                        
                        if let userId = authManager.currentUserId {
                            Task {
                                do {
                                    IdsUserIsFollowing = try await theUserIdsXisFollowing(userId)
                                    IdsUserIsFollowing.append(userId)
                                    
                                    await loadMore()
                                    
                                    loading = false
                                } catch {
                                    print("Error pulling following: \(error)")
                                    errorMessage = "Error pulling following"
                                    loading = false
                                }
                            }
                        } else {
                            print("Error: Not signed in")
                            errorMessage = "Error: Not signed in"
                            loading = false
                        }
                        
                    } label : {
                        Text("Global")
                    }
                    .buttonStyle(.glass)
                    .disabled(loading)
                } else {
                    Button {
                        appSettings.homeLeaderBoardMode = "global"
                        
                        leaderBoard = []
                        loading = true
                        loadingTop = initialNumRows
                        
                        Task {
                            await loadMore()
                            loading = false
                        }
                        
                    } label : {
                        Text("Following")
                    }
                    .buttonStyle(.glass)
                    .disabled(loading)
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
                            profileToView = ProfileTarget(id: row.userId)
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
            
            if appSettings.homeLeaderBoardMode == "global" {
                await loadMore()
                
                loading = false
            } else {
                if let userId = authManager.currentUserId {
                    Task {
                        do {
                            IdsUserIsFollowing = try await theUserIdsXisFollowing(userId)
                            IdsUserIsFollowing.append(userId)
                            
                            await loadMore()
                            
                            loading = false
                        } catch {
                            print("Error pulling following: \(error)")
                            errorMessage = "Error pulling following"
                            loading = false
                        }
                    }
                } else {
                    print("Error: Not signed in")
                    errorMessage = "Error: Not signed in"
                    loading = false
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(item: $profileToView) { target in
            ProfileView(givenId: target.id)
        }
        .overlay {
            TopPopUp(message: $errorMessage)
                .padding(.top)
        }
    }
        
    
    private func loadMore() async {
        var leaderBoardTemp: [leaderBoardRow] = []
        
        if appSettings.homeLeaderBoardMode == "global" {
            do {
                leaderBoardTemp = try await pullGlobalTop(exerciseName: appSettings.homeLeaderBoardExerciseName, startLoad: loadingTop-initialNumRows, endLoad: loadingTop-1)
            } catch {
                leaderBoardTemp = []
                print("Error loading more onto the leaderboard \(error)")
                errorMessage = "Error loading more onto the leaderboard \(error)"
            }
        } else {
            do {
                leaderBoardTemp = try await pullFollowingTop(exerciseName: appSettings.homeLeaderBoardExerciseName, startLoad: loadingTop-initialNumRows, endLoad: loadingTop-1, following: IdsUserIsFollowing)
            } catch {
                leaderBoardTemp = []
                print("Error loading more onto the following leaderboard \(error)")
                errorMessage = "Error loading more onto the following leaderboard \(error)"
            }
            
        }
        
        for newRow in leaderBoardTemp {
            leaderBoard.append(newRow)
        }

    }
}

#Preview {
    LeaderBoardCardHome(initialNumRows: 5)
        .environment(AppSettings())
        .environment(AuthManager())
}
