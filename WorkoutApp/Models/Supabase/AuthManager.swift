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

@Observable
class AuthManager {
    var currentUser: Supabase.User?
    var currentUsername: String?
    var isLoading = true

    init() {
        Task {
            await loadSession()
        }
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    func loadSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            await fetchUsername()
        } catch {
            currentUser = nil
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)
        currentUser = response.user
        await fetchUsername()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
        await fetchUsername()
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        currentUsername = nil
    }

    func fetchUsername() async {
        guard let userId = currentUser?.id else { return }

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
}
