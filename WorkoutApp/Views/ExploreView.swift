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
    @State private var errorMessage: String = ""
    
    // if the search bar is focused or not
    @FocusState private var isSearchFocused: Bool
    
    // used to make the search re-search every 300ms not every key stroke
    @State private var searchTask: Task<Void, Never>?
    
    // choose between the global and following only feed
    @State private var feedType: String = "following"
        
    // filters the profiles by the search
    var filtered: [ProfileRow] {
        return profiles.filter {
            $0.id != authManager.currentUserId
        }
    }

    var body: some View {
        ScrollView {
            // padding for the top
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            CustomSearchBar(text: $searchText, isFocused: $isSearchFocused, placeHolderText: "Find people")
                .padding(.horizontal)
            
            // stack the people search results with the feed
            ZStack(alignment: .top) {
                VStack {
                    VStack {
                        Picker("Feed", selection: $feedType) {
                            Text("Following").tag("following")
                            Text("Global").tag("global")
                        }
                        .blur(radius: !searchText.isEmpty ? 5 : 0)
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if let currentUserId = authManager.currentUserId {
                            if feedType == "following" {
                                FeedElementFollowing(userId: currentUserId)
                                    .blur(radius: !searchText.isEmpty ? 5 : 0)
                            } else {
                                FeedElementGlobal(userId: currentUserId)
                                    .blur(radius: !searchText.isEmpty ? 5 : 0)
                            }
                        }
                    }
                    .allowsHitTesting(searchText.isEmpty)// only allow clicks when nothing in the search bar
                }
                .contentShape(Rectangle())
                .onTapGesture {// clear search bar when you click this
                    searchText = ""
                }
                VStack {
                    if !searchText.isEmpty {
                        if filtered.isEmpty {
                            Text("No results")
                                .foregroundColor(.secondary)
                                .padding(.top, 60)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(filtered) { profile in
                                    ProfileListRow(profile: profile)
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
        .frame(maxWidth: .infinity)
        .overlay {
            VStack {
                ZStack {
                    Text("Explore")
                        .headerStyle()
                }
                TopPopUp(message: $errorMessage)
                
                Spacer()
            }
        }
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            
            // if the search is empty don't pull from database
            guard !newValue.isEmpty else {
                profiles = []
                return
            }
            
            searchTask = Task {
                do {
                    try await Task.sleep(nanoseconds: 300_000_000) // 300ms
                    guard !Task.isCancelled else { return }
                    await search(newValue)
                } catch {
                    // Task.sleep throws if cancelled — nothing to do here
                }
            }
        }
    }

    private func search(_ text: String) async {
        do {
            profiles = try await pullProfilesFromSupabase(searchText: text)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
            print("Failed to load: \(error.localizedDescription)")
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
    
    @State private var errorMessage: String = ""
    
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
                        errorMessage = "Follow/unfollow failed: \(error)"
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
    let authManager = AuthManager()
    // this previews as the user Oliver
    authManager.currentUserId = UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")

    return ExploreView()
        .environment(authManager)
        .environment(AppSettings())
}
