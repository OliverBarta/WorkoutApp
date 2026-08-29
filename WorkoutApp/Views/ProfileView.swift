//
//  ProfileView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import SwiftUI
import Foundation

// the view where you see other peoples profile
struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(AuthManager.self) private var authManager
    
    let givenId: UUID
    
    @State private var routines: [Routine] = []
    @State private var username = ""
    @State private var errorMessage: String = ""
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    @State private var isFollowing: Bool = false
    
    @State private var streakNumber: Int = 0
    
    @State private var workoutHistory: [HistoryRow] = []
    
    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    Button {

                    } label : {
                        HStack(spacing: 0) {
                            Text("Followers: ")
                                .font(.subheadline)
                            Text("\(followerCount)")
                                .font(.headline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.clear.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)

                    Button {

                    } label: {
                        HStack(spacing: 0) {
                            Text("Following: ")
                                .font(.subheadline)
                            Text("\(followingCount)")
                                .font(.headline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.clear.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)

                    Button {

                    } label: {
                        HStack(spacing: 4) {
                            Text("\(streakNumber)")

                            Image(systemName: "flame")
                        }
                        .foregroundColor(Theme.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.clear.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)

                    Button {

                    } label: {
                        Image(systemName: "medal")
                            .foregroundColor(Color.cyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.clear.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)

            if !routines.isEmpty {
                Text("Routines: ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .font(.subheadline)
                    
                ForEach(routines) { routine in
                        ExploreRoutineCard(routine: routine)
                }
            } else {
                Text("No routines")
            }
        }
        .task {
            await loadCounts()

            await loadRoutines()

            await loadUsername()

            await loadIsFollowing()
            
            do {
                streakNumber = try await pullStreak(userId: givenId)
                
            } catch {
                errorMessage = "Failed to load streak: \(error)"
                print("Error pulling streak \(error)")
            }
            
        }
        .overlay {
            VStack {
                ZStack {
                    if username != "" {
                        Text(username)
                            .headerStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Loading...")
                            .headerStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
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
                        
                        // the if statement so you can't follow yourself
                        if givenId != authManager.currentUserId {
                            Button {
                                Task {
                                    do {
                                        if isFollowing {
                                            try await unfollowUser(givenId)
                                        } else {
                                            try await followUser(givenId)
                                        }
                                        isFollowing.toggle()
                                    } catch {
                                        errorMessage = "Follow/unfollow failed: \(error)"
                                        print("Follow/unfollow failed: \(error)")
                                    }
                                }
                            } label : {
                                Text(isFollowing ? "Following" : "Follow")
                                    .padding(5)
                            }
                            .buttonStyle(.glass)
                            .foregroundColor(Theme.oppositeBackground)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                    }
                    .padding(.horizontal)
                    
                }
                TopPopUp(message: $errorMessage)
                
                Spacer()
            }
        }
    }
    
    private func loadRoutines() async {
        do {
            routines = try await pullFullRoutines(givenId)
        } catch {
            errorMessage = error.localizedDescription
            print(error.localizedDescription)
        }
    }
    
    private func loadUsername() async {
        do {
            username = try await pullUsername(givenId)
        } catch {
            errorMessage = error.localizedDescription
            print(error.localizedDescription)
        }
    }
    
    private func loadCounts() async {
        do {
            followerCount = try await pullFollowerCount(givenId)
            followingCount = try await pullFollowingCount(givenId)
        } catch {
            errorMessage = error.localizedDescription
            print(error.localizedDescription)
        }
    }

    private func loadIsFollowing() async {
        guard let currentUserId = authManager.currentUserId else { return }
        do {
            isFollowing = try await pullIsFollowing(followerId: currentUserId, followingId: givenId)
        } catch {
            errorMessage = error.localizedDescription
            print(error.localizedDescription)
        }
    }

}

#Preview {
    ProfileView(givenId: UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")!)
        .environment(AuthManager())
}
