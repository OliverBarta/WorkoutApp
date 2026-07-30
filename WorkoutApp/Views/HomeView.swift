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
    
    
    
    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    
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
                                    
                                    Text("\(dayNumber)")
                                        .font(.caption)
                                        .foregroundColor(Theme.oppositeBackground)
                                        .frame(width: 45, height: 45)
                                        .background(dayInWorkout ? Theme.primary : Color.clear)
                                        .clipShape(
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: 12,
                                                bottomLeadingRadius: 12,
                                                bottomTrailingRadius: 12,
                                                topTrailingRadius: 12
                                            )
                                        )
                                        .overlay(
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: 12,
                                                bottomLeadingRadius: 12,
                                                bottomTrailingRadius: 12,
                                                topTrailingRadius: 12
                                            )
                                            .stroke(Color.gray, lineWidth: 1)
                                        )
                                }
                                
                            }

                        }
                        .padding()
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    if history.isEmpty {
                        Text("No workouts logged yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 60)
                    } else {
                        ForEach(history) { entry in
                            WorkoutHistoryCard(entry: entry)
                                .padding()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showSettings) {
                SettingsMenu()
            }
            .sheet(isPresented: $showHistory) {
                HistorySheet()
                    .presentationDetents([.height(380)])
                
            }
            
            .overlay {
                VStack {
                    ZStack {
                        HStack {
                            Button {
                                showSettings = true
                            } label : {
                                Image(systemName: "gearshape")
                                    .foregroundColor(Theme.oppositeBackground)
                                    .padding(12)
                            }
                            .glassEffect()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        
                        Text("Home")
                            .headerStyle()
                    }
                    
                    Spacer()
                    
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: WorkoutHistoryEntry.self, inMemory: true)
}
