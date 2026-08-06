//
//  ProfileView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-06.
//

import SwiftUI
import Foundation

// the view where you see other peoples profile
struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(AuthManager.self) private var authManager
    
    let givenId: UUID
    
    @State private var routines: [Routine] = []
    @State private var username = ""
    @State private var errorMessage: String = ""
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            HStack {
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
            
            if !routines.isEmpty {
                ForEach(routines) { routine in
                        ExploreRoutineCard(routine: routine)
                }
            } else {
                Text("No routines")
            }
            
            
            
            if errorMessage != "" {
                Text(errorMessage)
            }
        }
        .task {
            await loadCounts()
            
            await loadRoutines()
            
            await loadUsername()
        }
        .overlay {
            VStack {
                ZStack {
                    if username != "" {
                        Text(username)
                            .headerStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("No username")
                            .headerStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .padding(5)
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(Theme.oppositeBackground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    .padding(.horizontal)
                    
                }
                Spacer()
            }
        }
    }
    
    private func loadRoutines() async {
        do {
            routines = try await pullFullRoutines(givenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUsername() async {
        do {
            username = try await pullUsername(givenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadCounts() async {
        do {
            followerCount = try await pullFollowerCount(givenId)
            followingCount = try await pullFollowingCount(givenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
}

#Preview {
    ProfileView(givenId: UUID(uuidString: "bdabd210-a6e1-4bfc-928a-349e3f34d248")!)
        .environment(AuthManager())
}
