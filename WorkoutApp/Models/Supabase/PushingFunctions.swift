//
//  PushingFunctions.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-28.
//

import Foundation
import Supabase

struct commentToUpload: Encodable {
    var user_id: UUID
    var username: String
    var history_item_id: UUID
    var content: String
}

func postComment(userId: UUID, username: String, historyId: UUID, content: String) async throws {
    guard !content.isEmpty else { return }// catches empty comments
    guard content.count <= 200 else { return }// catches large comments
    
    let comment = commentToUpload (
        user_id: userId,
        username: username,
        history_item_id: historyId,
        content: content
    )
    
    try await supabase
        .from("comments")
        .insert(comment)
        .execute()
}
