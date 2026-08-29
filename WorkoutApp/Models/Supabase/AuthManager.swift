//
//  AuthManager.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//
//

import Foundation
import Supabase
import Observation
import SwiftData

@Observable
class AuthManager {
    var currentUser: Supabase.User?
    var currentUsername: String?
    var currentUserId: UUID?
    var currentStreak: Int = 0
    var isLoading = true

    init() {
        Task {
            await loadSession()
        }
    }

    var isSignedIn: Bool {
        currentUser != nil && currentUsername != nil
    }

    func loadSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            await fetchUsername()
            await fetchStreak()
        } catch {
            currentUser = nil
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)

        struct StreakInsert: Encodable {
            let user_id: UUID
            let streak: Int
        }

        try await supabase
            .from("streaks")
            .insert(StreakInsert(user_id: response.user.id, streak: 0))
            .execute()

        guard let session = response.session else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account created — check your email to confirm, then sign in."])
        }

        currentUser = session.user
        currentStreak = 0
        await fetchUsername()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
        await fetchUsername()
        await fetchStreak()
    }

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Remote sign out failed, clearing local session anyway: \(error)")
        }
        currentUser = nil
        currentUsername = nil
        currentStreak = 0
    }

    func fetchUsername() async {
        guard let userId = currentUser?.id else { return }

        currentUserId = userId
        
        struct ProfileRow: Decodable {
            let username: String
        }

        do {
            let profile: ProfileRow = try await supabase
                .from("profiles")
                .select("username")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            currentUsername = profile.username
        } catch {
            print("Failed to fetch username: \(error)")
        }
    }

    func updateUsername(_ newUsername: String) async throws {
        guard let userId = currentUser?.id else { return }

        struct UsernameUpdate: Encodable {
            let username: String
        }

        try await supabase
            .from("profiles")
            .update(UsernameUpdate(username: newUsername))
            .eq("id", value: userId)
            .execute()

        currentUsername = newUsername
    }

    func fetchStreak() async {
        guard let userId = currentUser?.id else { return }

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
            currentStreak = row.streak
        } catch {
            print("Failed to fetch streak: \(error)")
        }
    }

    // Weekly streak: no change if a workout was already logged this week, +1 if last week had one,
    // otherwise resets to 1 (this workout starts a new streak rather than zeroing it out).
    func updateStreakAfterWorkout(history: [WorkoutHistoryEntry]) async throws {
        guard let userId = currentUser?.id else { return }

        let calendar = Calendar.current
        let now = Date()

        func isInWeek(_ date: Date, offset: Int) -> Bool {
            guard let target = calendar.date(byAdding: .weekOfYear, value: offset, to: now) else { return false }
            return calendar.isDate(date, equalTo: target, toGranularity: .weekOfYear)
        }

        let workedOutThisWeek = history.contains { isInWeek($0.dateCompleted, offset: 0) }
        if workedOutThisWeek { return }

        let workedOutLastWeek = history.contains { isInWeek($0.dateCompleted, offset: -1) }
        let newStreak = workedOutLastWeek ? currentStreak + 1 : 1

        struct StreakUpdate: Encodable {
            let streak: Int
        }

        try await supabase
            .from("streaks")
            .update(StreakUpdate(streak: newStreak))
            .eq("user_id", value: userId)
            .execute()

        currentStreak = newStreak
    }
}
