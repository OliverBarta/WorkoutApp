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

func pullProfilesFromSupabase() async throws -> [ProfileRow] {
    guard let currentUserId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    var profiles: [ProfileRow] = try await supabase
        .from("profiles")
        .select("id, username")
        .execute()
        .value

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

struct WorkoutActivityRow: Decodable, Identifiable {
    let id: UUID
    let name: String
    let duration_seconds: Int
    let completed_sets: Int
    let total_sets: Int
    let created_at: Date
}

func pullFullRoutines(_ userId: UUID) async throws -> [Routine] {
    let dtos: [RoutineDTO] = try await supabase
        .from("routines")
        .select()
        .eq("user_id", value: userId)
        .execute()
        .value

    return dtos.map { $0.toModel() }
}

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
        throw NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No profile found for this user"])
    }

    return username
}
