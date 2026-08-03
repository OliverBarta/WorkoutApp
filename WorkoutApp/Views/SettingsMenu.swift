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
    
    var body: some View {
        VStack {
            
            HStack {
                Text(authManager.currentUsername ?? "Guest")
                    .font(.headline)
                
                Spacer()
                Text("Followers: ")
                    .font(.subheadline)
                Text("12")
                    .font(.headline)
                
                Spacer()
                
                Text("Following: ")
                    .font(.subheadline)
                Text("5")
                    .font(.headline)
                
            }
            .padding()
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            
            if errorMessage != "" {
                Text(errorMessage)
            }
            
            HStack {
                Button {
                    Task {
                        do {
                            try await authManager.signOut()
                        } catch {
                            print("Sign out failed: \(error)")
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 35)
        .alert("Enter new username", isPresented: $showChangeUsername) {
            TextField("Exercise Name", text: $newUsername)
            
            Button("Update username") {
                
                Task { await save() }
                
            }
            
            Button("Cancel", role: .cancel) {
                newUsername = ""
            }
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
