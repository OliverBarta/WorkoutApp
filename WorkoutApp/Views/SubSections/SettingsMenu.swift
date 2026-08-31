//
//  SettingsMenu.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-30.
//

import SwiftUI

struct SettingsMenu: View {
    
    @Environment(AuthManager.self) private var authManager
    @Environment(AppSettings.self) private var appSettings
    
    @State private var newUsername = ""
    @State private var errorMessage: String = ""
    @State private var showChangeUsername: Bool = false
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0
    
    @State private var followingViewBeingShown = false
    @State private var followerViewBeingShown = false
    
    var body: some View {
        ScrollView {
            Rectangle()
                .padding(.top, 35)
                .opacity(0)
            
            HStack {
                Text(authManager.currentUsername ?? "Guest")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    followerViewBeingShown = true
                } label : {
                    Text("Followers: ")
                        .font(.subheadline)
                    Text("\(followerCount)")
                        .font(.headline)
                }
                .buttonStyle(.glass)
                
                Spacer()
                
                Button {
                    followingViewBeingShown = true
                } label : {
                    Text("Following: ")
                        .font(.subheadline)
                    Text("\(followingCount)")
                        .font(.headline)
                }
                .buttonStyle(.glass)
                
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
                            print("Sign out failed: \(error)")
                        }
                    }
                } label : {
                    Text("Sign out")
                        .frame(maxWidth:. infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.red)
                
                Button {
                    showChangeUsername = true
                } label : {
                    Text("Change username")
                        .frame(maxWidth:. infinity)
                }
                .buttonStyle(.glassProminent)
            }
            
            HStack {
                Text("Default rest time:")
                    .font(.headline)
                
                Spacer()
                
                wheel(range: 0..<60, selection: $pickerMinutes, unit: "min")
                wheel(range: 0..<60, selection: $pickerSeconds, unit: "sec")
                
            }
            .padding()
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Text("Weight unit: ")
                    .font(.headline)

                Spacer()

                Picker("Weight unit", selection: Bindable(appSettings).weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding()
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            
            HStack {
                Text("Timer default:")
                    .font(.headline)

                Spacer()

                Picker("Timer default", selection: Bindable(appSettings).timerDefault) {
                    Text("Stopwatch").tag("stopwatch")
                    Text("timer").tag("timer")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding()
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))

            Spacer()
            
            Text("These settings are not linked to the account they are linked to this device.")
                .font(.caption)
        }
        .scrollIndicators(.hidden)// hides the side scroll bar
        .alert("Enter new username", isPresented: $showChangeUsername) {
            TextField("Exercise Name", text: $newUsername)
            
            Button("Update username") {
                
                Task { await save() }
                
            }
            
            Button("Cancel", role: .cancel) {
                newUsername = ""
            }
        }
        .onChange(of: pickerMinutes+pickerSeconds) {
            appSettings.defaultRestSeconds = 60*pickerMinutes + pickerSeconds
        }
        .task {
            loadRestTime()
            
            await loadCounts()
        }
        .fullScreenCover(isPresented: $followingViewBeingShown) {
            if let userId = authManager.currentUserId, let username = authManager.currentUsername {
                FollowingView(givenId: userId, givenUsername: username)
            }
        }
        .fullScreenCover(isPresented: $followerViewBeingShown) {
            if let userId = authManager.currentUserId, let username = authManager.currentUsername {
                FollowerView(givenId: userId, givenUsername: username)
            }
        }
        .overlay {
            VStack {
                ZStack {
                    Text("Settings")
                        .headerStyle()
                    
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
                
                
                TopPopUp(message: $errorMessage)
                
                
                Spacer()
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
            print(error.localizedDescription)
        }
    }
    
    private func save() async {
        do {
            try await authManager.updateUsername(newUsername)
        } catch {
            errorMessage = error.localizedDescription
            print(error.localizedDescription)
        }
    }
    
    private func loadRestTime() {
        pickerMinutes = appSettings.defaultRestSeconds/60
        pickerSeconds = appSettings.defaultRestSeconds%60
    }
}


#Preview {
    SettingsMenu()
        .environment(AuthManager())
        .environment(AppSettings())
}
