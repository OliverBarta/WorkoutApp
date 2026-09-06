//
//  FollowerView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-30.
//


import SwiftUI
import Foundation

//struct ProfileRow: Decodable, Identifiable {
//    let id: UUID
//    let username: String
//    var isFollowing: Bool = false
//
//    private enum CodingKeys: String, CodingKey {
//        case id, username
//        // isFollowing is intentionally excluded — it's not part of the Supabase response
//    }
//}

struct FollowerView: View {
    
    let givenId: UUID
    
    let givenUsername: String
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(AuthManager.self) private var authManager
    
    @State private var usersToDisplay: [ProfileRow] = []
    
    @State private var errorMessage: String = ""
    @State private var showReload: Bool = false
    
    @State private var loading = true
    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            
            if usersToDisplay.isEmpty {
                if loading {
                    ProgressView()
                } else {
                    Text("\(givenUsername) has no followers")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                }
            } else if let userOperatingPhoneId = authManager.currentUserId {
                ForEach(usersToDisplay) { userToDisplay in
                    if userToDisplay.id != userOperatingPhoneId {
                        ProfileListRow(profile: userToDisplay)
                    }
                }
            }
            
        }
        .scrollIndicators(.hidden)// hides the side scroll bar
        .task {
            await fillUsersToDisplay()
        }
        .overlay {
            VStack {
                ZStack {
                    Text("Followers")
                        .headerStyle()
                        .frame(alignment: .center)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding(5)
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                TopPopUp(message: $errorMessage, addSpaceUnder: false)

                Spacer()
                
                if showReload {
                    Button {
                        loading = true
                        Task { await fillUsersToDisplay() }
                    } label : {
                        Text("Reload")
                            .padding()
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
    
    // fills users to display with users givenId is being followed by
    private func fillUsersToDisplay() async {
        showReload = false
        guard let userOperatingPhoneId = authManager.currentUserId else {
            print("Not signed in")
            errorMessage = "Failed to fetch followers, not signed in"
            loading = false
            return
        }
        do {
            // pulls all the users following givenId
            let followerIds = try await theUserIdsXisBeingFollowedBy(givenId)
            
            usersToDisplay = []
            
            for id in followerIds {
                let usernameForId = try await pullUsername(id)
                // is userOperatingPhoneId following the user that is following userOperatingPhoneId (is userOperatingPhoneId following id)
                let followingStatus = try await pullIsFollowing(followerId: userOperatingPhoneId, followingId: id)
                
                let userToDisplay: ProfileRow = ProfileRow(id: id, username: usernameForId, isFollowing: followingStatus)
                
                usersToDisplay.append(userToDisplay)
            }
            loading = false
        } catch {
            print("Failed to fetch follower ids: \(error)")
            errorMessage = "Couldn't load followers"
            showReload = true
            loading = false
        }
        
    }
    
}

#Preview {
    FollowerView(givenId: UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")!, givenUsername: "Oliver")
        .environment(AuthManager())
}
