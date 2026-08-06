//
//  FollowingFunctions.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import Foundation
import Supabase

struct FollowInsert: Encodable {
    let follower_id: UUID
    let following_id: UUID
}

func followUser(_ userIdToFollow: UUID) async throws {
    guard let currentUserId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    let record = FollowInsert(follower_id: currentUserId, following_id: userIdToFollow)

    try await supabase
        .from("follows")
        .insert(record)
        .execute()
}

func unfollowUser(_ userIdToUnfollow: UUID) async throws {
    guard let currentUserId = supabase.auth.currentSession?.user.id else {
        throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
    }

    try await supabase
        .from("follows")
        .delete()
        .eq("follower_id", value: currentUserId)
        .eq("following_id", value: userIdToUnfollow)
        .execute()
}
