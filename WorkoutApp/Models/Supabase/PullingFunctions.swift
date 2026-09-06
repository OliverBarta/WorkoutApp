//
//  PullProfilesFromSupabase.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import Supabase
import Foundation

struct ProfileRow: Decodable, Identifiable {
    let id: UUID
    let username: String
    var isFollowing: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, username
        // isFollowing is intentionally excluded — it's not part of the Supabase response
    }
}

// pulls all profiles rom supabase whose username mathes the searchText
func pullProfilesFromSupabase(searchText: String) async throws -> [ProfileRow] {
    let currentUserId: UUID
    if let sessionUserId = supabase.auth.currentSession?.user.id {
        currentUserId = sessionUserId
    } else if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {// this middle else if is just so you can see the explore view search in preview mode
        currentUserId = UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")!
    } else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    var query = supabase
        .from("profiles")
        .select("id, username")

    if !searchText.isEmpty {
        query = query.ilike("username", pattern: "%\(searchText)%")
    }

    var profiles: [ProfileRow] = try await query.execute().value

    struct FollowingRow: Decodable {
        let following_id: UUID
    }

    let followingRows: [FollowingRow] = try await supabase
        .from("follows")
        .select("following_id")
        .eq("follower_id", value: currentUserId)
        .execute()
        .value

    let followingIds = Set(followingRows.map { $0.following_id })

    for index in profiles.indices {
        profiles[index].isFollowing = followingIds.contains(profiles[index].id)
    }

    return profiles
}

// gets the follower count of userId
func pullFollowerCount(_ userId: UUID) async throws -> Int {
    let response = try await supabase
        .from("follows")
        .select("*", head: true, count: .exact)
        .eq("following_id", value: userId)
        .execute()

    return response.count ?? 0
}

// gets the following count of userId
func pullFollowingCount(_ userId: UUID) async throws -> Int {
    let response = try await supabase
        .from("follows")
        .select("*", head: true, count: .exact)
        .eq("follower_id", value: userId)
        .execute()

    return response.count ?? 0
}

// checks whether followerId currently follows followingId
func pullIsFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
    let response = try await supabase
        .from("follows")
        .select("*", head: true, count: .exact)
        .eq("follower_id", value: followerId)
        .eq("following_id", value: followingId)
        .execute()

    return (response.count ?? 0) > 0
}

// pulls all the routines for a user
func pullFullRoutines(_ userId: UUID) async throws -> [Routine] {
    let dtos: [RoutineDTO] = try await supabase
        .from("routines")
        .select()
        .eq("user_id", value: userId)
        .execute()
        .value

    return dtos.map { $0.toModel() }
}

// gets the username for a given id
func pullUsername(_ userId: UUID) async throws -> String {
    struct UsernameRow: Decodable {
        let username: String
    }

    let rows: [UsernameRow] = try await supabase
        .from("profiles")
        .select("username")
        .eq("id", value: userId)
        .execute()
        .value

    guard let username = rows.first?.username else {
        throw NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No profile found for this user, username \(rows)"])
    }

    return username
}

// returns all the ids the given userId is following
func theUserIdsXisFollowing(_ userId: UUID) async throws -> [UUID] {
    struct FollowingRow: Decodable { let following_id: UUID }
    let rows: [FollowingRow] = try await supabase
        .from("follows")
        .select("following_id")
        .eq("follower_id", value: userId)
        .execute()
        .value
    return rows.map { $0.following_id }
}

// returns all the ids following the given userId
func theUserIdsXisBeingFollowedBy(_ userId: UUID) async throws -> [UUID] {
    struct FollowerRow: Decodable { let follower_id: UUID }
    let rows: [FollowerRow] = try await supabase
        .from("follows")
        .select("follower_id")
        .eq("following_id", value: userId)
        .execute()
        .value
    return rows.map { $0.follower_id }
}

struct HistoryRow: Decodable, Identifiable {
    let id: UUID
    let routine_id: UUID?// made this ? because when a user deletes a routine all history of that routine now has routine_id = NULL
    let user_id: UUID
    let name: String
    let exercises: [ExerciseHistoryDTO]
    let updated_at: Date
    let duration_seconds: Int
}

// pulls all the history for the users that are in the followingIds and userId. Limits it to limit.
func pullFeed(userId: UUID, followingIds: [UUID], before: Date? = nil, limit: Int = 10) async throws -> [HistoryRow] {
    let query = supabase
        .from("history")
        .select()
        .in("user_id", values: followingIds + [userId])

    let filteredQuery: PostgrestFilterBuilder
    if let before {
        filteredQuery = query.lt("updated_at", value: before)
    } else {
        filteredQuery = query
    }

    return try await filteredQuery
        .order("updated_at", ascending: false)
        .limit(limit)
        .execute()
        .value
}

func pullFeedGlobal(userId: UUID, before: Date? = nil, limit: Int = 10) async throws -> [HistoryRow] {
    let query = supabase
        .from("history")
        .select()

    let filteredQuery: PostgrestFilterBuilder
    if let before {
        filteredQuery = query.lt("updated_at", value: before)
    } else {
        filteredQuery = query
    }

    return try await filteredQuery
        .order("updated_at", ascending: false)
        .limit(limit)
        .execute()
        .value
}

func pullLikes(historyId: UUID) async throws -> Int {
    let numLikes = try await supabase
        .from("likes")
        .select(head: true, count: .exact)
        .eq("history_item_id", value: historyId)
        .execute()
    
    return numLikes.count ?? 0
}

func isUserLikingPost(historyId: UUID, userId: UUID) async throws -> Bool {
    let response = try await supabase
        .from("likes")
        .select(head: true, count: .exact)
        .eq("history_item_id", value: historyId)
        .eq("user_id", value: userId)
        .execute()
    
    return (response.count ?? 0) > 0
}

// pulls every personal best a user has, keyed by exercise name, so the device can seed itself
// from the server instead of starting from nothing on each launch
func pullPersonalBests(userId: UUID) async throws -> [String: Double] {
    struct PersonalBestRow: Decodable {
        let exercise: String
        let weight: Double
    }

    let rows: [PersonalBestRow] = try await supabase
        .from("personalbest")
        .select("exercise, weight")
        .eq("user_id", value: userId)
        .execute()
        .value

    // uniquingKeysWith guards against duplicate rows for one exercise, which the unique
    // constraint should already prevent
    return Dictionary(rows.map { ($0.exercise, $0.weight) }, uniquingKeysWith: max)
}

// pulls a given users streak number
func pullStreak(userId: UUID) async throws -> Int {
    struct StreakRow: Decodable {
        let streak: Int
    }
    
    do {
        let row: StreakRow = try await supabase
            .from("streaks")
            .select("streak")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return row.streak
    } catch {
        return 0
    }
}

struct comment: Decodable, Identifiable {
    let id: UUID
    let username: String
    let content: String
}
// pulls all comments for a given post
func pullComments(historyId: UUID) async throws -> [comment] {
    try await supabase
        .from("comments")
        .select("id, username, content")
        .eq("history_item_id", value: historyId)
        .execute()
        .value
}


