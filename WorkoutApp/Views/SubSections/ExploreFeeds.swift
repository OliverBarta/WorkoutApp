//
//  ExploreFeeds.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-22.
//

import SwiftUI

// the feed of workouts done by the user and the people the user follows
struct FeedElementFollowing: View {
    
    // the id of the user operating the phone
    let userId: UUID
    
    @State private var errorMessage: String = ""
    
    @State private var feed: [HistoryRow] = []
    @State private var followingIds: [UUID] = []// the ids the user operating the phone is following
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    // a hashmap where the key is ID and the val is username
    @State private var usernames: [UUID: String] = [:]
    @State private var durationSeconds: [UUID: Int] = [:]
    
    @State private var loading: Bool = false
    
    var body: some View {
        VStack {
            TopPopUp(message: $errorMessage)
            if feed.isEmpty {
                if loading {
                    ProgressView()
                } else {
                    Text("No posts")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                }
            } else {
                LazyVStack {
                    ForEach(feed) { HistoryItem in
                        ExploreFeedCard(
                            historyId: HistoryItem.id,
                            userName: usernames[HistoryItem.user_id] ?? "",
                            userID: HistoryItem.user_id,
                            dateCompleted: HistoryItem.updated_at,
                            durationSeconds: HistoryItem.duration_seconds,
                            routineHistory: exercisesToRoutineHistory(HistoryItem.exercises, name: HistoryItem.name)
                        )
                        .onAppear {
                            if HistoryItem.id == feed.last?.id {
                                loadMore()
                            }
                        }
                    }
                    if isLoadingMore {
                        ProgressView()
                    }
                }
            }

        }
        .frame(maxWidth: .infinity)
        .task {
            loading = true
            
            followingIds = (try? await theUserIdsXisFollowing(userId)) ?? []
            loadMore()
        }
    }

    // a window of loading. It loads the first 10, then when the user scrolls to the end of the ten it loads from 10-20 and repeat
    func loadMore() {
        guard !isLoadingMore, !reachedEnd else {
            loading = false
            return
        }
        isLoadingMore = true
        Task {
            defer { isLoadingMore = false }
            do {
                let cursor = feed.last?.updated_at
                let next = try await pullFeed(userId: userId, followingIds: followingIds, before: cursor)
                if next.count < 10 { reachedEnd = true }
                
                // adds the up to ten new users every time this function is called to the usernames hashmap
                for entry in next where usernames[entry.user_id] == nil {
                     usernames[entry.user_id] = (try? await pullUsername(entry.user_id)) ?? "Unknown"
                }
                
                feed.append(contentsOf: next)
                loading = false
            } catch {
                errorMessage = "Failed to load feed: \(error)"
                print("Failed to load feed: \(error)")
                loading = false
            }
        }
    }
}



// the feed of workouts done by the user and the people the user follows
struct FeedElementGlobal: View {
    
    let userId: UUID
    
    @State private var errorMessage: String = ""
    
    @State private var feed: [HistoryRow] = []
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    // a hashmap where the key is ID and the val is username
    @State private var usernames: [UUID: String] = [:]
    @State private var durationSeconds: [UUID: Int] = [:]
    
    @State private var loading: Bool = false
    
    var body: some View {
        VStack {
            TopPopUp(message: $errorMessage)

            if feed.isEmpty {
                if loading {
                    ProgressView()
                } else {
                    Text("No posts")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                }
            } else {
                LazyVStack {
                    ForEach(feed) { HistoryItem in
                        ExploreFeedCard(
                            historyId: HistoryItem.id,
                            userName: usernames[HistoryItem.user_id] ?? "",
                            userID: HistoryItem.user_id,
                            dateCompleted: HistoryItem.updated_at,
                            durationSeconds: HistoryItem.duration_seconds,
                            routineHistory: exercisesToRoutineHistory(HistoryItem.exercises, name: HistoryItem.name)
                        )
                        .onAppear {
                            if HistoryItem.id == feed.last?.id {
                                loadMore()
                            }
                        }
                    }
                    if isLoadingMore {
                        ProgressView()
                    }
                }
            }

        }
        .frame(maxWidth: .infinity)
        .task {
            loading = true
            
            loadMore()
        }
    }

    // a window of loading. It loads the first 10, then when the user scrolls to the end of the ten it loads from 10-20 and repeat
    func loadMore() {
        guard !isLoadingMore, !reachedEnd else {
            loading = false
            return
        }
        isLoadingMore = true
        Task {
            defer { isLoadingMore = false }
            do {
                let cursor = feed.last?.updated_at
                let next = try await pullFeedGlobal(userId: userId, before: cursor)
                if next.count < 10 { reachedEnd = true }

                // adds the up to ten new users every time this function is called to the usernames hashmap
                for item in next where usernames[item.user_id] == nil {
                     usernames[item.user_id] = (try? await pullUsername(item.user_id)) ?? "Unknown"
                }

                feed.append(contentsOf: next)
                loading = false
            } catch {
                errorMessage = "Failed to load feed: \(error)"
                print("Failed to load feed: \(error)")
                loading = false
            }
        }
    }
}

//struct HistoryRow: Decodable, Identifiable {
//    let id: UUID
//    let routine_id: UUID?// made this ? because when a user deletes a routine all history of that routine now has routine_id = NULL
//    let user_id: UUID
//    let name: String
//    let exercises: [ExerciseHistoryDTO]
//    let updated_at: Date
//    let duration_seconds: Int
//}
