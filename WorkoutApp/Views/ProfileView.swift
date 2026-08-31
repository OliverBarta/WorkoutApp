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
    
    let givenId: UUID// id of profile being view
    
    @State private var routines: [Routine] = []
    @State private var username = ""
    @State private var errorMessage: String = ""
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    @State private var isFollowing: Bool = false
    
    @State private var streakNumber: Int = 0
    
    
    @State private var workoutHistory: [HistoryRow] = []
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    
    @State private var followingViewBeingShown = false
    @State private var followerViewBeingShown = false

    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    Button {
                        followerViewBeingShown = true
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
                        followingViewBeingShown = true
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

            Text("Routines: ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .font(.headline)
            
            if !routines.isEmpty {
                ForEach(routines) { routine in
                        ExploreRoutineCard(routine: routine)
                }
            } else {
                Text("\(username) has no routines")
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
            }
            
            
            Text("History: ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .font(.headline)
            
            LazyVStack {// loades 10 then loades 10 more when you get to the bottom
                ForEach(workoutHistory) { HistoryItem in
                    ExploreFeedCard(
                        historyId: HistoryItem.id,
                        userName: username,
                        userID: givenId,
                        dateCompleted: HistoryItem.updated_at,
                        durationSeconds: HistoryItem.duration_seconds,
                        routine: exercisesToRoutine(HistoryItem.exercises.map { $0.toModel() }, name: HistoryItem.name)
                    )
                        .onAppear {
                            if HistoryItem.id == workoutHistory.last?.id {
                                loadMoreHistory()
                            }
                        }
                }
                if isLoadingMore {
                    ProgressView()
                } else if workoutHistory.isEmpty {
                    Text("\(username) has never worked out")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                }
            }

        }
        .scrollIndicators(.hidden)// hides the side scroll bar
        .task {
            await loadCounts()

            await loadRoutines()

            await loadUsername()

            await loadIsFollowing()

            loadMoreHistory()

            do {
                streakNumber = try await pullStreak(userId: givenId)
                
            } catch {
                errorMessage = "Failed to load streak: \(error)"
                print("Error pulling streak \(error)")
            }
            
        }
        .fullScreenCover(isPresented: $followingViewBeingShown) {
            FollowingView(givenId: givenId, givenUsername: username)
        }
        .fullScreenCover(isPresented: $followerViewBeingShown) {
            FollowerView(givenId: givenId, givenUsername: username)
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
    
    // a window of loading. It loads the first 10, then when the user scrolls to the end of the ten it loads from 10-20 and repeat
    private func loadMoreHistory() {
        guard !isLoadingMore, !reachedEnd else { return }
        isLoadingMore = true
        Task {
            defer { isLoadingMore = false }
            do {
                let cursor = workoutHistory.last?.updated_at
                // followingIds is empty so the feed is only this profile's own workouts
                let next = try await pullFeed(userId: givenId, followingIds: [], before: cursor)
                if next.count < 10 { reachedEnd = true }

                workoutHistory.append(contentsOf: next)
            } catch {
                errorMessage = "Failed to load history: \(error)"
                print("Failed to load history: \(error)")
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
        .environment(AppSettings())
}
