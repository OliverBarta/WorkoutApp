//
//  HomeView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-07-15.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            ScrollView {
                Text("test")
                    .padding(.top, 45)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .overlay {
                VStack {
                    Text("Profile")
                        .headerStyle()
                    Spacer()
                }
            }
            
            
        }
    }
}

#Preview {
    ProfileView()
}
