//
//  ExploreFeedCard.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-22.
//

import SwiftUI
import Supabase

// the card that appears in the feed. If you click the card it takes you to the routine in spectate view.
// if you click the username it takes you to their profile.
struct ExploreFeedCard: View {
    
    // id of the history item
    let historyId: UUID
    // user name and id of the user that posted the workout
    let userName: String
    let userID: UUID
    
    let dateCompleted: Date
    let durationSeconds: Int
    
    let routineHistory: RoutineHistory

    @Environment(AuthManager.self) private var authManager
    @Environment(AppSettings.self) private var appSettings
    
    @State private var showSpectateView: Bool = false
    @State private var showProfileView: Bool = false
    
    // if the user using the phone has liked this post
    @State private var userLikedPost: Bool = false
    // how many likes this post has
    @State private var likeCount: Int = 0
    
    // number of comments this post has
    @State private var commentCount: Int = 0
    
    @State private var comments: [comment] = []
    
    @State private var userIsTypingComment: Bool = false
    @State private var usersComment: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(routineHistory.name)
                        .font(.headline)
                        .foregroundColor(Theme.primary)
                    Spacer()

                    Button {
                        showProfileView = true
                    } label : {
                        Text(userName)
                    }
                }
                
                HStack {
                    Text(formattedDate(dateCompleted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(SecondsFormatted(durationSeconds))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(routineHistory.exercises) { exercise in
                    HStack {
                        if exercise.personalBestIndex != -1 {
                            Image(systemName: "crown")
                                .foregroundStyle(Theme.gold)
                        }
                        
                        Text(exercise.name)
                            .font(.subheadline)
                            .foregroundColor(exercise.personalBestIndex != -1 ? Theme.gold : Theme.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<min(exercise.reps.count, exercise.weights.count, exercise.seconds.count), id: \.self) { index in
                                    Text(formattedSet(reps: exercise.reps[index], weight: exercise.weights[index], seconds: exercise.seconds[index], repsColumn: exercise.repsColumn, weightColumn: exercise.weightColumn, secsColumn: exercise.secsColumn, unit: appSettings.weightUnit))
                                        .font(.subheadline)
                                        .foregroundColor(exercise.personalBestIndex == index ? Theme.gold : .secondary)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Button {
                        Task {await toggleLike()}
                    } label : {
                        if userLikedPost {
                            Image(systemName: "hat.widebrim.fill")
                                .foregroundStyle(Color.green)
                                .padding(8)
                        } else {
                            Image(systemName: "hat.widebrim")
                                .foregroundStyle(Color.green)
                                .padding(8)
                        }
                        Text("\(likeCount)")
                            .foregroundStyle(Color.secondary)
                            .padding(.trailing)
                    }
                    .glassEffect()
                    
                    Button {
                        userIsTypingComment = true
                    } label : {
                        Image(systemName: "message")
                            .foregroundStyle(Color.secondary)
                            .padding(8)
                        Text("\(commentCount)")
                            .foregroundStyle(Color.secondary)
                            .padding(.trailing)
                    }
                    .glassEffect()
                }
                
                // comment code
                if commentCount != 0 || userIsTypingComment {
                    VStack {
                        if userIsTypingComment {
                            HStack {
                                TextField("Add a comment...", text: $usersComment)
                                    .multilineTextAlignment(.leading)
                                
                                Button {
                                    userIsTypingComment = false
                                } label: {
                                    Text("Cancel")
                                }
                                .buttonStyle(.glass)
                                Button {
                                    Task {
                                        guard let userId = authManager.currentUserId,
                                              let username = authManager.currentUsername else {
                                            print("You must be signed in to comment.")
                                            return
                                        }

                                        do {
                                            try await postComment(userId: userId, username: username, historyId: historyId, content: usersComment)
                                            
                                            usersComment = ""
                                            comments = try await pullComments(historyId: historyId)
                                            commentCount = comments.count
                                        } catch {
                                            print("Error posting comment: \(error)")
                                        }
                                    }
                                    
                                    userIsTypingComment = false
                                } label: {
                                    Text("Post")
                                }
                                .buttonStyle(.glass)
                            }
                            
                        }
                        
                        if commentCount != 0 {
                            ForEach(comments) { comment in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(comment.username)
                                        .fixedSize(horizontal: true, vertical: false)

                                    Text(comment.content)
                                        .foregroundStyle(Color.secondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                
            }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            showSpectateView = true
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $showSpectateView) {
            RoutineSpectateView(routine: routineHistoryToRoutine(routineHistory))
        }
        .fullScreenCover(isPresented: $showProfileView) {
            ProfileView(givenId: userID)
        }
        .task {
            await loadLikeInfo()
            
            do {
                comments = try await pullComments(historyId: historyId)
                commentCount = comments.count
                
            } catch {
                comments = []
                commentCount = 0
                print("Error pulling comments: \(error)")
            }
        }
    }
    private func loadLikeInfo() async {
        // use guard because current user id is an optional variable (has the "?")
        guard let userId = authManager.currentUserId else { return }
        
        do {
            async let liked = isUserLikingPost(historyId: historyId, userId: userId)
            async let count = pullLikes(historyId: historyId)
            userLikedPost = try await liked
            likeCount = try await count
        } catch {
            print("Failed to load like state: \(error)")
        }
    }
    
    // adds or deletes a row in the "likes" table of the database. Also changes the userLikedPost and likeCount variables
    private func toggleLike() async {
        // use guard because current user id is an optional variable (has the "?")
        guard let userId = authManager.currentUserId else { return }
        
        
        let wasLiked = userLikedPost
        // optimistic UI update
        userLikedPost.toggle()
        likeCount += wasLiked ? -1 : 1

        do {
            if wasLiked {
                // deletes the row from supabase
                try await supabase
                    .from("likes")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("history_item_id", value: historyId)
                    .execute()
            } else {
                // inserts a row to supabase
                try await supabase
                    .from("likes")
                    .insert(["user_id": userId, "history_item_id": historyId])
                    .execute()
            }
        } catch {
            // revert on failure
            userLikedPost = wasLiked
            likeCount += wasLiked ? 1 : -1
            print("Failed to toggle like: \(error)")
        }
    }
}




#Preview {
    ExploreFeedCard(
        historyId: UUID(uuidString: "119dfeae-9d07-4818-892f-98f4617f3c49")!,
        userName: "Oliver",
        userID: UUID(uuidString: "fbb7dbaa-2342-4290-9f05-6c83c65dc0c5")!,
        dateCompleted: Date(),
        durationSeconds: 60,
        // built the same way the feed builds it, out of the exercises on a history row.
        // bench press has its second set as the personal best, squat has none
        routineHistory: exercisesToRoutineHistory(
            [
                ExerciseHistoryDTO(name: "Bench Press", reps: [3,3,3], weights: [10, 10, 10], seconds: [0,0,0], restTime: 60, order: 0, personalBestIndex: 1),
                ExerciseHistoryDTO(name: "Squat", reps: [3,3,3], weights: [10, 10, 10], seconds: [0,0,0], restTime: 60, order: 1, personalBestIndex: -1)
            ],
            name: "Routine 1"
        )
    )
        .environment(AuthManager())
        .environment(AppSettings())
}
