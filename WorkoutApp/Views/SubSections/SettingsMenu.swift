//
//  SettingsMenu.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-30.
//

import SwiftUI

struct SettingsMenu: View {
    
    @Environment(AuthManager.self) private var authManager
    
    @State private var newUsername = ""
    @State private var errorMessage: String = ""
    @State private var showChangeUsername: Bool = false
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack {
                
                HStack {
                    Text(authManager.currentUsername ?? "Guest")
                        .font(.headline)
                    
                    Spacer()
                    Text("Followers: ")
                        .font(.subheadline)
                    Text("\(followerCount)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Following: ")
                        .font(.subheadline)
                    Text("\(followingCount)")
                        .font(.headline)
                    
                }
                .padding()
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                
                HStack {
                    Button {
                        Task {
                            do {
                                try await authManager.signOut()
                                
                            } catch {
                                errorMessage = "Sign out failed: \(error)"
                            }
                        }
                    } label : {
                        Text("Sign out")
                            .frame(maxWidth:. infinity)
                    }
                    .buttonStyle(.liquidGlass(tintColor: Color.red))
                    .frame(maxWidth:. infinity)
                    
                    Button {
                        showChangeUsername = true
                    } label : {
                        Text("Change username")
                            .frame(maxWidth:. infinity)
                    }
                    .buttonStyle(.liquidGlass(tintColor: Theme.primary))
                    .frame(maxWidth:. infinity)
                }
                .frame(maxWidth:. infinity)
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert("Enter new username", isPresented: $showChangeUsername) {
                TextField("Exercise Name", text: $newUsername)
                
                Button("Update username") {
                    
                    Task { await save() }
                    
                }
                
                Button("Cancel", role: .cancel) {
                    newUsername = ""
                }
            }
            .task {
                await loadCounts()
            }
            
            VStack {
                TopPopUp(message: $errorMessage)
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.liquidGlass(tintColor: Theme.primary))
                .padding(.horizontal)
                
            }
        }
        
    }
    
    private func loadCounts() async {
        guard let userId = authManager.currentUserId else { return }

        do {
            followerCount = try await pullFollowerCount(userId)
            followingCount = try await pullFollowingCount(userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func save() async {
        do {
            try await authManager.updateUsername(newUsername)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


#Preview {
    SettingsMenu()
        .environment(AuthManager())
}
