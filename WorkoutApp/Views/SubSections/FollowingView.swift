//
//  FollowingFollowers.swift
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

// the view showing the users givenId is following
struct FollowingView: View {
    
    let givenId: UUID
    
    let givenUsername: String
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(AuthManager.self) private var authManager
    
    @State private var usersToDisplay: [ProfileRow] = []
    
    @State private var errorMessage: String = ""
    @State private var showReload: Bool = false
    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            if usersToDisplay.isEmpty {
                Text("\(givenUsername) isn't following anybody")
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
                    Text("Following")
                        .headerStyle()
                        .frame(alignment: .center)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding(5)
                    }
                    .buttonStyle(.glass)
                    .foregroundColor(Theme.oppositeBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    
                }
                TopPopUp(message: $errorMessage, addSpaceUnder: false)
                Spacer()
                
                if showReload {
                    Button {
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
    
    // fills users to display with users givenId is following
    private func fillUsersToDisplay() async {
        showReload = false
        do {
            // pulls all the users givenId is following
            let followingIds = try await theUserIdsXisFollowing(givenId)
            
            usersToDisplay = []
            
            for id in followingIds {
                let usernameForId = try await pullUsername(id)
                
                // is givenId following the user that they are following (yes always)
                let followingStatus = true
                
                let userToDisplay: ProfileRow = ProfileRow(id: id, username: usernameForId, isFollowing: followingStatus)
                
                usersToDisplay.append(userToDisplay)
            }
            
        } catch {
            print("Failed to fetch following ids: \(error)")
            errorMessage = "Couldn't load following"
            showReload = true
        }
        
    }
}

#Preview {
    FollowingView(givenId: UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")!, givenUsername: "Oliver")
        .environment(AuthManager())
}
