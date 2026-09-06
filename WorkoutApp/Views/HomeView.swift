//
//  Profile.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutHistoryEntry.dateCompleted, order: .reverse) private var history: [WorkoutHistoryEntry]
    
    @Query private var routines: [Routine]
    
    @Environment(WorkoutSession.self) private var workoutSession
    @Environment(AppSettings.self) private var appSettings
    @Environment(AuthManager.self) private var authManager

    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showStreakInfo = false
    @State private var showUserProfile = false
    
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    
                    Rectangle()
                        .padding(.top, 35)
                        .opacity(0)
                    
                    Button {
                        showHistory = true
                    } label: { 
                        VStack(spacing: 12) {
                            Text("History")
                                .font(.headline)
                                .foregroundColor(Theme.oppositeBackground)
                            
                            HStack(spacing: 4) {
                                ForEach(0..<7) { offset in
                                    let date = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date()
                                    let dayNumber = Calendar.current.component(.day, from: date)
                                    
                                    let dayInWorkout = history.contains { historyItem in
                                        Calendar.current.isDate(historyItem.dateCompleted, inSameDayAs: date)
                                    }
                                    
                                    ZStack {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fill)
                                        
                                        Text("\(dayNumber)")
                                            .font(.caption)
                                            .foregroundColor(Theme.oppositeBackground)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(dayInWorkout ? Theme.primary : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                }
                                
                            }

                        }
                        .padding()
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    
                    
                    if routines.count >= 1 {
                        // Routine that the user hasn't hit in the longest time
                        RoutineCard(routine: routines[0], deletableCard: false)
                    }
                    
                    LeaderBoardCardHome(initialNumRows: 5)
                    
                    if history.isEmpty {
                        Text("No workouts logged yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 60)
                    } else {
                        ForEach(history) { entry in
                            WorkoutHistoryCard(entry: entry)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)// hides the side scroll bar
            .frame(maxWidth: .infinity)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsMenu()
            }
            .sheet(isPresented: $showHistory) {
                HistorySheet()
                    .presentationDetents([.height(380)])
            }
            .sheet(isPresented: $showStreakInfo) {
                StreakSheet()
                    .presentationDetents([.height(380)])
            }
            .fullScreenCover(isPresented: $showUserProfile) {
                if let userId = authManager.currentUserId {
                    ProfileView(givenId: userId)
                }
            }
            .overlay {
                VStack {
                    ZStack {
                        HStack {
                            
                            Button {
                                showStreakInfo = true
                            } label : {
                                Text("\(authManager.currentStreak)")
                                    .foregroundColor(Theme.orange)
                                    .padding(.vertical, 12)
                                    .padding(.leading, 12)
                                
                                Image(systemName: "flame")
                                    .foregroundColor(Theme.orange)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 12)
                            }
                            .glassEffect()
                            
                            Spacer()
                            
                            Button {
                                if authManager.currentUserId != nil {
                                    showUserProfile = true
                                } else {
                                    errorMessage = "Error: Not signed in"
                                }
                            } label : {
                                Image(systemName: "person")
                                    .foregroundColor(Theme.oppositeBackground)
                                    .padding(12)
                            }
                            .glassEffect()
                            
                            Button {
                                showSettings = true
                            } label : {
                                Image(systemName: "gearshape")
                                    .foregroundColor(Theme.oppositeBackground)
                                    .padding(12)
                            }
                            .glassEffect()
                        }
                        .padding(.horizontal)
                        
                        Text("Home")
                            .headerStyle()
                    }
                    
                    TopPopUp(message: $errorMessage, addSpaceUnder: false)
                    
                    Spacer()
                    
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: WorkoutHistoryEntry.self, inMemory: true)
        .environment(WorkoutSession())
        .environment(AuthManager())
        .environment(AppSettings())
}
