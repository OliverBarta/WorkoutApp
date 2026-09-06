//
//  leaderBoards.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-09-03.
//

import Supabase
import Foundation

// used in leaderboards.
struct leaderBoardRow: Identifiable {
    var id: UUID { userId }
    var userId: UUID
    var username: String
    var weight: Double
}

// gets a list of leaderboard rows for a given exercise from startLoad to endLoad. So if it was 4-6 it would return the 4th, 5th, and 6th highest weights (if they exist) in their respective leaderBoardRows
func pullGlobalTop(exerciseName: String, startLoad: Int, endLoad: Int) async throws -> [leaderBoardRow] {
    
    struct PersonalBestDTO: Decodable {
        let user_id: UUID
        let exercise: String
        let weight: Double
    }

    let response: [PersonalBestDTO] = try await supabase
        .from("personalbest")
        .select("user_id, exercise, weight")
        .eq("exercise", value: exerciseName)
        .order("weight", ascending: false)
        .range(from: startLoad, to: endLoad)
        .execute()
        .value
    
    var finalOutput: [leaderBoardRow] = []
    
    for item in response {
        var newUsername = ""
        
        do {
            newUsername = try await pullUsername(item.user_id)
        } catch {
            newUsername = "Unknown"
        }
        
        let newRow = leaderBoardRow (
            userId: item.user_id,
            username: newUsername,
            weight: item.weight
        )
        finalOutput.append(newRow)
    }
    
    return finalOutput
}

// pulls the personalbests from startLoad-endLoad for a given exercise name for only the users in "following"
func pullFollowingTop(exerciseName: String, startLoad: Int, endLoad: Int, following: [UUID]) async throws -> [leaderBoardRow] {
    
    struct PersonalBestDTO: Decodable {
        let user_id: UUID
        let exercise: String
        let weight: Double
    }
    
    let response: [PersonalBestDTO] = try await supabase
        .from("personalbest")
        .select("user_id, exercise, weight")
        .eq("exercise", value: exerciseName)
        .order("weight", ascending: false)
        .range(from: startLoad, to: endLoad)
        .execute()
        .value
    
    var finalOutput: [leaderBoardRow] = []
    
    for item in response {
        if following.contains(item.user_id) {
            var newUsername = ""
            
            do {
                newUsername = try await pullUsername(item.user_id)
            } catch {
                newUsername = "Unknown"
            }
            
            let newRow = leaderBoardRow (
                userId: item.user_id,
                username: newUsername,
                weight: item.weight
            )
            finalOutput.append(newRow)
        }
    }
    
    return finalOutput
}
