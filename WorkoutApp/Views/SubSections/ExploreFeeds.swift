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
    
    var body: some View {
        VStack {
            TopPopUp(message: $errorMessage)

            LazyVStack {
                ForEach(feed) { HistoryItem in
                    ExploreFeedCard(
                        historyId: HistoryItem.id,
                        userName: usernames[HistoryItem.user_id] ?? "",
                        userID: HistoryItem.user_id,
                        dateCompleted: HistoryItem.updated_at,
                        durationSeconds: HistoryItem.duration_seconds,
                        routine: exercisesToRoutine(HistoryItem.exercises.map { $0.toModel() }, name: HistoryItem.name)
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
        .frame(maxWidth: .infinity)
        .task {
            followingIds = (try? await pullFollowingIds(userId)) ?? []
            loadMore()
        }
    }

    // a window of loading. It loads the first 10, then when the user scrolls to the end of the ten it loads from 10-20 and repeat
    func loadMore() {
        guard !isLoadingMore, !reachedEnd else { return }
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
            } catch {
                errorMessage = "Failed to load feed: \(error)"
                print("Failed to load feed: \(error)")
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
    
    var body: some View {
        VStack {
            TopPopUp(message: $errorMessage)

            LazyVStack {
                ForEach(feed) { HistoryItem in
                    ExploreFeedCard(
                        historyId: HistoryItem.id,
                        userName: usernames[HistoryItem.user_id] ?? "",
                        userID: HistoryItem.user_id,
                        dateCompleted: HistoryItem.updated_at,
                        durationSeconds: HistoryItem.duration_seconds,
                        routine: exercisesToRoutine(HistoryItem.exercises.map { $0.toModel() }, name: HistoryItem.name)
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
        .frame(maxWidth: .infinity)
        .task {
            loadMore()
        }
    }

    // a window of loading. It loads the first 10, then when the user scrolls to the end of the ten it loads from 10-20 and repeat
    func loadMore() {
        guard !isLoadingMore, !reachedEnd else { return }
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
            } catch {
                errorMessage = "Failed to load feed: \(error)"
                print("Failed to load feed: \(error)")
            }
        }
    }
}

// This struct is in pulling functions
//struct HistoryRow: Decodable, Identifiable {
//    let id: UUID
//    let routine_id: UUID
//    let user_id: UUID
//    let name: String
//    let exercises: [ExerciseDTO]
//    let updated_at: Date
//    let duration_seconds: Int
//}
