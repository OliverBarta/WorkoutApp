//
//  ExplorView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-30.
//
import SwiftUI

struct ExploreView: View {
    @Environment(AuthManager.self) private var authManager
    
    @State private var searchText = ""
    @State private var profiles: [ProfileRow] = []
    // possible error message from supabase
    @State private var errorMessage: String?
    
    // if the search bar is focused or not
    @FocusState private var isSearchFocused: Bool
    
    // filters the profiles by the search
    var filtered: [ProfileRow] {
        return profiles.filter {
            $0.id != authManager.currentUserId &&
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                // padding for the top
                Rectangle()
                    .padding(.top, 35)
                    .opacity(0)
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                CustomSearchBar(text: $searchText, isFocused: $isSearchFocused, placeHolderText: "Find people")
                    .padding(.horizontal)
                
                if searchText != "" {
                    if filtered.isEmpty {
                        Text("No results")
                            .foregroundColor(.secondary)
                            .padding(.top, 30)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filtered) { profile in
                                ProfileListRow(profile: profile)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            VStack {
                ZStack {
                    Text("Explore")
                        .headerStyle()
                }
                Spacer()
            }
        }
        .task {
            await loadProfiles()
        }
    }

    private func loadProfiles() async {
        do {
            profiles = try await pullProfilesFromSupabase()
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
    }
}

// the profile
struct ProfileListRow: View {
    let profile: ProfileRow
    
    @State private var isFollowing: Bool
    
    @State private var showProfileView: Bool = false
    
    init(profile: ProfileRow) {
        self.profile = profile
        _isFollowing = State(initialValue: profile.isFollowing)
    }
    
    var body: some View {
        Button {
            // should go to profile view
            showProfileView = true
        } label : {
            Circle()
                .fill(Theme.primary.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(profile.username.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(Theme.primary)
                )
            
            Text(profile.username)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(isFollowing ? "Following" : "Follow") {
                Task {
                    do {
                        if isFollowing {
                            try await unfollowUser(profile.id)
                        } else {
                            try await followUser(profile.id)
                        }
                        isFollowing.toggle()
                    } catch {
                        print("Follow/unfollow failed: \(error)")
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showProfileView) {
            ProfileView(givenId: profile.id)
        }
    }
}

#Preview {
    ExploreView()
        .environment(AuthManager())
}
